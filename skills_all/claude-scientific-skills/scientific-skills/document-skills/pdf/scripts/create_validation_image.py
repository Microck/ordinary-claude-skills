"""Create visual validation images by drawing bounding-box rectangles on PDF page images.

Overlays red rectangles on entry bounding boxes and blue rectangles on label
bounding boxes so that downstream tools can visually verify the positions
Claude predicted for text annotations.  See forms.md for the expected JSON
format.
"""

import json
import sys

from PIL import Image, ImageDraw


def create_validation_image(page_number, fields_json_path, input_path, output_path):
    """Draw bounding-box rectangles onto a page image for visual verification.

    Reads the fields JSON, opens the source image (a PNG rendering of the
    PDF page), and draws a red rectangle over each entry bounding box and a
    blue rectangle over each label bounding box for the specified page.

    Args:
        page_number: The 1-based page number whose fields should be drawn.
        fields_json_path: Path to the ``fields.json`` file.
        input_path: Path to the source PNG image for the page.
        output_path: Destination path for the annotated PNG image.
    """
    # Input file should be in the `fields.json` format described in forms.md.
    with open(fields_json_path, 'r') as f:
        data = json.load(f)

        img = Image.open(input_path)
        draw = ImageDraw.Draw(img)
        num_boxes = 0
        
        for field in data["form_fields"]:
            if field["page_number"] == page_number:
                entry_box = field['entry_bounding_box']
                label_box = field['label_bounding_box']
                # Draw red rectangle over entry bounding box and blue rectangle over the label.
                draw.rectangle(entry_box, outline='red', width=2)
                draw.rectangle(label_box, outline='blue', width=2)
                num_boxes += 2
        
        img.save(output_path)
        print(f"Created validation image at {output_path} with {num_boxes} bounding boxes")


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: create_validation_image.py [page number] [fields.json file] [input image path] [output image path]")
        sys.exit(1)
    page_number = int(sys.argv[1])
    fields_json_path = sys.argv[2]
    input_image_path = sys.argv[3]
    output_image_path = sys.argv[4]
    create_validation_image(page_number, fields_json_path, input_image_path, output_image_path)
