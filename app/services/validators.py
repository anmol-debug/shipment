"""
Business Data Validators
Validates shipment data fields for correctness and format
"""
import re
from typing import Dict, Any, List, Optional
from datetime import datetime


class ValidationError(Exception):
    """Custom exception for validation errors"""
    pass


class ShipmentValidator:
    """Validates shipment data fields"""

    # Valid enum values
    VALID_STATUSES = {'new', 'pending', 'in_progress', 'completed', 'cancelled', 'archived'}
    VALID_TRANSPORT_MODES = {'ocean', 'air', 'land', 'rail'}

    # Regex patterns
    CONTAINER_NUMBER_PATTERN = r'^[A-Z]{4}\d{7}$'  # ISO 6346: 4 letters + 7 digits
    BOL_NUMBER_PATTERN = r'^[A-Z0-9\-]{4,20}$'  # Alphanumeric with dashes, 4-20 chars
    ALPHANUMERIC_PATTERN = r'^[A-Za-z0-9\s\-.,/()]+$'  # Alphanumeric with common punctuation

    @classmethod
    def validate_snapshot_data(cls, snapshot_data: Dict[str, Any]) -> List[str]:
        """
        Validate all fields in snapshot_data
        Returns list of error messages (empty if valid)
        """
        errors = []

        # Required fields check
        if not snapshot_data.get('id'):
            errors.append("Validation Error: 'id' is required")

        if not snapshot_data.get('title'):
            errors.append("Validation Error: 'title' is required")

        # Validate each field if present
        if 'status' in snapshot_data:
            error = cls.validate_status(snapshot_data['status'])
            if error:
                errors.append(error)

        if 'transportMode' in snapshot_data:
            error = cls.validate_transport_mode(snapshot_data['transportMode'])
            if error:
                errors.append(error)

        if 'container_number' in snapshot_data:
            error = cls.validate_container_number(snapshot_data['container_number'])
            if error:
                errors.append(error)

        if 'house_bol_number' in snapshot_data:
            error = cls.validate_bol_number(snapshot_data['house_bol_number'], 'House BOL')
            if error:
                errors.append(error)

        if 'master_bol_number' in snapshot_data:
            error = cls.validate_bol_number(snapshot_data['master_bol_number'], 'Master BOL')
            if error:
                errors.append(error)

        if 'port_of_loading' in snapshot_data:
            error = cls.validate_port_name(snapshot_data['port_of_loading'], 'Port of Loading')
            if error:
                errors.append(error)

        if 'port_of_discharge' in snapshot_data:
            error = cls.validate_port_name(snapshot_data['port_of_discharge'], 'Port of Discharge')
            if error:
                errors.append(error)

        if 'gross_weight_kgs' in snapshot_data:
            error = cls.validate_weight(snapshot_data['gross_weight_kgs'])
            if error:
                errors.append(error)

        if 'vessel_name' in snapshot_data:
            error = cls.validate_vessel_name(snapshot_data['vessel_name'])
            if error:
                errors.append(error)

        if 'voyage_number' in snapshot_data:
            error = cls.validate_voyage_number(snapshot_data['voyage_number'])
            if error:
                errors.append(error)

        if 'flight_number' in snapshot_data:
            error = cls.validate_flight_number(snapshot_data['flight_number'])
            if error:
                errors.append(error)

        if 'consignee_name' in snapshot_data:
            error = cls.validate_name(snapshot_data['consignee_name'], 'Consignee Name')
            if error:
                errors.append(error)

        if 'shipper_name' in snapshot_data:
            error = cls.validate_name(snapshot_data['shipper_name'], 'Shipper Name')
            if error:
                errors.append(error)

        return errors

    @staticmethod
    def validate_status(status: Any) -> Optional[str]:
        """Validate status field"""
        if not status:
            return None  # Optional field

        if not isinstance(status, str):
            return "Validation Error: 'status' must be a string"

        if status.lower() not in ShipmentValidator.VALID_STATUSES:
            return f"Validation Error: Invalid status '{status}'. Must be one of: {', '.join(sorted(ShipmentValidator.VALID_STATUSES))}"

        return None

    @staticmethod
    def validate_transport_mode(mode: Any) -> Optional[str]:
        """Validate transport mode field"""
        if not mode:
            return None  # Optional field

        if not isinstance(mode, str):
            return "Validation Error: 'transportMode' must be a string"

        if mode.lower() not in ShipmentValidator.VALID_TRANSPORT_MODES:
            return f"Validation Error: Invalid transport mode '{mode}'. Must be one of: {', '.join(sorted(ShipmentValidator.VALID_TRANSPORT_MODES))}"

        return None

    @staticmethod
    def validate_container_number(container_num: Any) -> Optional[str]:
        """Validate container number (ISO 6346 format)"""
        if not container_num:
            return None  # Optional field

        if not isinstance(container_num, str):
            return "Validation Error: Container number must be a string"

        # Remove whitespace
        container_num = container_num.strip().upper()

        if not re.match(ShipmentValidator.CONTAINER_NUMBER_PATTERN, container_num):
            return "Validation Error: Invalid container number format. Must be 4 uppercase letters followed by 7 digits (e.g., MSCU1234567)"

        return None

    @staticmethod
    def validate_bol_number(bol_num: Any, field_name: str) -> Optional[str]:
        """Validate Bill of Lading number"""
        if not bol_num:
            return None  # Optional field

        if not isinstance(bol_num, str):
            return f"Validation Error: {field_name} must be a string"

        # Remove whitespace
        bol_num = bol_num.strip()

        if len(bol_num) < 4:
            return f"Validation Error: {field_name} must be at least 4 characters"

        if len(bol_num) > 20:
            return f"Validation Error: {field_name} must be at most 20 characters"

        if not re.match(ShipmentValidator.BOL_NUMBER_PATTERN, bol_num.upper()):
            return f"Validation Error: {field_name} must contain only letters, numbers, and dashes"

        return None

    @staticmethod
    def validate_port_name(port: Any, field_name: str) -> Optional[str]:
        """Validate port name (allows international characters)"""
        if not port:
            return None  # Optional field

        if not isinstance(port, str):
            return f"Validation Error: {field_name} must be a string"

        port = port.strip()

        if len(port) < 2:
            return f"Validation Error: {field_name} must be at least 2 characters"

        if len(port) > 100:
            return f"Validation Error: {field_name} must be at most 100 characters"

        # Allow letters (including international), numbers, spaces, commas, and basic punctuation
        # This allows ports like "Shanghai, China" or "Long Beach, CA"
        if not re.match(r'^[\w\s,.\-()]+$', port, re.UNICODE):
            return f"Validation Error: {field_name} contains invalid characters"

        return None

    @staticmethod
    def validate_weight(weight: Any) -> Optional[str]:
        """Validate weight field (must be positive number)"""
        if not weight:
            return None  # Optional field

        # Handle string input
        if isinstance(weight, str):
            weight = weight.strip()
            # Remove units if present (e.g., "1000 KGS" -> "1000")
            weight = re.sub(r'[A-Za-z\s]+$', '', weight).strip()

        try:
            weight_float = float(weight)
            if weight_float <= 0:
                return "Validation Error: Weight must be a positive number"
            if weight_float > 1000000:  # Sanity check: 1,000 tons
                return "Validation Error: Weight seems unreasonably high (max 1,000,000 kg)"
        except (ValueError, TypeError):
            return "Validation Error: Weight must be a valid number"

        return None

    @staticmethod
    def validate_vessel_name(vessel: Any) -> Optional[str]:
        """Validate vessel name"""
        if not vessel:
            return None  # Optional field

        if not isinstance(vessel, str):
            return "Validation Error: Vessel name must be a string"

        vessel = vessel.strip()

        if len(vessel) < 2:
            return "Validation Error: Vessel name must be at least 2 characters"

        if len(vessel) > 100:
            return "Validation Error: Vessel name must be at most 100 characters"

        # Allow letters, numbers, spaces, and common punctuation
        if not re.match(ShipmentValidator.ALPHANUMERIC_PATTERN, vessel):
            return "Validation Error: Vessel name contains invalid characters"

        return None

    @staticmethod
    def validate_voyage_number(voyage: Any) -> Optional[str]:
        """Validate voyage number"""
        if not voyage:
            return None  # Optional field

        if not isinstance(voyage, str):
            return "Validation Error: Voyage number must be a string"

        voyage = voyage.strip()

        if len(voyage) < 2:
            return "Validation Error: Voyage number must be at least 2 characters"

        if len(voyage) > 20:
            return "Validation Error: Voyage number must be at most 20 characters"

        # Alphanumeric only
        if not voyage.replace('-', '').replace('_', '').isalnum():
            return "Validation Error: Voyage number must be alphanumeric"

        return None

    @staticmethod
    def validate_flight_number(flight: Any) -> Optional[str]:
        """Validate flight number (e.g., AA123, UA4567)"""
        if not flight:
            return None  # Optional field

        if not isinstance(flight, str):
            return "Validation Error: Flight number must be a string"

        flight = flight.strip().upper()

        if len(flight) < 2:
            return "Validation Error: Flight number must be at least 2 characters"

        if len(flight) > 10:
            return "Validation Error: Flight number must be at most 10 characters"

        # Typically 2 letters + 1-4 digits (e.g., AA123)
        if not re.match(r'^[A-Z]{2,3}\d{1,4}$', flight):
            return "Validation Error: Flight number must be 2-3 letters followed by 1-4 digits (e.g., AA123)"

        return None

    @staticmethod
    def validate_name(name: Any, field_name: str) -> Optional[str]:
        """Validate company/person names (consignee, shipper, etc.)"""
        if not name:
            return None  # Optional field

        if not isinstance(name, str):
            return f"Validation Error: {field_name} must be a string"

        name = name.strip()

        if len(name) < 2:
            return f"Validation Error: {field_name} must be at least 2 characters"

        if len(name) > 200:
            return f"Validation Error: {field_name} must be at most 200 characters"

        # Allow letters (international), numbers, spaces, and common business punctuation
        if not re.match(r'^[\w\s,.\-&()\'\"]+$', name, re.UNICODE):
            return f"Validation Error: {field_name} contains invalid characters"

        return None


def validate_shipment_data(snapshot_data: Dict[str, Any], strict: bool = False) -> None:
    """
    Validate shipment data and raise exception if invalid

    Args:
        snapshot_data: Dictionary containing shipment fields
        strict: If True, raise exception on first error. If False, collect all errors.

    Raises:
        ValidationError: If validation fails
    """
    errors = ShipmentValidator.validate_snapshot_data(snapshot_data)

    if errors:
        if strict:
            # Raise first error
            raise ValidationError(errors[0])
        else:
            # Raise all errors combined
            error_message = "; ".join(errors)
            raise ValidationError(error_message)
