"""
Authentication API endpoints
Handles login, logout, and session management using Supabase Auth
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from app.services.supabase_client import get_supabase
from typing import Optional

router = APIRouter()


class LoginRequest(BaseModel):
    """Login request with email and password"""
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Login response with user info and access token"""
    success: bool
    user_id: str
    email: str
    access_token: str
    refresh_token: str
    user_name: str
    role: str


class UserResponse(BaseModel):
    """Current user information"""
    success: bool
    user_id: str
    email: str
    user_name: str
    role: str


@router.post("/login", response_model=LoginResponse)
async def login(credentials: LoginRequest):
    """
    Login with email and password

    Returns:
        - access_token: JWT token for authenticated requests
        - refresh_token: Token to refresh the access token
        - user info: user_id, email, name, role
    """
    print(f"\n{'='*60}")
    print(f"LOGIN ATTEMPT")
    print(f"{'='*60}")
    print(f"Email: {credentials.email}")
    print(f"Password length: {len(credentials.password)}")

    try:
        supabase = get_supabase()
        print(f"Supabase client created: {supabase is not None}")
        print(f"Supabase URL: {supabase.supabase_url}")

        # Authenticate with Supabase
        print(f"Attempting sign_in_with_password...")
        auth_response = supabase.auth.sign_in_with_password({
            "email": credentials.email,
            "password": credentials.password
        })

        print(f"Auth response received")
        print(f"User object: {auth_response.user}")
        print(f"Session object: {auth_response.session}")

        if not auth_response.user:
            print(f"ERROR: No user in auth_response")
            raise HTTPException(status_code=401, detail="Invalid credentials")

        user_id = auth_response.user.id
        print(f"User ID: {user_id}")

        # Get user profile for additional info (name, role)
        print(f"Fetching profile for user: {user_id}")
        profile_response = supabase.table('profiles')\
            .select('first_name, last_name, role')\
            .eq('id', user_id)\
            .single()\
            .execute()

        profile = profile_response.data if profile_response.data else {}
        user_name = f"{profile.get('first_name', '')} {profile.get('last_name', '')}".strip()
        print(f"Profile found: {profile}")

        print(f"LOGIN SUCCESS for {credentials.email}")
        print(f"{'='*60}\n")

        return LoginResponse(
            success=True,
            user_id=user_id,
            email=auth_response.user.email,
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_name=user_name or "Unknown User",
            role=profile.get('role', 'user')
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"LOGIN ERROR: {type(e).__name__}: {str(e)}")
        print(f"Full error: {repr(e)}")
        import traceback
        traceback.print_exc()
        print(f"{'='*60}\n")
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")


@router.post("/logout")
async def logout():
    """
    Logout current user
    Client should clear tokens after this call
    """
    try:
        supabase = get_supabase()
        supabase.auth.sign_out()

        return {"success": True, "message": "Logged out successfully"}
    except Exception as e:
        print(f"Logout error: {e}")
        raise HTTPException(status_code=500, detail=f"Logout failed: {str(e)}")


@router.get("/me", response_model=UserResponse)
async def get_current_user(authorization: Optional[str] = None):
    """
    Get current authenticated user info
    Requires Authorization header with Bearer token
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")

    try:
        access_token = authorization.split(" ")[1]
        supabase = get_supabase()

        # Get user from token
        user_response = supabase.auth.get_user(access_token)

        if not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

        user_id = user_response.user.id

        # Get profile info
        profile_response = supabase.table('profiles')\
            .select('first_name, last_name, role')\
            .eq('id', user_id)\
            .single()\
            .execute()

        profile = profile_response.data if profile_response.data else {}
        user_name = f"{profile.get('first_name', '')} {profile.get('last_name', '')}".strip()

        return UserResponse(
            success=True,
            user_id=user_id,
            email=user_response.user.email,
            user_name=user_name or "Unknown User",
            role=profile.get('role', 'user')
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Get user error: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")
