# Data Extraction Logic

## Overview

This document explains the intelligent extraction logic used to process shipment documents and calculate averages.

---

## Document Sources

The application processes two types of documents:

### 1. PDF - Bill of Lading
- Contains shipping information
- Has **total gross weight** for the entire shipment
- May be scanned (image-based) or text-based
- Provides: B/L number, container number, consignee info, dates, total weight

### 2. XLSX - Commercial Invoice & Packing List
- Contains two sheets: "Invoice" and "Packing List"
- **Invoice sheet**: Has line items with unit prices
- **Packing List sheet**: Has line items with individual weights
- Provides: Line item details, prices, weights, consignee address

---

## Extraction Strategy

### Field 1-5: Direct Extraction
These fields are extracted directly from the documents:

1. **Bill of Lading Number**: From PDF or Excel
2. **Container Number**: From PDF or Excel
3. **Consignee Name**: Prioritizes Excel "SHIP TO" field (row 6)
4. **Consignee Address**: From Excel "SHIP TO" or PDF consignee field
5. **Date of Export**: From any document, converted to MM/DD/YYYY

### Field 6: Line Items Count
**Source**: Excel Invoice sheet

**Logic**:
```
Count all rows with numbered S.No. values in the Invoice sheet
```

**Example**:
- Invoice sheet has rows with S.No.: 1, 2, 3, ..., 18
- Result: `lineItemsCount = 18`

**Why Invoice sheet?**
- Invoice sheet is typically more complete than Packing List
- Some items may not have weights but still need to be counted
- Invoice sheet represents the actual products being sold

---

### Field 7: Average Gross Weight ⚠️ CRITICAL CALCULATION

**Formula**:
```
Average Gross Weight = (PDF Total Weight) ÷ (Line Items Count)
```

**Why this approach?**
1. **PDF has official total weight**: The Bill of Lading shows the total gross weight for the entire shipment (e.g., 16,250 KG)
2. **Excel individual weights may be incomplete**: The Packing List might have missing weights or only partial data
3. **Excel weights don't always sum to PDF total**: Due to missing items or measurement differences

**Example Calculation**:
```
PDF Total Weight: 16,250 KG
Line Items Count: 18 (from Excel Invoice)
Average = 16,250 ÷ 18 = 902.78 KG per item
```

**Why NOT sum Excel weights?**
- Excel Packing List sum: ~2,922 KG (only 18% of actual)
- Missing items or incomplete data
- PDF is the authoritative source for total weight

---

### Field 8: Average Price

**Formula**:
```
Average Price = (Sum of Total Values from Excel) ÷ (Line Items Count)
```

**Source**: Excel Invoice sheet, Column E ("Total Value (USD)")

**Logic**:
1. Find the "Total Value (USD)" column in Invoice sheet (column E)
2. Sum all total values for numbered items (not unit prices)
3. Divide by line items count

**Why Total Value and not Unit Price?**
- Total Value = Unit Price × Quantity
- Gives a better representation of actual invoice value per line
- Accounts for quantity differences between items

**Example Calculation**:
```
Total Values from column E:
$932, $611.28, $2326.50, $1943.37, $325.80, $22.08, $5302.98, $95.55,
$58.59, $534.47, $3979.02, $1740, $200, $1000, $279.60, $360, $3500, etc.

Sum of Total Values = Total Invoice Amount
Line Items Count = 18
Average = (Total Invoice Amount) ÷ 18 per line item
```

---

## Handling Edge Cases

### Scanned PDFs
- If PDF has no extractable text, convert to PNG image
- Use Claude vision API to read the image
- Extract data from visual content

### Multi-Sheet Excel Files
- Read all sheets (Invoice, Packing List, etc.)
- Prioritize Invoice sheet for prices and line item count
- Use Packing List for reference but not for calculations

### Missing Data
- If a field is not found in any document, return `null`
- Don't make assumptions or calculate with incomplete data
- Let the user manually fill in missing fields

### Empty Weight Cells
- Some items in Packing List may have empty weights
- This is why we use PDF total weight instead of summing Excel
- Individual item weights are for reference only

---

## Data Flow

```
1. User uploads PDF + XLSX files
   ↓
2. Backend receives files
   ↓
3. PDF Processing:
   - Try text extraction
   - If no text → Convert to PNG
   - Store as IMAGE_PDF marker
   ↓
4. XLSX Processing:
   - Read all sheets
   - Extract text with openpyxl
   - Store structured data
   ↓
5. LLM Processing:
   - Send PDF (text or image) + XLSX text to Claude
   - Claude analyzes all documents
   - Applies extraction rules:
     * Count line items from Invoice
     * Use PDF total for weight calculation
     * Sum prices from Invoice sheet
   ↓
6. Return structured JSON:
   {
     "billOfLadingNumber": "ZMLU34110002",
     "containerNumber": "MSCU1234567",
     "consigneeName": "KABOFER TRADING INC",
     "consigneeAddress": "...",
     "dateOfExport": "08/22/2019",
     "lineItemsCount": 18,
     "averageGrossWeight": "902.78 KG",
     "averagePrice": "$0.82"
   }
```

---

## Claude AI Instructions

The LLM is given explicit instructions:

1. **For Line Items**: "COUNT the number of rows with S.No. values in the Excel Invoice sheet"
2. **For Avg Weight**: "Find the TOTAL gross weight from the PDF... DO NOT sum individual weights from Excel"
3. **For Avg Price**: "Find the 'Unit Value (USD)' column... Sum ALL unit prices... Divide by lineItemsCount"

This ensures consistent and accurate extraction across different documents.

---

## Validation

After extraction, the system validates:
- All 8 fields are present (null if not found)
- Dates are in MM/DD/YYYY format
- Numbers are properly formatted with units
- Prices have currency symbols

---

## Future Improvements

Potential enhancements:
1. Add Python-based calculations for 100% accuracy
2. Detect and reconcile discrepancies between documents
3. Support for more document types (invoices, customs forms, etc.)
4. Multi-page PDF support
5. Confidence scores for extracted data
