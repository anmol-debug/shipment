import { useState } from 'react';
import './App.css';
import FileUpload from './components/FileUpload';
import ShipmentForm from './components/ShipmentForm';
import DocumentViewer from './components/DocumentViewer';

function App() {
  const [extractedData, setExtractedData] = useState(null);
  const [uploadedFiles, setUploadedFiles] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleExtraction = async (files) => {
    console.log('handleExtraction called with files:', files);
    console.log('Number of files:', files.length);

    setIsLoading(true);
    setError(null);

    const formData = new FormData();
    Array.from(files).forEach((file, index) => {
      console.log(`Appending file ${index}:`, file.name, file.size, 'bytes');
      formData.append('files', file);
    });

    // Log FormData contents
    console.log('FormData entries:');
    for (let pair of formData.entries()) {
      console.log(pair[0], pair[1]);
    }

    try {
      const response = await fetch('http://localhost:8000/api/extract', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();

      if (result.success) {
        setExtractedData(result.data);
        setUploadedFiles(result.files);
      } else {
        throw new Error(result.message || 'Extraction failed');
      }
    } catch (err) {
      console.error('Error:', err);
      setError(err.message || 'Failed to extract data. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleReset = () => {
    setExtractedData(null);
    setUploadedFiles([]);
    setError(null);
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>Shipment Document Extraction</h1>
        <p>Upload your Bill of Lading and Commercial Invoice to extract shipment data</p>
      </header>

      <main className="app-main">
        {!extractedData ? (
          <div className="upload-section">
            <FileUpload
              onFilesSelected={handleExtraction}
              isLoading={isLoading}
            />
            {error && (
              <div className="error-message">
                <strong>Error:</strong> {error}
              </div>
            )}
          </div>
        ) : (
          <div className="extraction-results">
            <div className="results-header">
              <h2>Extracted Data</h2>
              <button onClick={handleReset} className="btn-secondary">
                Upload New Documents
              </button>
            </div>

            <div className="results-container">
              <div className="form-section">
                <ShipmentForm
                  initialData={extractedData}
                  onSave={async (data) => {
                    console.log('Saving data:', data);
                    try {
                      const response = await fetch('http://localhost:8000/api/save', {
                        method: 'POST',
                        headers: {
                          'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                          extractedData: data,
                          files: uploadedFiles
                        }),
                      });

                      const result = await response.json();

                      if (result.success) {
                        alert(`Data saved successfully for B/L ${data.billOfLadingNumber}!`);
                      } else {
                        alert('Failed to save data: ' + (result.message || 'Unknown error'));
                      }
                    } catch (err) {
                      console.error('Save error:', err);
                      alert('Failed to save data. Please try again.');
                    }
                  }}
                />
              </div>

              <div className="viewer-section">
                <DocumentViewer files={uploadedFiles} />
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
