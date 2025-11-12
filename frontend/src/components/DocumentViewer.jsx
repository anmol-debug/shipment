import { useState } from 'react';
import './DocumentViewer.css';

function DocumentViewer({ files }) {
  const [activeFile, setActiveFile] = useState(0);

  if (!files || files.length === 0) {
    return (
      <div className="document-viewer empty">
        <p>No documents to display</p>
      </div>
    );
  }

  const currentFile = files[activeFile];
  const isPdf = currentFile.originalName.toLowerCase().endsWith('.pdf');
  const isXlsx = currentFile.originalName.toLowerCase().endsWith('.xlsx') ||
                 currentFile.originalName.toLowerCase().endsWith('.xls');

  return (
    <div className="document-viewer">
      <div className="viewer-header">
        <h3>Documents</h3>
        {files.length > 1 && (
          <div className="file-tabs">
            {files.map((file, index) => (
              <button
                key={index}
                className={`file-tab ${index === activeFile ? 'active' : ''}`}
                onClick={() => setActiveFile(index)}
              >
                {file.originalName}
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="viewer-content">
        <div className="file-info">
          <span className="file-name">{currentFile.originalName}</span>
          <a
            href={`http://localhost:8000${currentFile.path}`}
            download={currentFile.originalName}
            className="btn-download"
          >
            Download
          </a>
        </div>

        <div className="viewer-frame">
          {isPdf ? (
            <iframe
              src={`http://localhost:8000${currentFile.path}`}
              title={currentFile.originalName}
              width="100%"
              height="100%"
            />
          ) : isXlsx ? (
            <div className="xlsx-preview">
              <div className="preview-message">
                <svg
                  className="file-icon"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                <p>Excel File Preview</p>
                <p className="preview-hint">
                  XLSX files cannot be previewed in the browser.
                  <br />
                  Download the file to view its contents.
                </p>
                <a
                  href={`http://localhost:8000${currentFile.path}`}
                  download={currentFile.originalName}
                  className="btn-primary"
                >
                  Download File
                </a>
              </div>
            </div>
          ) : (
            <div className="unsupported-preview">
              <p>Preview not available for this file type</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default DocumentViewer;
