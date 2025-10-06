import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";

export default function Register() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const [nome, setNome] = useState("");
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [cargo, setCargo] = useState("funcionario");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErr("");
    setLoading(true);
    try {
      await register({ nome, email, senha, cargo });
      alert("Registrado com sucesso. Faça login.");
      navigate("/auth/login");
    } catch (error) {
      setErr(error.message || "Erro ao registrar");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-6">
      <div className="max-w-4xl w-full bg-white rounded-lg shadow-lg overflow-hidden flex">
        <div className="w-1/3 bg-green-100 p-8 flex flex-col items-start justify-center">
          <h2 className="text-2xl font-bold text-green-700 mb-2">Create Account</h2>
          <p className="text-sm text-gray-700">Registre um funcionário para acessar o painel</p>
        </div>

        <div className="w-2/3 p-8">
          <h3 className="text-2xl font-semibold text-gray-800 mb-6">Sign up</h3>
          {err && <div className="mb-4 text-red-600">{err}</div>}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Nome</label>
              <input
                type="text"
                value={nome}
                onChange={(e) => setNome(e.target.value)}
                required
                className="mt-1 block w-full rounded border-gray-200 shadow-sm focus:ring-2 focus:ring-green-200 p-2"
              />
            </div>

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
                {loading ? "Cadastrando..." : "Cadastrar"}
              </button>

              <div className="text-sm">
                <Link to="/auth/login" className="text-green-600 hover:underline">
                  Já tenho conta
                </Link>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
