# Storage System Guide

## Overview

The application now saves extracted data and uploaded files organized by Bill of Lading (B/L) number. This allows you to:
- Save extraction results along with original documents
- Retrieve previously saved data by B/L number
- Track user edits to extracted data
- Access all files related to a specific shipment

## Storage Structure

```
storage/
├── ZMLU34110002/                    # Folder named by B/L number
│   ├── metadata.json                # Extracted data + timestamps
│   ├── BL-COSU534343282.pdf        # Original PDF file
│   └── Demo-Invoice-PackingList_1.xlsx  # Original Excel file
└── [other B/L numbers]/
```

## How It Works

### 1. **Upload & Extract**
- User uploads PDF + XLSX files
- System extracts data using Claude AI
- Data is displayed in editable form

### 2. **Edit & Save**
- User reviews and edits extracted data
- Click "Save Changes" button
- System stores:
  - Edited extraction data
  - Original uploaded files
  - Timestamp
  - All organized by B/L number

### 3. **Retrieve Later**
- Use API to retrieve saved data by B/L number
- Get all files and metadata for that shipment

## API Endpoints

### Save Data
```bash
POST /api/save
Content-Type: application/json

{
  "extractedData": {
    "billOfLadingNumber": "ZMLU34110002",
    "containerNumber": "MSCU1234567",
    "consigneeName": "KABOFER TRADING INC",
    "consigneeAddress": "66-89 MAIN ST, FLUSHING, NY, 94089",
    "dateOfExport": "08/22/2019",
    "lineItemsCount": 18,
    "averageGrossWeight": "902.78 KG",
    "averagePrice": "$1289.51"
  },
  "files": [
    {"originalName": "BL-COSU534343282.pdf"},
    {"originalName": "Demo-Invoice-PackingList_1.xlsx"}
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Data saved successfully for B/L ZMLU34110002",
  "storagePath": "ZMLU34110002"
}
```

### Retrieve Data by B/L Number
```bash
GET /api/retrieve/ZMLU34110002
```

**Response:**
```json
{
  "success": true,
  "data": {
    "billOfLadingNumber": "ZMLU34110002",
    "savedAt": "2025-11-11T18:24:04.730017",
    "extractedData": { ... },
    "files": [ ... ]
  }
}
```

### List All Saved B/L Numbers
```bash
GET /api/list
```

**Response:**
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "billOfLadingNumber": "ZMLU34110002",
      "savedAt": "2025-11-11T18:24:04.730017",
      "containerNumber": "MSCU1234567",
      "consigneeName": "KABOFER TRADING INC"
    }
  ]
}
```

## Testing

### Quick Test Script
```bash
./test_storage.sh
```

### Manual Testing

1. **Test in Browser:**
   - Go to http://localhost:5173
   - Upload documents
   - Edit extracted data
   - Click "Save Changes"
   - Alert should confirm save

2. **Test via API:**
   ```bash
   # List saved B/L numbers
   curl http://localhost:8000/api/list | python3 -m json.tool

   # Retrieve specific B/L
   curl http://localhost:8000/api/retrieve/ZMLU34110002 | python3 -m json.tool
   ```

3. **Check File System:**
   ```bash
   ls -la storage/ZMLU34110002/
   cat storage/ZMLU34110002/metadata.json | python3 -m json.tool
   ```

## Key Features

✅ **Automatic Organization** - Files organized by B/L number
✅ **Edit Tracking** - Saves user-edited data, not just AI extraction
✅ **File Preservation** - Original documents stored with metadata
✅ **Timestamp Tracking** - Records when data was saved
✅ **Easy Retrieval** - Simple API to get data by B/L number
✅ **List View** - See all saved shipments at a glance

## Error Handling

- **Missing B/L Number:** Returns 400 error if B/L number is not provided
- **Not Found:** Returns 404 if B/L number doesn't exist in storage
- **Invalid Characters:** B/L numbers are sanitized (alphanumeric + underscore only)

## Production Considerations

For production deployment, consider:
1. **Database Storage** - Use PostgreSQL/MongoDB instead of file system
2. **Cloud Storage** - Store files in S3/Cloud Storage
3. **Authentication** - Add user authentication and authorization
4. **Versioning** - Track multiple versions of same B/L
5. **Search** - Add full-text search across all shipments
6. **Backup** - Automated backups of storage directory

## Troubleshooting

**Problem:** "B/L number is required" error
- **Solution:** Ensure the extracted data includes a valid billOfLadingNumber

**Problem:** Files not saved
- **Solution:** Check that files exist in uploads/ directory before saving

**Problem:** Cannot retrieve data
- **Solution:** Verify the B/L number exactly matches (case-sensitive)

## Example Usage Flow

```bash
# 1. Upload and extract via frontend
# (User uploads files at http://localhost:5173)

# 2. Edit data and save
# (User clicks "Save Changes" button)

# 3. List all saved shipments
curl http://localhost:8000/api/list

# 4. Retrieve specific shipment
curl http://localhost:8000/api/retrieve/ZMLU34110002

# 5. Access saved files
ls storage/ZMLU34110002/
# Files: metadata.json, BL-COSU534343282.pdf, Demo-Invoice-PackingList_1.xlsx
```

## Next Steps

To extend this functionality:
1. Add a "Load Previous" feature in the UI
2. Show list of saved B/L numbers on the homepage
3. Add search/filter functionality
4. Export data to CSV or Excel
5. Compare multiple versions of same B/L
