"""
Supabase client service for database operations
"""
from supabase import create_client, Client
from app.core.config import settings


class SupabaseService:
    """Singleton service for Supabase client"""

    _instance: Client = None

    @classmethod
    def get_client(cls) -> Client:
        """Get or create Supabase client instance"""
        if cls._instance is None:
            if not settings.SUPABASE_URL:
                raise ValueError(
                    "Supabase configuration is missing. "
                    "Please set SUPABASE_URL in your .env file"
                )

            # Use service key if available, otherwise fall back to anon key
            # NOTE: For production, service_role key is required for full permissions
            api_key = settings.SUPABASE_SERVICE_KEY or settings.SUPABASE_KEY

            if not api_key:
                raise ValueError(
                    "Supabase API key is missing. "
                    "Please set SUPABASE_SERVICE_KEY or SUPABASE_KEY in your .env file"
                )

            cls._instance = create_client(
                settings.SUPABASE_URL,
                api_key  # Use service key for backend operations
            )
        return cls._instance


# Convenience function to get the client
def get_supabase() -> Client:
    """Get the Supabase client instance"""
    return SupabaseService.get_client()
