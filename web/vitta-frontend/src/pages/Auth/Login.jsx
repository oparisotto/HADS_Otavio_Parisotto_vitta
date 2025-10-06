import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";

export default function Login() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErr("");
    setLoading(true);
    try {
      await login(email, senha);
      navigate("/dashboard");
    } catch (error) {
      setErr(error.message || "Erro ao logar");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-6">
      <div className="max-w-4xl w-full bg-white rounded-lg shadow-lg overflow-hidden flex">
        {/* LEFT - Brand/Welcome (padrão similar à sua imagem) */}
        <div className="w-1/3 bg-green-100 p-8 flex flex-col items-start justify-center">
          <h2 className="text-2xl font-bold text-green-700 mb-2">Welcome Back!</h2>
          <p className="text-sm text-gray-700">Faça login para continuar no painel Vitta</p>
        </div>

        {/* RIGHT - Form */}
        <div className="w-2/3 p-8">
          <h3 className="text-2xl font-semibold text-gray-800 mb-6">Sign in</h3>

          {err && <div className="mb-4 text-red-600">{err}</div>}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="mt-1 block w-full rounded border-gray-200 shadow-sm focus:ring-2 focus:ring-green-200 p-2"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Senha</label>
              <input
                type="password"
                value={senha}
                onChange={(e) => setSenha(e.target.value)}
                required
                className="mt-1 block w-full rounded border-gray-200 shadow-sm focus:ring-2 focus:ring-green-200 p-2"
              />
            </div>

            <div className="flex items-center justify-between">
              <button
                type="submit"
                className="px-6 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                disabled={loading}
              >
                {loading ? "Entrando..." : "Entrar"}
              </button>

              <div className="text-sm">
                <Link to="/auth/recover" className="text-green-600 hover:underline">
                  Esqueci minha senha
                </Link>
              </div>
            </div>

            <div className="pt-4 text-sm border-t">
              <span>Não tem conta? </span>
              <Link to="/auth/register" className="text-green-600 hover:underline">
                Cadastre-se
              </Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
