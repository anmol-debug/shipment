import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import './ShipmentEditor.css';

const API_BASE = 'http://localhost:8000/api';

function ShipmentEditor({ shipment, onClose, onSaved }) {
  const { user } = useAuth();
  const [formData, setFormData] = useState({
    status: shipment.status || '',
    title: shipment.title || '',
    description: shipment.description || '',
    transportMode: shipment.transportMode || '',
    ...shipment.extracted_data
  });
  const [reason, setReason] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState(null);

  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleSave = async () => {
    if (!reason.trim()) {
      setError('Please provide a reason for this change');
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      // Calculate field changes (diff)
      const fieldChanges = {};
      const oldData = { status: shipment.status, ...shipment.extracted_data };

      Object.keys(formData).forEach(key => {
        if (formData[key] !== oldData[key]) {
          fieldChanges[key] = {
            old: oldData[key],
            new: formData[key]
          };
        }
      });

      if (Object.keys(fieldChanges).length === 0) {
        setError('No changes detected');
        setIsSaving(false);
        return;
      }

      // Create audit event with complete snapshot data (including id and title)
      const snapshotData = {
        id: shipment.id,  // Required by validation
        title: formData.title || shipment.title,  // Required by validation
        ...formData
      };

      const auditResponse = await fetch(`${API_BASE}/shipments/${shipment.id}/audit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event_type: formData.status !== shipment.status ? 'status_changed' : 'updated',
          actor_id: user?.id || 'unknown',
          actor_name: user?.name || 'Unknown User',
          reason: reason,
          field_changes: fieldChanges,
          snapshot_data: snapshotData,
          metadata: {
            changed_fields: Object.keys(fieldChanges)
          }
        })
      });

      if (!auditResponse.ok) {
        // Extract the detailed error message from the backend
        const errorData = await auditResponse.json();
        const errorMessage = errorData.detail || 'Failed to save changes';
        throw new Error(errorMessage);
      }

      const result = await auditResponse.json();

      alert(`✅ Changes saved as version ${result.version_no}`);

      if (onSaved) {
        onSaved(result);
      }

      onClose();

    } catch (err) {
      setError(err.message);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="editor-overlay">
      <div className="editor-modal">
        <div className="editor-header">
          <h2>Edit Shipment: {shipment.title}</h2>
          <button onClick={onClose} className="btn-close">×</button>
        </div>

        <div className="editor-body">
          {error && (
            <div className="error-banner">
              ⚠️ {error}
            </div>
          )}

          <div className="form-grid">
            {/* Status */}
            <div className="form-group">
              <label>Status</label>
              <select
                value={formData.status}
                onChange={(e) => handleInputChange('status', e.target.value)}
              >
                <option value="new">New</option>
                <option value="pending">Pending</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
              </select>
            </div>

            {/* Transport Mode */}
            <div className="form-group">
              <label>Transport Mode</label>
              <select
                value={formData.transportMode}
                onChange={(e) => handleInputChange('transportMode', e.target.value)}
              >
                <option value="ocean">Ocean</option>
                <option value="air">Air</option>
                <option value="land">Land</option>
              </select>
            </div>

            {/* Vessel Name */}
            {formData.vessel_name !== undefined && (
              <div className="form-group">
                <label>Vessel Name</label>
                <input
                  type="text"
                  value={formData.vessel_name || ''}
                  onChange={(e) => handleInputChange('vessel_name', e.target.value)}
                />
              </div>
            )}

            {/* Consignee Name */}
            {formData.consignee_name !== undefined && (
              <div className="form-group">
                <label>Consignee Name</label>
                <input
                  type="text"
                  value={formData.consignee_name || ''}
                  onChange={(e) => handleInputChange('consignee_name', e.target.value)}
                />
              </div>
            )}

            {/* House BOL Number */}
            {formData.house_bol_number !== undefined && (
              <div className="form-group">
                <label>House B/L Number</label>
                <input
                  type="text"
                  value={formData.house_bol_number || ''}
                  onChange={(e) => handleInputChange('house_bol_number', e.target.value)}
                />
              </div>
            )}

            {/* Master BOL Number */}
            {formData.master_bol_number !== undefined && (
              <div className="form-group">
                <label>Master B/L Number</label>
                <input
                  type="text"
                  value={formData.master_bol_number || ''}
                  onChange={(e) => handleInputChange('master_bol_number', e.target.value)}
                />
              </div>
            )}

            {/* Port of Loading */}
            {formData.port_of_loading !== undefined && (
              <div className="form-group">
                <label>Port of Loading</label>
                <input
                  type="text"
                  value={formData.port_of_loading || ''}
                  onChange={(e) => handleInputChange('port_of_loading', e.target.value)}
                />
              </div>
            )}

            {/* Port of Discharge */}
            {formData.port_of_discharge !== undefined && (
              <div className="form-group">
                <label>Port of Discharge</label>
                <input
                  type="text"
                  value={formData.port_of_discharge || ''}
                  onChange={(e) => handleInputChange('port_of_discharge', e.target.value)}
                />
              </div>
            )}

            {/* Gross Weight */}
            {formData.gross_weight_kgs !== undefined && (
              <div className="form-group">
                <label>Gross Weight (KGS)</label>
                <input
                  type="text"
                  value={formData.gross_weight_kgs || ''}
                  onChange={(e) => handleInputChange('gross_weight_kgs', e.target.value)}
                />
              </div>
            )}

            {/* Flight Number (for air shipments) */}
            {formData.flight_number !== undefined && (
              <div className="form-group">
                <label>Flight Number</label>
                <input
                  type="text"
                  value={formData.flight_number || ''}
                  onChange={(e) => handleInputChange('flight_number', e.target.value)}
                />
              </div>
            )}

            {/* Voyage Number (for ocean shipments) */}
            {formData.voyage_number !== undefined && (
              <div className="form-group">
                <label>Voyage Number</label>
                <input
                  type="text"
                  value={formData.voyage_number || ''}
                  onChange={(e) => handleInputChange('voyage_number', e.target.value)}
                />
              </div>
            )}
          </div>

          {/* Reason for change (required) */}
          <div className="form-group reason-group">
            <label>Reason for Change *</label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Explain why you're making these changes..."
              rows={3}
              required
            />
          </div>
        </div>

        <div className="editor-footer">
          <button onClick={onClose} className="btn-cancel" disabled={isSaving}>
            Cancel
          </button>
          <button onClick={handleSave} className="btn-save" disabled={isSaving}>
            {isSaving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default ShipmentEditor;
