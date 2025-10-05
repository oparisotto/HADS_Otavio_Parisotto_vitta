import { NavLink, useNavigate } from "react-router-dom";
import { FaHome, FaUser, FaUsers, FaFileInvoiceDollar, FaSignOutAlt } from "react-icons/fa";

export default function Sidebar() {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("usuario");
    navigate("/auth");
  };

  const linkClasses = ({ isActive }) =>
    `flex items-center gap-2 px-4 py-3 rounded hover:bg-gray-200 transition ${
      isActive ? "bg-green-600 text-white" : "text-gray-700"
    }`;

  return (
    <aside className="w-64 bg-white border-r shadow-md flex flex-col">
      <div className="p-6 text-center font-bold text-xl text-green-600 border-b">Vitta</div>

      <nav className="flex-1 mt-4">
        <NavLink to="/dashboard" className={linkClasses}>
          <FaHome /> Dashboard
        </NavLink>
        <NavLink to="/alunos" className={linkClasses}>
          <FaUsers /> Alunos
        </NavLink>
        <NavLink to="/funcionarios" className={linkClasses}>
          <FaUser /> Funcionários
        </NavLink>
        <NavLink to="/planos" className={linkClasses}>
          <FaFileInvoiceDollar /> Planos
        </NavLink>
      </nav>

      <button
        onClick={handleLogout}
        className="flex items-center gap-2 px-4 py-3 m-6 mt-auto text-red-600 rounded hover:bg-red-100 transition"
      >
        <FaSignOutAlt /> Sair
      </button>
    </aside>
  );
}
