import PyPDF2
import os
import base64
from typing import Optional, List
import pypdfium2 as pdfium

def extract_text_from_pdf(file_path: str) -> str:
    """
    Extract text from a PDF file. If the PDF is scanned (no text),
    returns base64 encoded images for vision-based extraction.

    Args:
        file_path: Path to the PDF file

    Returns:
        str: Extracted text or special marker for image-based PDF
    """
    text = ""

    # First try standard text extraction
    with open(file_path, "rb") as file:
        reader = PyPDF2.PdfReader(file)
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"

    # If no text found, it's likely a scanned PDF - convert to image
    if not text.strip():
        print(f"No text found in PDF, treating as scanned document")
        return extract_pdf_as_image(file_path)

    return text


def extract_pdf_as_image(file_path: str) -> str:
    """
    Convert PDF pages to base64 encoded PNG images for vision-based extraction.
    Returns a special marker that the LLM service will detect.
    """
    try:
        # Use pypdfium2 to render PDF pages to images
        pdf = pdfium.PdfDocument(file_path)

        # Convert first page to image
        page = pdf[0]

        # Render page to bitmap at 2x scale for better quality
        bitmap = page.render(scale=2.0)
        pil_image = bitmap.to_pil()

        # Convert PIL image to base64 PNG
        import io
        buffer = io.BytesIO()
        pil_image.save(buffer, format='PNG')
        image_data = base64.standard_b64encode(buffer.getvalue()).decode('utf-8')

        pdf.close()

        return f"IMAGE_PDF:{image_data}"

    except Exception as e:
        print(f"Error converting PDF to image: {e}")
        return "[Scanned PDF - text extraction not possible]"
