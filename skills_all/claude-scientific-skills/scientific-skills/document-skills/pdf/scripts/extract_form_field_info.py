"""Extract metadata from fillable PDF form fields and write to JSON.

Reads a PDF with fillable form fields, collects each field's identifier,
type (text, checkbox, radio group, or choice), page location, bounding
rectangle, and available option values, then serialises the result as JSON
that downstream tools use to fill the fields.  See forms.md for the output
format.
"""

import json
import sys

from pypdf import PdfReader


# This matches the format used by PdfReader `get_fields` and `update_page_form_field_values` methods.
def get_full_annotation_field_id(annotation):
    """Walk up the annotation's /Parent chain and return the dotted field ID.

    PDF form fields may be nested inside parent nodes that carry partial
    names.  This function concatenates the names from the innermost child
    to the outermost parent, joined by ``.``, matching the convention used
    by ``PdfReader.get_fields``.

    Args:
        annotation: A pypdf annotation dictionary object.

    Returns:
        str or None: The fully-qualified dotted field name, or ``None`` if
        the annotation has no ``/T`` entries in its hierarchy.
    """
    components = []
    while annotation:
        field_name = annotation.get('/T')
        if field_name:
            components.append(field_name)
        annotation = annotation.get('/Parent')
    return ".".join(reversed(components)) if components else None


def make_field_dict(field, field_id):
    """Build a metadata dictionary for a single form field.

    Determines the field type (text, checkbox, choice, or unknown) from
    the ``/FT`` entry and populates type-specific metadata such as checked
    and unchecked values for checkboxes, or available options for choice
    fields.

    Args:
        field: A pypdf field dictionary.
        field_id: The fully-qualified field identifier string.

    Returns:
        dict: A dictionary with at least ``field_id`` and ``type`` keys,
        plus additional keys depending on the field type.
    """
    field_dict = {"field_id": field_id}
    ft = field.get('/FT')
    if ft == "/Tx":
        field_dict["type"] = "text"
    elif ft == "/Btn":
        field_dict["type"] = "checkbox"  # radio groups handled separately
        states = field.get("/_States_", [])
        if len(states) == 2:
            # "/Off" seems to always be the unchecked value, as suggested by
            # https://opensource.adobe.com/dc-acrobat-sdk-docs/standards/pdfstandards/pdf/PDF32000_2008.pdf#page=448
            # It can be either first or second in the "/_States_" list.
            if "/Off" in states:
                field_dict["checked_value"] = states[0] if states[0] != "/Off" else states[1]
                field_dict["unchecked_value"] = "/Off"
            else:
                print(f"Unexpected state values for checkbox `${field_id}`. Its checked and unchecked values may not be correct; if you're trying to check it, visually verify the results.")
                field_dict["checked_value"] = states[0]
                field_dict["unchecked_value"] = states[1]
    elif ft == "/Ch":
        field_dict["type"] = "choice"
        states = field.get("/_States_", [])
        field_dict["choice_options"] = [{
            "value": state[0],
            "text": state[1],
        } for state in states]
    else:
        field_dict["type"] = f"unknown ({ft})"
    return field_dict


def get_field_info(reader: PdfReader):
    """Extract fillable form field metadata from a PDF.

    Scans the PDF for interactive form fields, resolves their types, page
    locations, and bounding rectangles, and returns a sorted list of field
    descriptor dictionaries.

    Args:
        reader: An initialised ``PdfReader`` instance.

    Returns:
        list[dict]: A list of field dictionaries sorted by page number,
        then Y position (top-to-bottom in PDF coordinates), then X position.
        Each dictionary contains at least ``field_id``, ``type``, and ``page``.
    """
    fields = reader.get_fields()

    field_info_by_id = {}
    possible_radio_names = set()

    for field_id, field in fields.items():
        # Skip if this is a container field with children, except that it might be
        # a parent group for radio button options.
        if field.get("/Kids"):
            if field.get("/FT") == "/Btn":
                possible_radio_names.add(field_id)
            continue
        field_info_by_id[field_id] = make_field_dict(field, field_id)

    # Bounding rects are stored in annotations in page objects.

    # Radio button options have a separate annotation for each choice;
    # all choices have the same field name.
    # See https://westhealth.github.io/exploring-fillable-forms-with-pdfrw.html
    radio_fields_by_id = {}

    for page_index, page in enumerate(reader.pages):
        annotations = page.get('/Annots', [])
        for ann in annotations:
            field_id = get_full_annotation_field_id(ann)
            if field_id in field_info_by_id:
                field_info_by_id[field_id]["page"] = page_index + 1
                field_info_by_id[field_id]["rect"] = ann.get('/Rect')
            elif field_id in possible_radio_names:
                try:
                    # ann['/AP']['/N'] should have two items. One of them is '/Off',
                    # the other is the active value.
                    on_values = [v for v in ann["/AP"]["/N"] if v != "/Off"]
                except KeyError:
                    continue
                if len(on_values) == 1:
                    rect = ann.get("/Rect")
                    if field_id not in radio_fields_by_id:
                        radio_fields_by_id[field_id] = {
                            "field_id": field_id,
                            "type": "radio_group",
                            "page": page_index + 1,
                            "radio_options": [],
                        }
                    # Note: at least on macOS 15.7, Preview.app doesn't show selected
                    # radio buttons correctly. (It does if you remove the leading slash
                    # from the value, but that causes them not to appear correctly in
                    # Chrome/Firefox/Acrobat/etc).
                    radio_fields_by_id[field_id]["radio_options"].append({
                        "value": on_values[0],
                        "rect": rect,
                    })

    # Some PDFs have form field definitions without corresponding annotations,
    # so we can't tell where they are. Ignore these fields for now.
    fields_with_location = []
    for field_info in field_info_by_id.values():
        if "page" in field_info:
            fields_with_location.append(field_info)
        else:
            print(f"Unable to determine location for field id: {field_info.get('field_id')}, ignoring")

    # Sort by page number, then Y position (flipped in PDF coordinate system), then X.
    def sort_key(f):
        """Return a sort key tuple ``(page, [adjusted_y, x])`` for a field dict.

        Handles both plain fields (with a ``rect`` key) and radio groups
        (with nested ``radio_options``).  The Y coordinate is negated so
        that fields nearer the top of the page sort first in the PDF
        coordinate system where Y increases upward.

        Args:
            f: A field descriptor dictionary.

        Returns:
            list: ``[page, [negated_y, x]]`` suitable for use as a sort key.
        """
        if "radio_options" in f:
            rect = f["radio_options"][0]["rect"] or [0, 0, 0, 0]
        else:
            rect = f.get("rect") or [0, 0, 0, 0]
        adjusted_position = [-rect[1], rect[0]]
        return [f.get("page"), adjusted_position]
    
    sorted_fields = fields_with_location + list(radio_fields_by_id.values())
    sorted_fields.sort(key=sort_key)

    return sorted_fields


def write_field_info(pdf_path: str, json_output_path: str):
    """Read a PDF, extract form field metadata, and write it to a JSON file.

    Args:
        pdf_path: Path to the source PDF file.
        json_output_path: Destination path for the JSON output.
    """
    reader = PdfReader(pdf_path)
    field_info = get_field_info(reader)
    with open(json_output_path, "w") as f:
        json.dump(field_info, f, indent=2)
    print(f"Wrote {len(field_info)} fields to {json_output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: extract_form_field_info.py [input pdf] [output json]")
        sys.exit(1)
    write_field_info(sys.argv[1], sys.argv[2])
