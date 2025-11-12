import { useState } from 'react';
import './ShipmentForm.css';

function ShipmentForm({ initialData, onSave }) {
  const [formData, setFormData] = useState(initialData || {
    billOfLadingNumber: '',
    containerNumber: '',
    consigneeName: '',
    consigneeAddress: '',
    dateOfExport: '',
    lineItemsCount: '',
    averageGrossWeight: '',
    averagePrice: ''
  });

  const [isEdited, setIsEdited] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    setIsEdited(true);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(formData);
    setIsEdited(false);
  };

  const handleReset = () => {
    setFormData(initialData);
    setIsEdited(false);
  };

  return (
    <form className="shipment-form" onSubmit={handleSubmit}>
      <h3>Shipment Information</h3>

      <div className="form-grid">
        <div className="form-group">
          <label htmlFor="billOfLadingNumber">
            Bill of Lading Number <span className="required">*</span>
          </label>
          <input
            type="text"
            id="billOfLadingNumber"
            name="billOfLadingNumber"
            value={formData.billOfLadingNumber || ''}
            onChange={handleChange}
            placeholder="Enter B/L number"
          />
        </div>

        <div className="form-group">
          <label htmlFor="containerNumber">
            Container Number <span className="required">*</span>
          </label>
          <input
            type="text"
            id="containerNumber"
            name="containerNumber"
            value={formData.containerNumber || ''}
            onChange={handleChange}
            placeholder="e.g., ABCD1234567"
          />
        </div>

        <div className="form-group full-width">
          <label htmlFor="consigneeName">
            Consignee Name <span className="required">*</span>
          </label>
          <input
            type="text"
            id="consigneeName"
            name="consigneeName"
            value={formData.consigneeName || ''}
            onChange={handleChange}
            placeholder="Enter consignee name"
          />
        </div>

        <div className="form-group full-width">
          <label htmlFor="consigneeAddress">
            Consignee Address <span className="required">*</span>
          </label>
          <textarea
            id="consigneeAddress"
            name="consigneeAddress"
            value={formData.consigneeAddress || ''}
            onChange={handleChange}
            rows="3"
            placeholder="Enter full address"
          />
        </div>

        <div className="form-group">
          <label htmlFor="dateOfExport">
            Date of Export <span className="required">*</span>
          </label>
          <input
            type="text"
            id="dateOfExport"
            name="dateOfExport"
            value={formData.dateOfExport || ''}
            onChange={handleChange}
            placeholder="MM/DD/YYYY"
          />
        </div>

        <div className="form-group">
          <label htmlFor="lineItemsCount">
            Line Items Count <span className="required">*</span>
          </label>
          <input
            type="text"
            id="lineItemsCount"
            name="lineItemsCount"
            value={formData.lineItemsCount || ''}
            onChange={handleChange}
            placeholder="Number of items"
          />
        </div>

        <div className="form-group">
          <label htmlFor="averageGrossWeight">
            Average Gross Weight <span className="required">*</span>
          </label>
          <input
            type="text"
            id="averageGrossWeight"
            name="averageGrossWeight"
            value={formData.averageGrossWeight || ''}
            onChange={handleChange}
            placeholder="e.g., 1500 KG"
          />
        </div>

        <div className="form-group">
          <label htmlFor="averagePrice">
            Average Price <span className="required">*</span>
          </label>
          <input
            type="text"
            id="averagePrice"
            name="averagePrice"
            value={formData.averagePrice || ''}
            onChange={handleChange}
            placeholder="e.g., $150.00"
          />
        </div>
      </div>

      <div className="form-actions">
        <button
          type="button"
          className="btn-secondary"
          onClick={handleReset}
          disabled={!isEdited}
        >
          Reset
        </button>
        <button
          type="submit"
          className="btn-primary"
          disabled={!isEdited}
        >
          Save Changes
        </button>
      </div>
    </form>
  );
}

export default ShipmentForm;
