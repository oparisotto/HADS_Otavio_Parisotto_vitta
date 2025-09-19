// src/components/Sidebar.jsx
import { Home, User, Users, FileText, DollarSign } from "lucide-react";
import { NavLink } from "react-router-dom";

const menuItems = [
  { name: "Dashboard", icon: <Home size={20} />, path: "/dashboard" },
  { name: "Alunos", icon: <Users size={20} />, path: "/alunos" },
  { name: "Funcionários", icon: <User size={20} />, path: "/funcionarios" },
  { name: "Planos", icon: <FileText size={20} />, path: "/planos" },
  { name: "Relatórios", icon: <DollarSign size={20} />, path: "/relatorios" },
];

export default function Sidebar() {
  return (
    <div className="w-64 h-screen bg-gray-900 text-white flex flex-col p-6">
      <h1 className="text-2xl font-bold mb-10">Vitta Gestor</h1>

      <nav className="flex flex-col gap-3">
        {menuItems.map((item) => (
          <NavLink
            key={item.name}
            to={item.path}
            className={({ isActive }) =>
              `flex items-center gap-3 p-3 rounded hover:bg-gray-800 transition-colors ${
                isActive ? "bg-gray-800 font-semibold" : "font-medium"
              }`
            }
          >
            {item.icon}
            <span>{item.name}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
