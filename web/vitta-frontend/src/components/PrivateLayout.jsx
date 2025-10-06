import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import Sidebar from "../components/Sidebar"; // ajuste o caminho conforme sua estrutura

export default function PrivateLayout() {
  const { user } = useAuth();

  // Se não estiver logado, redireciona para login
  if (!user) return <Navigate to="/auth/login" replace />;

  // Se estiver logado mas não for funcionário, bloqueia acesso
  if (user.cargo !== "funcionario" && user.cargo !== "admin") {
    return <Navigate to="/auth/login" replace />;
  }

  // Usuário autorizado, renderiza layout completo com sidebar
  return (
    <div className="flex min-h-screen">
      <Sidebar /> {/* Barra lateral fixa */}
      <main className="flex-1 p-6 bg-gray-100">
        <Outlet /> {/* Espaço para as rotas internas */}
      </main>
    </div>
  );
}
