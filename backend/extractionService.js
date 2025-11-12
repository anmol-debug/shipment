import Anthropic from '@anthropic-ai/sdk';
import pdf from 'pdf-parse';
import XLSX from 'xlsx';
import fs from 'fs';
import path from 'path';

const anthropic = new Anthropic({
  apiKey: ''
});

/**
 * Extract text from a PDF file
 */
async function extractPdfText(filePath) {
  try {
    const dataBuffer = fs.readFileSync(filePath);
    const data = await pdf(dataBuffer);
    return data.text;
  } catch (error) {
    console.error('Error extracting PDF text:', error);
    throw new Error(`Failed to extract PDF text: ${error.message}`);
  }
}

/**
 * Extract text from an XLSX file
 */
function extractXlsxText(filePath) {
  try {
    const workbook = XLSX.readFile(filePath);
    let allText = '';

    workbook.SheetNames.forEach(sheetName => {
      const worksheet = workbook.Sheets[sheetName];
      const sheetData = XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: '' });

      allText += `\n\n=== Sheet: ${sheetName} ===\n`;
      sheetData.forEach((row, rowIndex) => {
        if (row.some(cell => cell !== '')) {
          allText += row.join(' | ') + '\n';
        }
      });
    });

    return allText;
  } catch (error) {
    console.error('Error extracting XLSX text:', error);
    throw new Error(`Failed to extract XLSX text: ${error.message}`);
  }
}

/**
 * Extract text from all uploaded documents
 */
async function extractDocumentTexts(files) {
  const documentTexts = [];

  for (const file of files) {
    const ext = path.extname(file.originalname).toLowerCase();
    let text = '';

    try {
      if (ext === '.pdf') {
        text = await extractPdfText(file.path);
      } else if (ext === '.xlsx' || ext === '.xls') {
        text = extractXlsxText(file.path);
      }

      documentTexts.push({
        filename: file.originalname,
        type: ext,
        text: text
      });
    } catch (error) {
      console.error(`Error processing ${file.originalname}:`, error);
      throw error;
    }
  }

  return documentTexts;
}

/**
 * Use Claude AI to extract structured shipment data
 */
async function extractWithClaude(documentTexts) {
  const combinedText = documentTexts.map(doc =>
    `\n=== Document: ${doc.filename} (${doc.type}) ===\n${doc.text}`
  ).join('\n\n');

  const prompt = `You are an AI assistant specialized in extracting shipment data from documents.
I will provide you with the text content of shipment documents (Bill of Lading, Commercial Invoice, Packing List, etc.).

Please extract the following fields and return them in a JSON format:

1. billOfLadingNumber - The B/L number or BOL number
2. containerNumber - The container number (e.g., ABCD1234567)
3. consigneeName - The name of the consignee/receiver
4. consigneeAddress - The full address of the consignee
5. dateOfExport - The export date in MM/DD/YYYY format
6. lineItemsCount - Total number of line items/products
7. averageGrossWeight - Average gross weight (extract the unit as well, e.g., "1500 KG")
8. averagePrice - Average price per item or unit (extract currency and amount, e.g., "$150.00")

Important instructions:
- If a field is not found, use null as the value
- For dateOfExport, convert any date format to MM/DD/YYYY
- For averageGrossWeight and averagePrice, calculate the average if multiple items exist
- Return ONLY valid JSON, no additional text or explanation
- Be precise and extract data exactly as it appears in the documents

Here are the documents:
${combinedText}

Return the extracted data as JSON:`;

  try {
    const message = await anthropic.messages.create({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 2000,
      messages: [{
        role: 'user',
        content: prompt
      }]
    });

    const responseText = message.content[0].text;
    console.log('Claude response:', responseText);

    // Parse JSON response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('Failed to extract JSON from Claude response');
    }

    const extractedData = JSON.parse(jsonMatch[0]);

    // Validate required structure
    const expectedFields = [
      'billOfLadingNumber',
      'containerNumber',
      'consigneeName',
      'consigneeAddress',
      'dateOfExport',
      'lineItemsCount',
      'averageGrossWeight',
      'averagePrice'
    ];

    const result = {};
    expectedFields.forEach(field => {
      result[field] = extractedData[field] !== undefined ? extractedData[field] : null;
    });

    return result;
  } catch (error) {
    console.error('Error calling Claude API:', error);
    throw new Error(`Failed to extract data with AI: ${error.message}`);
  }
}

/**
 * Main function to extract shipment data from uploaded files
 */
export async function extractShipmentData(files) {
  try {
    console.log('Extracting text from documents...');
    const documentTexts = await extractDocumentTexts(files);

    console.log('Analyzing with Claude AI...');
    const extractedData = await extractWithClaude(documentTexts);

    console.log('Extraction complete:', extractedData);
    return extractedData;
  } catch (error) {
    console.error('Error in extractShipmentData:', error);
    throw error;
  }
}
