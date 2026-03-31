"""Convert each page of a PDF to a PNG image.

Uses ``pdf2image`` to rasterise PDF pages at 200 DPI, optionally scales
images so that neither dimension exceeds a configurable maximum, and saves
each page as a numbered PNG file.
"""

import os
import sys

from pdf2image import convert_from_path


def convert(pdf_path, output_dir, max_dim=1000):
    """Convert every page of a PDF to a scaled PNG image.

    Renders pages at 200 DPI, resizes any image whose width or height
    exceeds ``max_dim`` while preserving aspect ratio, and writes the
    results to ``output_dir`` as ``page_1.png``, ``page_2.png``, etc.

    Args:
        pdf_path: Path to the input PDF file.
        output_dir: Directory where PNG images will be saved.
        max_dim: Maximum allowed width or height in pixels; images
            exceeding this are proportionally scaled down.
    """
    images = convert_from_path(pdf_path, dpi=200)

    for i, image in enumerate(images):
        # Scale image if needed to keep width/height under `max_dim`
        width, height = image.size
        if width > max_dim or height > max_dim:
            scale_factor = min(max_dim / width, max_dim / height)
            new_width = int(width * scale_factor)
            new_height = int(height * scale_factor)
            image = image.resize((new_width, new_height))
        
        image_path = os.path.join(output_dir, f"page_{i+1}.png")
        image.save(image_path)
        print(f"Saved page {i+1} as {image_path} (size: {image.size})")

    print(f"Converted {len(images)} pages to PNG images")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: convert_pdf_to_images.py [input pdf] [output directory]")
        sys.exit(1)
    pdf_path = sys.argv[1]
    output_directory = sys.argv[2]
    convert(pdf_path, output_directory)
