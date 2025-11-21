"""
Audit and Versioning Service - SINGLE TABLE DESIGN WITH VALIDATION
Handles creating history entries with full snapshots for shipments
Includes comprehensive validation and transaction integrity
"""
from typing import Dict, Any, List, Optional
from datetime import datetime
from app.services.supabase_client import get_supabase
from app.services.validators import validate_shipment_data, ValidationError
import json


class AuditService:
    """Service for managing shipment audit trail and versioning using single table"""

    def __init__(self):
        self._supabase = None

    @property
    def supabase(self):
        """Lazy-load Supabase client"""
        if self._supabase is None:
            self._supabase = get_supabase()
        return self._supabase

    async def create_audit_event(
        self,
        shipment_id: str,
        event_type: str,
        actor_id: str,
        actor_name: str,
        reason: Optional[str],
        field_changes: Dict[str, Any],  # NOTE: Deprecated - not stored, computed on-demand
        snapshot_data: Dict[str, Any],
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Create a history entry with event metadata and full snapshot

        Args:
            shipment_id: UUID of the shipment
            exvent_type: Type of event (created, updated, status_changed, restored, file_added, file_removed)
            actor_id: UUID of the user making the change
            actor_name: Display name of the user
            reason: Optional reason for the change
            field_changes: DEPRECATED - diffs are computed on-demand, not stored
            snapshot_data: Complete shipment data at this version
            metadata: Optional additional context (IP address, user agent, etc.)

        Returns:
            Dict with version_no and event details

        Raises:
            ValueError: If validation fails
            Exception: If database operation fails
        """
        # ========================================
        # CLIENT-SIDE VALIDATION
        # ========================================
        # Validate before calling database for better error messages

        if not shipment_id:
            raise ValueError("Validation Error: shipment_id is required")

        if not event_type:
            raise ValueError("Validation Error: event_type is required")

        valid_event_types = {'created', 'updated', 'status_changed', 'restored', 'file_added', 'file_removed', 'deleted', 'archived'}
        if event_type not in valid_event_types:
            raise ValueError(
                f"Validation Error: Invalid event_type '{event_type}'. "
                f"Must be one of: {', '.join(sorted(valid_event_types))}"
            )

        if not actor_id:
            raise ValueError("Validation Error: actor_id is required")

        if not actor_name or not actor_name.strip():
            raise ValueError("Validation Error: actor_name is required and cannot be empty")

        if not snapshot_data:
            raise ValueError("Validation Error: snapshot_data is required")

        if not isinstance(snapshot_data, dict):
            raise ValueError("Validation Error: snapshot_data must be a dictionary")

        # Validate snapshot has minimum required fields
        required_fields = {'id', 'title'}
        missing_fields = required_fields - set(snapshot_data.keys())
        if missing_fields:
            raise ValueError(
                f"Validation Error: snapshot_data missing required fields: {', '.join(missing_fields)}"
            )

        # ========================================
        # BUSINESS DATA VALIDATION
        # ========================================
        # Validate business data fields (container numbers, ports, weights, etc.)
        try:
            validate_shipment_data(snapshot_data, strict=False)
        except ValidationError as e:
            # Re-raise with proper type
            raise ValueError(str(e))

        # ========================================
        # DATABASE OPERATION (In transaction)
        # ========================================
        try:
            # Call the database function to create history entry
            # The function runs in a single transaction with all validation
            # Server assigns version_no atomically to prevent race conditions
            result = self.supabase.rpc(
                'create_history_entry',
                {
                    'p_shipment_id': shipment_id,
                    'p_event_type': event_type,
                    'p_actor_id': actor_id,
                    'p_actor_name': actor_name,
                    'p_reason': reason,
                    'p_snapshot_data': json.dumps(snapshot_data),
                    'p_metadata': json.dumps(metadata) if metadata else None
                }
            ).execute()

            version_no = result.data
            return {
                'success': True,
                'version_no': version_no,
                'shipment_id': shipment_id,
                'event_type': event_type,
                'timestamp': datetime.now().isoformat()
            }

        except Exception as e:
            error_msg = str(e)

            # Parse database errors for better messages
            if 'Validation Error' in error_msg:
                raise ValueError(error_msg)
            elif 'Integrity Error' in error_msg or 'unique_violation' in error_msg.lower():
                raise Exception(f"Integrity Error: Version conflict detected. Please retry. Details: {error_msg}")
            elif 'Transaction Error' in error_msg:
                raise Exception(f"Transaction Error: Failed to create audit entry. {error_msg}")
            else:
                raise Exception(f"Failed to create history entry: {error_msg}")

    async def get_shipment_history(
        self,
        shipment_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get history for a shipment from single table

        Args:
            shipment_id: UUID of the shipment
            limit: Maximum number of events to return
            offset: Number of events to skip (for pagination)

        Returns:
            List of history entries with event metadata
        """
        try:
            result = self.supabase.table('shipment_history') \
                .select('id, shipment_id, version_no, event_type, actor_id, actor_name, timestamp, reason, metadata') \
                .eq('shipment_id', shipment_id) \
                .order('version_no', desc=True) \
                .limit(limit) \
                .offset(offset) \
                .execute()

            # Optionally compute field_changes for each event by comparing with previous version
            events = result.data
            if events and len(events) > 0:
                # Sort ascending to compute diffs
                sorted_events = sorted(events, key=lambda x: x['version_no'])

                for i, event in enumerate(sorted_events):
                    if i > 0:
                        # Compute diff from previous version
                        try:
                            diff_result = self.supabase.rpc(
                                'get_field_changes',
                                {
                                    'p_shipment_id': shipment_id,
                                    'p_from_version': sorted_events[i-1]['version_no'],
                                    'p_to_version': event['version_no']
                                }
                            ).execute()
                            event['field_changes'] = diff_result.data if diff_result.data else {}
                        except:
                            event['field_changes'] = {}
                    else:
                        event['field_changes'] = {}  # First version has no changes

            return events

        except Exception as e:
            raise Exception(f"Failed to get shipment history: {str(e)}")

    async def get_version(
        self,
        shipment_id: str,
        version_no: int
    ) -> Optional[Dict[str, Any]]:
        """
        Get a specific version snapshot from history

        Args:
            shipment_id: UUID of the shipment
            version_no: Version number to retrieve

        Returns:
            Version data with full snapshot or None if not found
        """
        try:
            result = self.supabase.table('shipment_history') \
                .select('*') \
                .eq('shipment_id', shipment_id) \
                .eq('version_no', version_no) \
                .single() \
                .execute()

            if result.data:
                # Parse the JSON snapshot_data if it's a string
                version_data = result.data.copy()
                if isinstance(version_data.get('snapshot_data'), str):
                    version_data['snapshot_data'] = json.loads(version_data['snapshot_data'])
                return version_data

            return None

        except Exception as e:
            raise Exception(f"Failed to get version: {str(e)}")

    async def restore_version(
        self,
        shipment_id: str,
        source_version_no: int,
        actor_id: str,
        actor_name: str,
        reason: str
    ) -> Dict[str, Any]:
        """
        Restore a shipment to a previous version

        Args:
            shipment_id: UUID of the shipment
            source_version_no: Version number to restore from
            actor_id: UUID of the user performing restore
            actor_name: Display name of the user
            reason: Reason for restoring

        Returns:
            Dict with new version_no and restored data

        Raises:
            ValueError: If validation fails
            Exception: If database operation fails
        """
        # ========================================
        # CLIENT-SIDE VALIDATION
        # ========================================

        if not shipment_id:
            raise ValueError("Validation Error: shipment_id is required")

        if not source_version_no or source_version_no <= 0:
            raise ValueError("Validation Error: source_version_no must be a positive integer")

        if not actor_id:
            raise ValueError("Validation Error: actor_id is required")

        if not actor_name or not actor_name.strip():
            raise ValueError("Validation Error: actor_name is required and cannot be empty")

        # ========================================
        # DATABASE OPERATION (In transaction)
        # ========================================
        try:
            # Call the database function to restore
            # The function runs in a single transaction:
            # 1. Validates source version exists
            # 2. Updates shipment_requests table
            # 3. Creates new history entry
            # If any step fails, entire operation rolls back
            result = self.supabase.rpc(
                'restore_shipment_version',
                {
                    'p_shipment_id': shipment_id,
                    'p_source_version_no': source_version_no,
                    'p_actor_id': actor_id,
                    'p_actor_name': actor_name,
                    'p_reason': reason
                }
            ).execute()

            new_version_no = result.data
            return {
                'success': True,
                'new_version_no': new_version_no,
                'source_version_no': source_version_no,
                'shipment_id': shipment_id,
                'restored_by': actor_name,
                'timestamp': datetime.now().isoformat()
            }

        except Exception as e:
            error_msg = str(e)

            # Parse database errors for better messages
            if 'Validation Error' in error_msg:
                raise ValueError(error_msg)
            elif 'Restore Error' in error_msg:
                raise Exception(error_msg)
            else:
                raise Exception(f"Failed to restore version: {error_msg}")

    async def get_latest_version_no(self, shipment_id: str) -> int:
        """
        Get the latest version number for a shipment

        Args:
            shipment_id: UUID of the shipment

        Returns:
            Latest version number (0 if no versions exist)
        """
        try:
            result = self.supabase.table('shipment_history') \
                .select('version_no') \
                .eq('shipment_id', shipment_id) \
                .order('version_no', desc=True) \
                .limit(1) \
                .execute()

            if result.data and len(result.data) > 0:
                return result.data[0]['version_no']

            return 0

        except Exception as e:
            raise Exception(f"Failed to get latest version: {str(e)}")

    async def filter_events(
        self,
        shipment_id: str,
        actor_id: Optional[str] = None,
        event_type: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        field_name: Optional[str] = None,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Filter history entries by various criteria

        Args:
            shipment_id: UUID of the shipment
            actor_id: Filter by user who made changes
            event_type: Filter by event type
            start_date: Filter events after this date
            end_date: Filter events before this date
            field_name: Filter events that changed a specific field (requires computing diffs)
            limit: Maximum number of events to return

        Returns:
            List of filtered history entries
        """
        try:
            query = self.supabase.table('shipment_history') \
                .select('id, shipment_id, version_no, event_type, actor_id, actor_name, timestamp, reason, metadata') \
                .eq('shipment_id', shipment_id)

            if actor_id:
                query = query.eq('actor_id', actor_id)

            if event_type:
                query = query.eq('event_type', event_type)

            if start_date:
                query = query.gte('timestamp', start_date.isoformat())

            if end_date:
                query = query.lte('timestamp', end_date.isoformat())

            result = query.order('timestamp', desc=True) \
                .limit(limit) \
                .execute()

            events = result.data

            # Filter by field_name if specified (requires computing diffs)
            if field_name and events:
                filtered_events = []
                sorted_events = sorted(events, key=lambda x: x['version_no'])

                for i, event in enumerate(sorted_events):
                    if i > 0:
                        # Compute diff from previous version
                        try:
                            diff_result = self.supabase.rpc(
                                'get_field_changes',
                                {
                                    'p_shipment_id': shipment_id,
                                    'p_from_version': sorted_events[i-1]['version_no'],
                                    'p_to_version': event['version_no']
                                }
                            ).execute()
                            field_changes = diff_result.data if diff_result.data else {}

                            if field_name in field_changes:
                                event['field_changes'] = field_changes
                                filtered_events.append(event)
                        except:
                            pass

                return filtered_events

            return events

        except Exception as e:
            raise Exception(f"Failed to filter events: {str(e)}")


# Create singleton instance
audit_service = AuditService()
