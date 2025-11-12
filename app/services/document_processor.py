import os
from app.utils.pdf_utils import extract_text_from_pdf
from app.utils.xlsx_utils import extract_text_from_xlsx

def process_documents(file_paths):
    """
    Process different types of documents and extract relevant information.

    Args:
        file_paths: List of paths to the documents

    Returns:
        str: Combined text from all documents
    """
    all_text = ""

    for file_path in file_paths:
        filename = os.path.basename(file_path)

        if file_path.endswith(".pdf"):
            text = extract_text_from_pdf(file_path)
            all_text += f"\n\n=== Document: {filename} (PDF) ===\n{text}"
        elif file_path.endswith(".xlsx") or file_path.endswith(".xls"):
            text = extract_text_from_xlsx(file_path)
            all_text += f"\n\n=== Document: {filename} (XLSX) ===\n{text}"

    return all_text 