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
            <iframe
              src={`http://localhost:8000/api/excel-preview/${currentFile.originalName}`}
              title={currentFile.originalName}
              width="100%"
              height="100%"
              style={{ border: 'none', background: '#f5f5f5' }}
            />
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
