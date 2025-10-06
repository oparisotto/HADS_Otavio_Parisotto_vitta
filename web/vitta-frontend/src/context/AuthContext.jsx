import React, { createContext, useContext, useState, useEffect } from "react";

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem("token"));
  const [user, setUser] = useState(() => {
    const raw = localStorage.getItem("usuario");
    return raw ? JSON.parse(raw) : null;
  });
  const API = import.meta.env.VITE_API_URL || "http://localhost:3000";

  useEffect(() => {
    if (token) localStorage.setItem("token", token);
    else localStorage.removeItem("token");
  }, [token]);

  useEffect(() => {
    if (user) localStorage.setItem("usuario", JSON.stringify(user));
    else localStorage.removeItem("usuario");
  }, [user]);

  const login = async (email, senha) => {
    const res = await fetch(`http://localhost:3000/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, senha }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || "Erro ao logar");
    }
    const data = await res.json();
    setToken(data.token);
    setUser(data.funcionario || data.usuario || null);
    return data;
  };

  const register = async ({ nome, email, senha, cargo }) => {
    const res = await fetch(`http://localhost:3000/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nome, email, senha, cargo }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || "Erro ao registrar");
    }
    return await res.json();
  };

  const forgotPassword = async (email) => {
    const res = await fetch(`http://localhost:3000/auth/forgot-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || "Erro ao solicitar código");
    }
    return await res.json();
  };

  const resetPassword = async ({ email, codigo, novaSenha }) => {
    const res = await fetch(`http://localhost:3000/auth/reset-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, codigo, novaSenha }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || "Erro ao resetar senha");
    }
    return await res.json();
  };

  const logout = () => {
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{ token, user, login, register, logout, forgotPassword, resetPassword }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
