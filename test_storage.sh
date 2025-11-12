#!/bin/bash

echo "==================================="
echo "Testing Storage API Endpoints"
echo "==================================="
echo ""

echo "1. List all saved B/L numbers:"
echo "curl http://localhost:8000/api/list"
curl -s http://localhost:8000/api/list | python3 -m json.tool
echo ""
echo ""

echo "2. Retrieve specific B/L (ZMLU34110002):"
echo "curl http://localhost:8000/api/retrieve/ZMLU34110002"
curl -s http://localhost:8000/api/retrieve/ZMLU34110002 | python3 -m json.tool
echo ""
echo ""

echo "3. Check storage directory structure:"
echo "ls -R storage/"
ls -R storage/
echo ""
echo ""

echo "==================================="
echo "API Documentation:"
echo "==================================="
echo ""
echo "POST /api/save - Save extracted data with files"
echo "  Body: { extractedData: {...}, files: [...] }"
echo ""
echo "GET /api/retrieve/{bl_number} - Get saved data by B/L number"
echo ""
echo "GET /api/list - List all saved B/L numbers"
echo ""
echo "Frontend: Click 'Save Changes' button to save data"
echo ""
