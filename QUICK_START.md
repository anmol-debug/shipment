# Quick Start Guide

## Prerequisites
- Python 3.8+ installed
- Node.js 20+ installed
- Terminal/Command line access

## Installation & Setup (2 minutes)

### 1. Install Backend Dependencies
```bash
pip3 install -r requirements.txt
```

### 2. Install Frontend Dependencies
```bash
cd frontend
npm install
cd ..
```

## Running the Application (30 seconds)

### Option A: Using the Start Script (Recommended)
```bash
./start.sh
```

### Option B: Manual Start

**Terminal 1 - Start Backend:**
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Terminal 2 - Start Frontend:**
```bash
cd frontend
npm run dev
```

## Access the Application

Once both servers are running:

1. **Open your browser** and go to: `http://localhost:5173`
2. **Upload documents**: Click or drag PDF/XLSX files
3. **Review data**: Check the extracted shipment information
4. **Edit if needed**: Make corrections in the form
5. **Save**: Click "Save Changes" to confirm

## Testing the API Directly

You can also test the backend API:

```bash
# Health check
curl http://localhost:8000/api/health

# View API docs
open http://localhost:8000/docs
```

## Sample Test Flow

1. Prepare two test documents:
   - A Bill of Lading (PDF)
   - A Commercial Invoice (XLSX)

2. Upload both files at once

3. Wait 5-10 seconds for AI processing

4. Review extracted data:
   - Bill of Lading Number
   - Container Number
   - Consignee Name & Address
   - Date of Export
   - Line Items Count
   - Average Weight & Price

5. Make any corrections needed

6. Click "Save Changes"

## Troubleshooting

**Backend won't start:**
```bash
# Check if port 8000 is in use
lsof -i :8000

# Kill the process if needed
kill -9 <PID>
```

**Frontend won't start:**
```bash
# Clear and reinstall dependencies
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**Extraction fails:**
- Ensure documents are valid PDF or XLSX files
- Check that files aren't corrupted
- Verify API key is valid (hardcoded in config.py)

## Stopping the Application

Press `Ctrl+C` in the terminal(s) running the servers.

## Next Steps

- Read [README.md](README.md) for detailed documentation
- Check [ASSUMPTIONS.md](ASSUMPTIONS.md) for design decisions
- Review [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for implementation details

## Support

If you encounter any issues:
1. Check the console/terminal for error messages
2. Review the troubleshooting section above
3. Ensure all dependencies are installed correctly
4. Verify Python and Node versions meet requirements
