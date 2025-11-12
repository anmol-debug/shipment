# Shipment Document Extraction Application

A production-ready application that extracts shipment data from PDF and XLSX documents using AI (Claude by Anthropic).

## Features

- **Multi-Document Support**: Upload and process multiple PDF and XLSX files
- **AI-Powered Extraction**: Uses Claude 3.5 Sonnet to extract structured data from documents
- **Editable Forms**: Review and edit extracted data in an intuitive form interface
- **Document Viewer**: View uploaded PDFs side-by-side with extracted data for easy audit
- **Modern UI**: Clean, responsive React interface built with Vite
- **Robust Error Handling**: Comprehensive validation and error handling throughout

## Extracted Fields

The application extracts the following shipment data:

1. Bill of Lading Number
2. Container Number
3. Consignee Name
4. Consignee Address
5. Date of Export (MM/DD/YYYY)
6. Line Items Count
7. Average Gross Weight
8. Average Price

## Tech Stack

### Backend
- **FastAPI**: Modern, fast web framework for building APIs
- **Anthropic Claude API**: AI-powered document extraction
- **PyPDF2**: PDF text extraction
- **openpyxl**: Excel file processing
- **Uvicorn**: ASGI server

### Frontend
- **React**: UI library
- **Vite**: Fast build tool and dev server
- **CSS3**: Modern styling with CSS Grid and Flexbox

## Project Structure

```
.
├── app/
│   ├── api/
│   │   └── routes.py          # API endpoints
│   ├── core/
│   │   └── config.py          # Configuration settings
│   ├── services/
│   │   ├── document_processor.py  # Document processing logic
│   │   └── llm_service.py         # LLM integration
│   └── utils/
│       ├── pdf_utils.py       # PDF utilities
│       └── xlsx_utils.py      # XLSX utilities
├── frontend/
│   └── src/
│       ├── components/
│       │   ├── FileUpload.jsx
│       │   ├── ShipmentForm.jsx
│       │   └── DocumentViewer.jsx
│       └── App.jsx
├── main.py                    # FastAPI application entry point
└── requirements.txt           # Python dependencies
```

## Setup Instructions

### Prerequisites

- Python 3.12+ (works with Python 3.8+)
- Node.js 20.7+ (for frontend)
- npm
**Add the api key to the config.py and extractionService.js**:

### Backend Setup

1. **Install Python dependencies**:
   ```bash
   pip3 install -r requirements.txt
   ```

2. **Start the backend server**:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

   The API will be available at `http://localhost:8000`

3. **Test the backend**:
   ```bash
   curl http://localhost:8000/api/health
   ```

### Frontend Setup

1. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start the development server**:
   ```bash
   npm run dev
   ```

   The frontend will be available at `http://localhost:5173`

## Usage

1. **Open the application** in your browser at `http://localhost:5173`

2. **Upload documents**:
   - Click the upload area or drag and drop files
   - Select one or more PDF or XLSX files
   - Click "Extract Data"

3. **Review extracted data**:
   - View the extracted information in the editable form
   - Make any necessary corrections
   - View the original documents in the document viewer

4. **Save changes**:
   - Click "Save Changes" to persist any edits

## API Endpoints

### `GET /`
Root endpoint with API information

### `GET /api/health`
Health check endpoint

### `POST /api/extract`
Extract shipment data from uploaded documents

**Request**: `multipart/form-data` with files
**Response**:
```json
{
  "success": true,
  "data": {
    "billOfLadingNumber": "...",
    "containerNumber": "...",
    ...
  },
  "files": [...]
}
```

### `GET /uploads/{filename}`
Retrieve uploaded files

## Error Handling

The application includes comprehensive error handling:

- **File validation**: Only PDF and XLSX files are accepted
- **File size limits**: 10MB maximum per file
- **API error handling**: Graceful degradation with user-friendly error messages
- **Network error handling**: Frontend handles connection issues

## Design Decisions & Assumptions

### Backend
- Used FastAPI for its modern async capabilities and automatic API documentation
- Implemented temporary file handling with cleanup to prevent disk space issues
- Structured the code following a service-oriented architecture for maintainability
- Fixed bugs in the boilerplate (PdfFileReader → PdfReader, added XLSX support)

### Frontend
- Used Vite for faster development experience compared to Create React App
- Implemented drag-and-drop for better UX
- Side-by-side layout for document viewing and form editing
- Responsive design that works on tablets and desktops
- PDF preview in iframe, XLSX download option (browsers can't render Excel natively)

### AI Integration
- Used Claude 3.5 Sonnet for high accuracy in document extraction
- Structured prompts to ensure consistent JSON output
- Added fallback parsing for various response formats
- Implemented validation to ensure all required fields are present

### Security Considerations
- CORS enabled for development (should be restricted in production)
- File type validation on both frontend and backend
- File size limits to prevent DoS attacks
- Temporary file cleanup to prevent disk space exhaustion

## Known Limitations

1. **XLSX Preview**: Browsers cannot render Excel files natively, so XLSX files show a download button instead of a preview
2. **Large Files**: Very large PDF files may take longer to process
3. **Complex Layouts**: Documents with complex layouts or scanned images may have lower extraction accuracy
4. **API Key**: Anthropic API key is hardcoded for demo purposes (should use environment variables in production)

## Future Enhancements

- Add OCR support for scanned documents
- Implement user authentication and session management
- Add database integration for storing extracted data
- Support for additional document formats (DOC, images)
- Batch processing capabilities
- Export data to CSV/JSON
- Document template management

## Testing

To test the application:

1. Prepare test documents (PDF Bill of Lading and XLSX Commercial Invoice)
2. Start both backend and frontend servers
3. Upload the documents through the UI
4. Verify the extracted data matches the documents
5. Test editing and saving functionality

## Troubleshooting

### Backend won't start
- Ensure Python 3.12+ is installed
- Check if port 8000 is available
- Verify all dependencies are installed

### Frontend won't start
- Ensure Node.js is installed
- Delete `node_modules` and run `npm install` again
- Check if port 5173 is available

### Extraction fails
- Verify the Anthropic API key is valid
- Check document format (should be PDF or XLSX)
- Ensure documents are not corrupted

## License

MIT

## Author

Built with Claude Code for the Amari AI take-home project.
