// src/App.jsx
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Alunos from "./pages/Alunos";
import Funcionarios from "./pages/Funcionarios";
import Planos from "./pages/Planos";
import Sidebar from "./components/Sidebar";

function App() {
  return (
    <Router>
      <div className="flex h-screen">
        {/* Sidebar */}
        <Sidebar />

        {/* Conteúdo */}
        <main className="flex-1 bg-gray-100 p-6">
          <Routes>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/alunos" element={<Alunos />} />
            <Route path="/funcionarios" element={<Funcionarios />} />
            <Route path="/planos" element={<Planos />} />
            {/* Rota padrão */}
            <Route path="*" element={<Dashboard />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
