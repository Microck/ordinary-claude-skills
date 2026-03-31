"""Detect whether a PDF contains fillable (AcroForm) form fields.

A lightweight script that opens a PDF and reports whether pypdf's
``get_fields`` returns any interactive form fields.  Used by downstream
tooling to decide whether to use native field filling or text annotations.
See forms.md.
"""

import sys
from pypdf import PdfReader


# Script for Claude to run to determine whether a PDF has fillable form fields. See forms.md.


reader = PdfReader(sys.argv[1])
if (reader.get_fields()):
    print("This PDF has fillable form fields")
else:
    print("This PDF does not have fillable form fields; you will need to visually determine where to enter data")
