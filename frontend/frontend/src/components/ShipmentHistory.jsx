import { useState, useEffect } from 'react';
import './ShipmentHistory.css';

function ShipmentHistory({ shipmentId, isOpen, onClose, onRestore }) {
  const [history, setHistory] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [selectedVersion, setSelectedVersion] = useState(null);
  const [viewMode, setViewMode] = useState('list'); // 'list', 'view', 'diff'
  const [compareVersion, setCompareVersion] = useState(null);
  const [filters, setFilters] = useState({
    actorName: '',
    eventType: '',
    startDate: '',
    endDate: ''
  });

  useEffect(() => {
    if (isOpen && shipmentId) {
      fetchHistory();
    }
  }, [isOpen, shipmentId]);

  const fetchHistory = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch(
        `http://localhost:8000/api/shipments/${shipmentId}/history?limit=50&offset=0`
      );

      if (!response.ok) {
        throw new Error('Failed to fetch history');
      }

      const data = await response.json();
      console.log('[ShipmentHistory] API Response:', data);
      console.log('[ShipmentHistory] History array length:', data.history?.length);
      setHistory(data.history || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchVersionDetails = async (versionNo) => {
    try {
      const response = await fetch(
        `http://localhost:8000/api/shipments/${shipmentId}/versions/${versionNo}`
      );

      if (!response.ok) {
        throw new Error('Failed to fetch version details');
      }

      const data = await response.json();
      console.log('[ShipmentHistory] Version details:', data);
      return data.version; // Extract the version object from the response
    } catch (err) {
      setError(err.message);
      return null;
    }
  };

  const handleViewVersion = async (event) => {
    const versionData = await fetchVersionDetails(event.version_no);
    if (versionData) {
      setSelectedVersion(versionData);
      setViewMode('view');
    }
  };

  const handleCompareVersions = async (event) => {
    if (!compareVersion) {
      setCompareVersion(event);
      return;
    }

    const version1 = await fetchVersionDetails(compareVersion.version_no);
    const version2 = await fetchVersionDetails(event.version_no);

    if (version1 && version2) {
      setSelectedVersion({ version1, version2 });
      setViewMode('diff');
      setCompareVersion(null);
    }
  };

  const handleRestore = async (event) => {
    const confirmed = window.confirm(
      `Are you sure you want to restore to version ${event.version_no}? This will create a new version with the restored data.`
    );

    if (!confirmed) return;

    const reason = window.prompt('Please provide a reason for restoring:');
    if (!reason) return;

    try {
      const response = await fetch(
        `http://localhost:8000/api/shipments/${shipmentId}/restore`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            source_version_no: event.version_no,
            actor_id: '550e8400-e29b-41d4-a716-446655440001', // TODO: Get from auth
            actor_name: 'Current User', // TODO: Get from auth
            reason: reason
          })
        }
      );

      if (!response.ok) {
        throw new Error('Failed to restore version');
      }

      const result = await response.json();
      alert(`Successfully restored to version ${event.version_no}. New version ${result.new_version_no} created.`);

      if (onRestore) {
        onRestore(result);
      }

      fetchHistory(); // Refresh history
    } catch (err) {
      alert(`Error: ${err.message}`);
    }
  };

  const applyFilters = () => {
    return history.filter(event => {
      if (filters.actorName && !event.actor_name?.toLowerCase().includes(filters.actorName.toLowerCase())) {
        return false;
      }
      if (filters.eventType && event.event_type !== filters.eventType) {
        return false;
      }
      if (filters.startDate && new Date(event.timestamp) < new Date(filters.startDate)) {
        return false;
      }
      if (filters.endDate && new Date(event.timestamp) > new Date(filters.endDate)) {
        return false;
      }
      return true;
    });
  };

  const formatDate = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const getEventIcon = (eventType) => {
    switch (eventType) {
      case 'created': return '➕';
      case 'updated': return '✏️';
      case 'status_changed': return '🔄';
      case 'restored': return '⏪';
      default: return '📝';
    }
  };

  const renderVersionList = () => {
    const filteredHistory = applyFilters();

    return (
      <div className="history-list">
        <div className="history-filters">
          <input
            type="text"
            placeholder="Filter by actor"
            value={filters.actorName}
            onChange={(e) => setFilters({ ...filters, actorName: e.target.value })}
            className="filter-input"
          />
          <select
            value={filters.eventType}
            onChange={(e) => setFilters({ ...filters, eventType: e.target.value })}
            className="filter-select"
          >
            <option value="">All Events</option>
            <option value="created">Created</option>
            <option value="updated">Updated</option>
            <option value="status_changed">Status Changed</option>
            <option value="restored">Restored</option>
          </select>
          <input
            type="date"
            value={filters.startDate}
            onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
            className="filter-input"
            placeholder="Start date"
          />
          <input
            type="date"
            value={filters.endDate}
            onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
            className="filter-input"
            placeholder="End date"
          />
        </div>

        <div className="versions-container">
          {filteredHistory.map((event) => (
            <div key={event.id} className={`version-item ${compareVersion?.id === event.id ? 'selected' : ''}`}>
              <div className="version-header">
                <span className="version-number">
                  {getEventIcon(event.event_type)} Version {event.version_no}
                </span>
                <span className="version-type">{event.event_type}</span>
              </div>

              <div className="version-details">
                <div className="version-meta">
                  <span className="version-actor">{event.actor_name || 'Unknown'}</span>
                  <span className="version-time">{formatDate(event.timestamp)}</span>
                </div>

                {event.reason && (
                  <div className="version-reason">
                    <strong>Reason:</strong> {event.reason}
                  </div>
                )}

                {event.field_changes && Object.keys(event.field_changes).length > 0 && (
                  <div className="version-changes">
                    <strong>Changes:</strong>
                    <ul>
                      {Object.entries(event.field_changes).map(([field, change]) => (
                        <li key={field}>
                          <span className="field-name">{field}:</span>
                          {typeof change === 'object' && change.old && change.new ? (
                            <span>
                              <span className="old-value">{change.old}</span>
                              {' → '}
                              <span className="new-value">{change.new}</span>
                            </span>
                          ) : (
                            <span>{JSON.stringify(change)}</span>
                          )}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>

              <div className="version-actions">
                <button
                  onClick={() => handleViewVersion(event)}
                  className="btn-action btn-view"
                  title="View full snapshot"
                >
                  View
                </button>
                <button
                  onClick={() => handleCompareVersions(event)}
                  className={`btn-action btn-diff ${compareVersion ? 'active' : ''}`}
                  title="Compare with another version"
                >
                  {compareVersion ? 'Compare' : 'Diff'}
                </button>
                <button
                  onClick={() => handleRestore(event)}
                  className="btn-action btn-restore"
                  title="Restore to this version"
                >
                  Restore
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderVersionView = () => {
    if (!selectedVersion) return null;

    return (
      <div className="version-view">
        <div className="view-header">
          <h3>Version {selectedVersion.version_no} Snapshot</h3>
          <button onClick={() => setViewMode('list')} className="btn-back">
            ← Back to List
          </button>
        </div>

        <div className="snapshot-data">
          <pre>{JSON.stringify(selectedVersion.snapshot_data, null, 2)}</pre>
        </div>

        <div className="snapshot-metadata">
          <h4>Metadata</h4>
          <dl>
            <dt>Event Type:</dt>
            <dd>{selectedVersion.event_type}</dd>
            <dt>Actor:</dt>
            <dd>{selectedVersion.actor_name}</dd>
            <dt>Timestamp:</dt>
            <dd>{formatDate(selectedVersion.timestamp)}</dd>
            {selectedVersion.reason && (
              <>
                <dt>Reason:</dt>
                <dd>{selectedVersion.reason}</dd>
              </>
            )}
          </dl>
        </div>
      </div>
    );
  };

  const renderVersionDiff = () => {
    if (!selectedVersion || !selectedVersion.version1 || !selectedVersion.version2) return null;

    const { version1, version2 } = selectedVersion;
    const data1 = version1.snapshot_data;
    const data2 = version2.snapshot_data;

    const allKeys = new Set([...Object.keys(data1 || {}), ...Object.keys(data2 || {})]);

    return (
      <div className="version-diff">
        <div className="diff-header">
          <h3>
            Comparing Version {version1.version_no} vs Version {version2.version_no}
          </h3>
          <button onClick={() => setViewMode('list')} className="btn-back">
            ← Back to List
          </button>
        </div>

        <div className="diff-container">
          <div className="diff-side">
            <h4>Version {version1.version_no}</h4>
            <div className="diff-meta">
              <p>{formatDate(version1.timestamp)}</p>
              <p>{version1.actor_name}</p>
            </div>
          </div>

          <div className="diff-side">
            <h4>Version {version2.version_no}</h4>
            <div className="diff-meta">
              <p>{formatDate(version2.timestamp)}</p>
              <p>{version2.actor_name}</p>
            </div>
          </div>
        </div>

        <div className="diff-fields">
          {Array.from(allKeys).map(key => {
            const val1 = data1?.[key];
            const val2 = data2?.[key];
            const isChanged = JSON.stringify(val1) !== JSON.stringify(val2);

            return (
              <div key={key} className={`diff-field ${isChanged ? 'changed' : ''}`}>
                <div className="field-name">{key}</div>
                <div className="field-values">
                  <div className="field-value old">
                    {typeof val1 === 'object' ? JSON.stringify(val1, null, 2) : String(val1 || '-')}
                  </div>
                  <div className="field-value new">
                    {typeof val2 === 'object' ? JSON.stringify(val2, null, 2) : String(val2 || '-')}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  if (!isOpen) return null;

  return (
    <div className="history-drawer-overlay" onClick={onClose}>
      <div className="history-drawer" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-header">
          <h2>Shipment History</h2>
          <button onClick={onClose} className="btn-close">
            ✕
          </button>
        </div>

        <div className="drawer-content">
          {isLoading && <div className="loading">Loading history...</div>}

          {error && (
            <div className="error-message">
              <strong>Error:</strong> {error}
            </div>
          )}

          {!isLoading && !error && (
            <>
              {viewMode === 'list' && renderVersionList()}
              {viewMode === 'view' && renderVersionView()}
              {viewMode === 'diff' && renderVersionDiff()}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export default ShipmentHistory;
