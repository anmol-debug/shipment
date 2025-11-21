import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import ShipmentHistory from './ShipmentHistory';
import ShipmentEditor from './ShipmentEditor';
import './ShipmentsDashboard.css';

const API_BASE = 'http://localhost:8000/api';

function ShipmentsDashboard() {
  const { user } = useAuth();
  const [shipments, setShipments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // History drawer state
  const [selectedShipment, setSelectedShipment] = useState(null);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);

  // Editor modal state
  const [editingShipment, setEditingShipment] = useState(null);
  const [isEditorOpen, setIsEditorOpen] = useState(false);

  // Fetch shipments on mount
  useEffect(() => {
    if (user?.id) {
      fetchShipments();
    }
  }, [user?.id]);

  const fetchShipments = async () => {
    if (!user?.id) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE}/shipments/user/${user.id}`, {
        headers: {
          'Authorization': `Bearer ${user.token}`
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setShipments(data.shipments);
    } catch (err) {
      setError(`Failed to fetch shipments: ${err.message}`);
      setShipments([]);
    } finally {
      setLoading(false);
    }
  };

  const openHistory = (shipment) => {
    setSelectedShipment(shipment);
    setIsHistoryOpen(true);
  };

  const closeHistory = () => {
    setIsHistoryOpen(false);
    setSelectedShipment(null);
  };

  const openEditor = (shipment) => {
    setEditingShipment(shipment);
    setIsEditorOpen(true);
  };

  const closeEditor = () => {
    setIsEditorOpen(false);
    setEditingShipment(null);
  };

  const handleShipmentSaved = (result) => {
    // Refresh the shipments list to show updated data
    fetchShipments();
    closeEditor();
  };

  const getStatusBadge = (status) => {
    const statusColors = {
      new: 'status-new',
      pending: 'status-pending',
      completed: 'status-completed',
      in_progress: 'status-in-progress'
    };

    return <span className={`status-badge ${statusColors[status] || ''}`}>{status}</span>;
  };

  return (
    <div className="shipments-dashboard">
      <div className="dashboard-header">
        <h1>📦 My Shipments</h1>
        <p className="subtitle">Logged in as: {user?.email}</p>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="loading">
          <div className="spinner"></div>
          <p>Loading shipments...</p>
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="error-message">
          <span>⚠️ {error}</span>
        </div>
      )}

      {/* Shipments List */}
      {!loading && shipments.length > 0 && (
        <div className="shipments-list">
          <div className="list-header">
            <h2>Shipments ({shipments.length})</h2>
          </div>

          <div className="shipments-grid">
            {shipments.map(shipment => (
              <div key={shipment.id} className="shipment-card">
                <div className="card-header">
                  <h3>{shipment.title}</h3>
                  {getStatusBadge(shipment.status)}
                </div>

                <div className="card-body">
                  {shipment.description && (
                    <p className="description">{shipment.description}</p>
                  )}

                  <div className="shipment-details">
                    <div className="detail-row">
                      <span className="label">Transport:</span>
                      <span className="value">{shipment.transportMode || 'N/A'}</span>
                    </div>

                    {shipment.extracted_data?.consignee_name && (
                      <div className="detail-row">
                        <span className="label">Consignee:</span>
                        <span className="value">{shipment.extracted_data.consignee_name}</span>
                      </div>
                    )}

                    {shipment.extracted_data?.vessel_name && (
                      <div className="detail-row">
                        <span className="label">Vessel:</span>
                        <span className="value">{shipment.extracted_data.vessel_name}</span>
                      </div>
                    )}

                    {shipment.extracted_data?.house_bol_number && (
                      <div className="detail-row">
                        <span className="label">B/L Number:</span>
                        <span className="value">{shipment.extracted_data.house_bol_number}</span>
                      </div>
                    )}

                    <div className="detail-row">
                      <span className="label">Created:</span>
                      <span className="value">{new Date(shipment.created_at).toLocaleDateString()}</span>
                    </div>
                  </div>
                </div>

                <div className="card-footer">
                  <button
                    onClick={() => openEditor(shipment)}
                    className="btn-edit"
                  >
                    ✏️ Edit
                  </button>
                  <button
                    onClick={() => openHistory(shipment)}
                    className="btn-history"
                  >
                    📜 View History
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Empty State */}
      {!loading && !error && shipments.length === 0 && (
        <div className="empty-state">
          <p>No shipments found for your account</p>
        </div>
      )}

      {/* Shipment History Drawer */}
      {selectedShipment && (
        <ShipmentHistory
          shipmentId={selectedShipment.id}
          shipmentTitle={selectedShipment.title}
          isOpen={isHistoryOpen}
          onClose={closeHistory}
          onRestore={(result) => {
            alert(`✅ Successfully restored to version ${result.source_version_no}`);
            // Refresh shipments list after restore
            fetchShipments();
          }}
        />
      )}

      {/* Shipment Editor Modal */}
      {editingShipment && isEditorOpen && (
        <ShipmentEditor
          shipment={editingShipment}
          onClose={closeEditor}
          onSaved={handleShipmentSaved}
        />
      )}
    </div>
  );
}

export default ShipmentsDashboard;
