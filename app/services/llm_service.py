from anthropic import Anthropic
from app.core.config import settings
import json

client = Anthropic(api_key=settings.ANTHROPIC_API_KEY)


def extract_field_from_document(document_text):
    """
    Use Claude AI to extract shipment data from document text or images.

    Args:
        document_text: Combined text from all documents (may contain IMAGE_PDF markers)

    Returns:
        dict: Extracted shipment data with all required fields
    """

    # Check if we have image-based PDFs
    if "IMAGE_PDF:" in document_text:
        return extract_from_image_pdf(document_text)

    prompt = f"""You are an AI assistant specialized in extracting shipment data from documents.
I will provide you with the text content of shipment documents (Bill of Lading, Commercial Invoice, Packing List, etc.).

Please extract the following fields and return them in a JSON format:

1. billOfLadingNumber - The B/L number or BOL number from PDF or Excel
2. containerNumber - The container number (e.g., ABCD1234567) from PDF or Excel
3. consigneeName - The name of the consignee/receiver (company name from "SHIP TO" in Excel or PDF)
4. consigneeAddress - The FULL delivery address of the consignee:
   - FIRST: Look in the PDF Bill of Lading for the "CONSIGNEE" or "NOTIFY PARTY" section
   - The address should include: street, city, state, ZIP code, country
   - If not in PDF, check Excel "SHIP TO" field (but it may only have company name)
   - Return the complete address, not just the company name
5. dateOfExport - The export date in MM/DD/YYYY format
6. lineItemsCount - COUNT the number of rows with S.No. values in the Excel Invoice sheet
7. averageGrossWeight - Find TOTAL weight from PDF, divide by lineItemsCount (format: "X.XX KG")
8. averagePrice - Sum Excel "Total Value (USD)" column E, divide by lineItemsCount (format: "$X.XX")

Important instructions:
- If a field is not found, use null as the value
- For dateOfExport, convert any date format to MM/DD/YYYY
- For lineItemsCount: COUNT numbered rows with S.No. in Excel Invoice sheet
- For averageGrossWeight: Use PDF TOTAL weight (not Excel sum), divide by lineItemsCount
- For averagePrice: Sum Excel "Total Value (USD)" column E, divide by lineItemsCount
- For consigneeAddress: Look in PDF FIRST (CONSIGNEE section), it should be a full street address
- Return ONLY valid JSON, no additional text or explanation
- Be precise and extract data exactly as it appears in the documents

Here are the documents:
{document_text}

Return the extracted data as JSON:"""

    try:
        message = client.messages.create(
            model="claude-3-opus-20240229",
            max_tokens=2000,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )

        response_text = message.content[0].text
        print(f"Claude response: {response_text}")

        # Parse JSON response
        json_match = response_text.strip()
        # Remove markdown code blocks if present
        if json_match.startswith("```"):
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
            json_match = json_match.strip()

        # Find JSON object
        start_idx = json_match.find("{")
        end_idx = json_match.rfind("}") + 1
        if start_idx != -1 and end_idx > start_idx:
            json_match = json_match[start_idx:end_idx]

        extracted_data = json.loads(json_match)

        # Validate and structure the response
        expected_fields = [
            'billOfLadingNumber',
            'containerNumber',
            'consigneeName',
            'consigneeAddress',
            'dateOfExport',
            'lineItemsCount',
            'averageGrossWeight',
            'averagePrice'
        ]

        result = {}
        for field in expected_fields:
            result[field] = extracted_data.get(field, None)

        return result

    except Exception as e:
        print(f"Error calling Claude API: {str(e)}")
        raise Exception(f"Failed to extract data with AI: {str(e)}")


def extract_from_image_pdf(document_text):
    """
    Extract data from scanned PDFs and other documents using Claude's vision API.
    Handles multiple IMAGE_PDF markers and combines with XLSX data.

    Args:
        document_text: Text containing IMAGE_PDF: markers and/or XLSX content

    Returns:
        dict: Extracted shipment data
    """
    try:
        # Build content array for multi-modal input
        content = []

        # Extract all IMAGE_PDF markers (there may be multiple PDFs)
        parts = document_text.split("IMAGE_PDF:")

        # Add all PDF images
        for i in range(1, len(parts)):
            # Extract base64 data for this PDF (everything before next newline or end)
            pdf_base64 = parts[i].split("\n")[0].strip()
            if pdf_base64 and not pdf_base64.startswith("==="):
                content.append({
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "image/png",
                        "data": pdf_base64
                    }
                })

        # Extract XLSX text content (everything that's not IMAGE_PDF data)
        xlsx_text = parts[0]  # Everything before first IMAGE_PDF
        for part in parts[1:]:
            # Get text after the base64 data
            lines = part.split("\n", 1)
            if len(lines) > 1:
                xlsx_text += "\n" + lines[1]

        # Build the prompt text
        prompt_text = """You have been provided with shipment documents including:
- Scanned PDF image(s): Bill of Lading with TOTAL gross weight for the entire shipment
- Excel/XLSX file(s): Commercial Invoice and Packing List with line items and individual prices

CRITICAL: Follow these EXACT instructions for each field:

1. billOfLadingNumber - Extract from PDF or Excel (e.g., "ZMLU34110002")

2. containerNumber - Extract from PDF or Excel (e.g., "MSCU1234567")

3. consigneeName - Extract "SHIP TO" company name from Excel Invoice sheet or PDF

4. consigneeAddress - Extract the full consignee delivery address:
   - FIRST: Look in the PDF Bill of Lading for the "CONSIGNEE" or "NOTIFY PARTY" section
   - The address typically includes: street, city, state, ZIP code, country
   - If not in PDF, check Excel "SHIP TO" field (but it may only have company name)
   - Return the complete address, not just the company name

5. dateOfExport - Extract date from ANY document, convert to MM/DD/YYYY format

6. lineItemsCount - COUNT the number of rows with S.No. values in the Excel Invoice sheet
   - Look for rows with numbered S.No. (1, 2, 3, etc.)
   - Count ALL numbered rows, even if some numbers are missing
   - Return the total COUNT as a number

7. averageGrossWeight - CRITICAL CALCULATION (DO NOT GET THIS WRONG):
   - Step 1: Find the TOTAL GROSS WEIGHT from the PDF Bill of Lading image
   - Look for text like "GROSS WEIGHT: 16250 KGS" or "TOTAL: 16250.00 KG"
   - This is the TOTAL for the entire shipment, NOT per item
   - Step 2: Take the lineItemsCount you found in step 6 (e.g., 18)
   - Step 3: Divide: (PDF total gross weight) / (lineItemsCount)
   - EXAMPLE: PDF shows "16250 KGS" and lineItemsCount is 18
     Calculation: 16250 / 18 = 902.78 KG
   - DO NOT use Excel weights. DO NOT sum anything. ONLY divide PDF total by count.
   - Format result as "X.XX KG"

8. averagePrice - Calculate from Excel Invoice sheet:
   - Find the "Total Value (USD)" column (column E)
   - Sum ALL total values in this column (not unit prices)
   - Calculate: (sum of total values) / (lineItemsCount from step 6)
   - Format as "$X.XX"

CRITICAL RULES (FOLLOW EXACTLY):
- For averageGrossWeight: Find PDF TOTAL gross weight (e.g., 16250 KG), divide by lineItemsCount
  WRONG: Using Excel weights, summing anything, calculating per-item weights
  RIGHT: 16250 / 18 = 902.78 KG
- For lineItemsCount: Count numbered rows in Excel Invoice sheet (not Packing List)
- For averagePrice: Use Excel "Total Value (USD)" column (column E), NOT unit prices
- For consigneeAddress: Look in the PDF Bill of Lading image FIRST for the "CONSIGNEE" section with full street address
- Excel SHIP TO field typically only has company name, not the full address
- Return ONLY valid JSON, no explanation or markdown
- If a field cannot be found, use null

"""

        if xlsx_text.strip():
            prompt_text += f"\n\nExcel/XLSX Packing List Data:\n{xlsx_text}\n"

        prompt_text += "\nReturn the extracted data as JSON:"

        content.append({
            "type": "text",
            "text": prompt_text
        })

        # Use Claude vision to read all documents
        message = client.messages.create(
            model="claude-3-opus-20240229",
            max_tokens=2000,
            messages=[{
                "role": "user",
                "content": content
            }]
        )

        response_text = message.content[0].text
        print(f"Claude vision response: {response_text}")

        # Parse JSON response
        json_match = response_text.strip()
        if json_match.startswith("```"):
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
            json_match = json_match.strip()

        start_idx = json_match.find("{")
        end_idx = json_match.rfind("}") + 1
        if start_idx != -1 and end_idx > start_idx:
            json_match = json_match[start_idx:end_idx]

        extracted_data = json.loads(json_match)

        # Validate and structure the response
        expected_fields = [
            'billOfLadingNumber',
            'containerNumber',
            'consigneeName',
            'consigneeAddress',
            'dateOfExport',
            'lineItemsCount',
            'averageGrossWeight',
            'averagePrice'
        ]

        result = {}
        for field in expected_fields:
            result[field] = extracted_data.get(field, None)

        return result

    except Exception as e:
        print(f"Error extracting from image PDF: {str(e)}")
        raise Exception(f"Failed to extract from scanned PDF: {str(e)}")
