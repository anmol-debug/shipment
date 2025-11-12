import { useState, useRef } from 'react';
import './FileUpload.css';

function FileUpload({ onFilesSelected, isLoading }) {
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [dragActive, setDragActive] = useState(false);
  const fileInputRef = useRef(null);

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    const files = Array.from(e.dataTransfer.files);
    console.log('Files dropped:', files.length, files.map(f => f.name));

    const validFiles = files.filter(file => {
      const ext = file.name.split('.').pop().toLowerCase();
      return ext === 'pdf' || ext === 'xlsx' || ext === 'xls';
    });

    if (validFiles.length > 0) {
      console.log('Valid dropped files:', validFiles.length, validFiles.map(f => f.name));
      setSelectedFiles(validFiles);
    } else {
      alert('Please upload only PDF or XLSX files');
    }
  };

  const handleFileInput = (e) => {
    const files = Array.from(e.target.files);
    console.log('Files selected from input:', files.length, files.map(f => f.name));

    // Validate file types
    const validFiles = files.filter(file => {
      const ext = file.name.split('.').pop().toLowerCase();
      return ext === 'pdf' || ext === 'xlsx' || ext === 'xls';
    });

    if (validFiles.length !== files.length) {
      alert('Some files were ignored. Only PDF and XLSX files are allowed.');
    }

    console.log('Valid files to display:', validFiles.length, validFiles.map(f => f.name));
    setSelectedFiles(validFiles);
  };

  const handleSubmit = () => {
    if (selectedFiles.length === 0) {
      alert('Please select at least one file');
      return;
    }
    onFilesSelected(selectedFiles);
  };

  const removeFile = (index) => {
    setSelectedFiles(files => files.filter((_, i) => i !== index));
  };

  return (
    <div className="file-upload">
      <div
        className={`drop-zone ${dragActive ? 'active' : ''}`}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept=".pdf,.xlsx,.xls"
          onChange={handleFileInput}
          style={{ display: 'none' }}
        />

        <div className="drop-zone-content">
          <svg
            className="upload-icon"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
            />
          </svg>
          <p className="drop-zone-text">
            <strong>Click to upload</strong> or drag and drop
          </p>
          <p className="drop-zone-hint">PDF, XLSX files only</p>
        </div>
      </div>

      {selectedFiles.length > 0 && (
        <div className="selected-files">
          <h3>Selected Files:</h3>
          <ul className="file-list">
            {selectedFiles.map((file, index) => (
              <li key={index} className="file-item">
                <span className="file-name">{file.name}</span>
                <span className="file-size">
                  {(file.size / 1024).toFixed(1)} KB
                </span>
                <button
                  className="btn-remove"
                  onClick={() => removeFile(index)}
                  disabled={isLoading}
                >
                  ×
                </button>
              </li>
            ))}
          </ul>

          <button
            className="btn-primary"
            onClick={handleSubmit}
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <span className="spinner"></span>
                Extracting...
              </>
            ) : (
              'Extract Data'
            )}
          </button>
        </div>
      )}
    </div>
  );
}

export default FileUpload;
