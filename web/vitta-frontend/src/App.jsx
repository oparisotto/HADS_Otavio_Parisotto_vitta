import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import Login from "./pages/Auth/Login";
import Register from "./pages/Auth/Register";
import Recover from "./pages/Auth/Recover";
import Dashboard from "./pages/Dashboard";
import Alunos from "./pages/Alunos";
import Funcionarios from "./pages/Funcionarios";
import Planos from "./pages/Planos";
import PrivateLayout from "./components/PrivateLayout";

export default function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          {/* Auth */}
          <Route path="/auth/login" element={<Login />} />
          <Route path="/auth/register" element={<Register />} />
          <Route path="/auth/recover" element={<Recover />} />
          <Route path="/auth" element={<Navigate to="/auth/login" replace />} />

          {/* Protected */}
          <Route path="/" element={<PrivateLayout />}>
            <Route index element={<Navigate to="dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="alunos" element={<Alunos />} />
            <Route path="funcionarios" element={<Funcionarios />} />
            <Route path="planos" element={<Planos />} />
          </Route>

          <Route path="*" element={<Navigate to="/auth/login" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}
