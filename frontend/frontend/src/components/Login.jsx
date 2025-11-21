import React, { useState } from 'react';
import './Login.css';

const API_BASE = 'http://localhost:8000/api';

function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Login failed');
      }

      const data = await response.json();

      // Store authentication data in localStorage
      localStorage.setItem('access_token', data.access_token);
      localStorage.setItem('refresh_token', data.refresh_token);
      localStorage.setItem('user_id', data.user_id);
      localStorage.setItem('user_email', data.email);
      localStorage.setItem('user_name', data.user_name);
      localStorage.setItem('user_role', data.role);

      // Call success callback
      onLoginSuccess(data);

    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Quick login helpers for testing
  const quickLogin = (testEmail, testPassword) => {
    setEmail(testEmail);
    setPassword(testPassword);
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h1 className="login-title">📦 Shipments Portal</h1>
        <p className="login-subtitle">Sign in to manage your shipments</p>

        <form onSubmit={handleSubmit} className="login-form">
          {error && (
            <div className="login-error">
              ⚠️ {error}
            </div>
          )}

          <div className="form-field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="your.email@example.com"
              required
              disabled={loading}
            />
          </div>

          <div className="form-field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
              disabled={loading}
            />
          </div>

          <button type="submit" className="login-button" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div className="test-accounts">
          <p className="test-accounts-title">Test Accounts (Click to fill):</p>
          <div className="test-accounts-grid">
            <button
              type="button"
              onClick={() => quickLogin('manager2@email.com', 'password123')}
              className="test-account-btn"
            >
              Manager Two
            </button>
            <button
              type="button"
              onClick={() => quickLogin('admin1@email.com', 'password123')}
              className="test-account-btn"
            >
              Admin One
            </button>
            <button
              type="button"
              onClick={() => quickLogin('manager1@email.com', 'password123')}
              className="test-account-btn"
            >
              Manager One
            </button>
          </div>
          <p className="test-password-hint">Password for all test accounts: <code>password123</code></p>
        </div>
      </div>
    </div>
  );
}

export default Login;
