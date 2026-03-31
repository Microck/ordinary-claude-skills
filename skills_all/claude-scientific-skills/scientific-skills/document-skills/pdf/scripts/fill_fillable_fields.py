"""Fill fillable form fields in a PDF document.

Reads a JSON file describing field values (as produced by
``extract_form_field_info.py``), validates each value against the field's
expected type and options, and writes the filled PDF to a new file.
See forms.md for the input JSON format.
"""

import json
import sys

from pypdf import PdfReader, PdfWriter

from extract_form_field_info import get_field_info


def fill_pdf_fields(input_pdf_path: str, fields_json_path: str, output_pdf_path: str):
    """Fill form fields in a PDF using values from a JSON file.

    Validates that every field ID referenced in the JSON exists in the PDF
    and that each value is appropriate for the field type.  Exits with
    status 1 on the first validation error.

    Args:
        input_pdf_path: Path to the source PDF containing form fields.
        fields_json_path: Path to a JSON file with field values to write.
        output_pdf_path: Destination path for the filled PDF.
    """
    with open(fields_json_path) as f:
        fields = json.load(f)
    # Group by page number.
    fields_by_page = {}
    for field in fields:
        if "value" in field:
            field_id = field["field_id"]
            page = field["page"]
            if page not in fields_by_page:
                fields_by_page[page] = {}
            fields_by_page[page][field_id] = field["value"]
    
    reader = PdfReader(input_pdf_path)

    has_error = False
    field_info = get_field_info(reader)
    fields_by_ids = {f["field_id"]: f for f in field_info}
    for field in fields:
        existing_field = fields_by_ids.get(field["field_id"])
        if not existing_field:
            has_error = True
            print(f"ERROR: `{field['field_id']}` is not a valid field ID")
        elif field["page"] != existing_field["page"]:
            has_error = True
            print(f"ERROR: Incorrect page number for `{field['field_id']}` (got {field['page']}, expected {existing_field['page']})")
        else:
            if "value" in field:
                err = validation_error_for_field_value(existing_field, field["value"])
                if err:
                    print(err)
                    has_error = True
    if has_error:
        sys.exit(1)

    writer = PdfWriter(clone_from=reader)
    for page, field_values in fields_by_page.items():
        writer.update_page_form_field_values(writer.pages[page - 1], field_values, auto_regenerate=False)

    # This seems to be necessary for many PDF viewers to format the form values correctly.
    # It may cause the viewer to show a "save changes" dialog even if the user doesn't make any changes.
    writer.set_need_appearances_writer(True)
    
    with open(output_pdf_path, "wb") as f:
        writer.write(f)


def validation_error_for_field_value(field_info, field_value):
    """Check whether a value is valid for the given field and return an error message if not.

    For checkbox fields the value must match the checked or unchecked value.
    For radio groups the value must be one of the defined option values.
    For choice (list/combo) fields the value must appear in the available options.

    Args:
        field_info: A field descriptor dictionary (from ``get_field_info``).
        field_value: The proposed value to validate.

    Returns:
        str or None: An error message string if the value is invalid, otherwise ``None``.
    """
    field_type = field_info["type"]
    field_id = field_info["field_id"]
    if field_type == "checkbox":
        checked_val = field_info["checked_value"]
        unchecked_val = field_info["unchecked_value"]
        if field_value != checked_val and field_value != unchecked_val:
            return f'ERROR: Invalid value "{field_value}" for checkbox field "{field_id}". The checked value is "{checked_val}" and the unchecked value is "{unchecked_val}"'
    elif field_type == "radio_group":
        option_values = [opt["value"] for opt in field_info["radio_options"]]
        if field_value not in option_values:
            return f'ERROR: Invalid value "{field_value}" for radio group field "{field_id}". Valid values are: {option_values}' 
    elif field_type == "choice":
        choice_values = [opt["value"] for opt in field_info["choice_options"]]
        if field_value not in choice_values:
            return f'ERROR: Invalid value "{field_value}" for choice field "{field_id}". Valid values are: {choice_values}'
    return None


def monkeypatch_pydpf_method():
    """Patch a pypdf bug in ``DictionaryObject.get_inherited`` for selection-list fields.

    pypdf (at least version 5.7.0) has a bug when setting the value for a
    selection-list field. In ``_writer.py`` around line 966:

    .. code-block:: python

        if field.get(FA.FT, "/Tx") == "/Ch" and field_flags & FA.FfBits.Combo == 0:
            txt = "\\n".join(annotation.get_inherited(FA.Opt, []))

    The problem is that for selection lists, ``get_inherited`` returns a list
    of two-element lists like ``[["value1", "Text 1"], ...]`` which causes
    ``join`` to raise a ``TypeError``.  This function monkey-patches
    ``DictionaryObject.get_inherited`` so that, when the key is ``Opt`` and
    the result is a list of two-element lists, it flattens to just the first
    element of each pair.
    """
    from pypdf.generic import DictionaryObject
    from pypdf.constants import FieldDictionaryAttributes

    original_get_inherited = DictionaryObject.get_inherited

    def patched_get_inherited(self, key: str, default = None):
        """Replacement for ``DictionaryObject.get_inherited`` that flattens /Opt values.

        Calls the original method and, when the requested key is ``Opt`` and
        the result is a list of two-element lists (value/text pairs), returns
        only the value strings.

        Args:
            self: The ``DictionaryObject`` instance (bound implicitly).
            key: The dictionary key to look up.
            default: Value to return if the key is not found.

        Returns:
            The original result, or a flattened list of value strings for
            ``Opt`` entries.
        """
        result = original_get_inherited(self, key, default)
        if key == FieldDictionaryAttributes.Opt:
            if isinstance(result, list) and all(isinstance(v, list) and len(v) == 2 for v in result):
                result = [r[0] for r in result]
        return result

    DictionaryObject.get_inherited = patched_get_inherited


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: fill_fillable_fields.py [input pdf] [field_values.json] [output pdf]")
        sys.exit(1)
    monkeypatch_pydpf_method()
    input_pdf = sys.argv[1]
    fields_json = sys.argv[2]
    output_pdf = sys.argv[3]
    fill_pdf_fields(input_pdf, fields_json, output_pdf)
