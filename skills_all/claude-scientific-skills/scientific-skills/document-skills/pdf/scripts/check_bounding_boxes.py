"""Validate non-overlapping bounding boxes for PDF form field annotations.

Reads a ``fields.json`` file (as described in forms.md) that contains label
and entry bounding boxes for each form field, checks every pair of boxes on
the same page for intersections, and verifies that entry boxes are tall
enough to accommodate their font size.  Outputs human-readable messages
describing any violations.
"""

from dataclasses import dataclass
import json
import sys


@dataclass
class RectAndField:
    rect: list[float]
    rect_type: str
    field: dict


def get_bounding_box_messages(fields_json_stream) -> list[str]:
    """Read a fields JSON stream and return a list of validation messages.

    Checks all label and entry bounding boxes for pairwise intersections on
    each page, and ensures each entry box is tall enough for its font size.
    Returns a list of strings starting with a count of fields read, followed
    by ``SUCCESS`` or ``FAILURE`` lines for each check.

    Args:
        fields_json_stream: A file-like object containing the fields JSON.

    Returns:
        list[str]: Validation messages suitable for printing to stdout.
    """
    messages = []
    fields = json.load(fields_json_stream)
    messages.append(f"Read {len(fields['form_fields'])} fields")

    def rects_intersect(r1, r2):
        """Return True if axis-aligned rectangles r1 and r2 overlap.

        Each rectangle is a four-element list ``[x1, y1, x2, y2]`` where
        ``(x1, y1)`` is the lower-left corner and ``(x2, y2)`` is the
        upper-right corner.

        Args:
            r1: First rectangle as ``[x1, y1, x2, y2]``.
            r2: Second rectangle as ``[x1, y1, x2, y2]``.

        Returns:
            bool: ``True`` if the rectangles share any area, ``False`` otherwise.
        """
        disjoint_horizontal = r1[0] >= r2[2] or r1[2] <= r2[0]
        disjoint_vertical = r1[1] >= r2[3] or r1[3] <= r2[1]
        return not (disjoint_horizontal or disjoint_vertical)

    rects_and_fields = []
    for f in fields["form_fields"]:
        rects_and_fields.append(RectAndField(f["label_bounding_box"], "label", f))
        rects_and_fields.append(RectAndField(f["entry_bounding_box"], "entry", f))

    has_error = False
    for i, ri in enumerate(rects_and_fields):
        # This is O(N^2); we can optimize if it becomes a problem.
        for j in range(i + 1, len(rects_and_fields)):
            rj = rects_and_fields[j]
            if ri.field["page_number"] == rj.field["page_number"] and rects_intersect(ri.rect, rj.rect):
                has_error = True
                if ri.field is rj.field:
                    messages.append(f"FAILURE: intersection between label and entry bounding boxes for `{ri.field['description']}` ({ri.rect}, {rj.rect})")
                else:
                    messages.append(f"FAILURE: intersection between {ri.rect_type} bounding box for `{ri.field['description']}` ({ri.rect}) and {rj.rect_type} bounding box for `{rj.field['description']}` ({rj.rect})")
                if len(messages) >= 20:
                    messages.append("Aborting further checks; fix bounding boxes and try again")
                    return messages
        if ri.rect_type == "entry":
            if "entry_text" in ri.field:
                font_size = ri.field["entry_text"].get("font_size", 14)
                entry_height = ri.rect[3] - ri.rect[1]
                if entry_height < font_size:
                    has_error = True
                    messages.append(f"FAILURE: entry bounding box height ({entry_height}) for `{ri.field['description']}` is too short for the text content (font size: {font_size}). Increase the box height or decrease the font size.")
                    if len(messages) >= 20:
                        messages.append("Aborting further checks; fix bounding boxes and try again")
                        return messages

    if not has_error:
        messages.append("SUCCESS: All bounding boxes are valid")
    return messages

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: check_bounding_boxes.py [fields.json]")
        sys.exit(1)
    # Input file should be in the `fields.json` format described in forms.md.
    with open(sys.argv[1]) as f:
        messages = get_bounding_box_messages(f)
    for msg in messages:
        print(msg)
