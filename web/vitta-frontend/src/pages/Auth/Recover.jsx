import { useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { Link } from "react-router-dom";

export default function Recover() {
  const { forgotPassword, resetPassword } = useAuth();
  const [step, setStep] = useState(1);
  const [email, setEmail] = useState("");
  const [codigo, setCodigo] = useState("");
  const [novaSenha, setNovaSenha] = useState("");
  const [msg, setMsg] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSendCode = async (e) => {
    e.preventDefault();
    setErr("");
    setLoading(true);
    try {
      await forgotPassword(email);
      setMsg("Código enviado ao email. Verifique sua caixa de entrada.");
      setStep(2);
    } catch (error) {
      setErr(error.message || "Erro ao enviar código");
    } finally {
      setLoading(false);
    }
  };

  const handleReset = async (e) => {
    e.preventDefault();
    setErr("");
    setLoading(true);
    try {
      await resetPassword({ email, codigo, novaSenha });
      alert("Senha alterada com sucesso. Faça login.");
      setStep(3);
    } catch (error) {
      setErr(error.message || "Erro ao resetar senha");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-6">
      <div className="max-w-2xl w-full bg-white rounded-lg shadow-lg p-8">
        <h2 className="text-2xl font-semibold text-gray-800 mb-4">Recuperar senha</h2>

        {msg && <div className="mb-3 text-green-600">{msg}</div>}
        {err && <div className="mb-3 text-red-600">{err}</div>}

        {step === 1 && (
          <form onSubmit={handleSendCode} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Email cadastrado</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="mt-1 block w-full rounded border-gray-200 shadow-sm focus:ring-2 focus:ring-green-200 p-2"
              />
            </div>
            <div className="flex justify-between items-center">
              <button className="px-6 py-2 bg-green-600 text-white rounded" disabled={loading}>
                {loading ? "Enviando..." : "Enviar código"}
              </button>
              <Link to="/auth/login" className="text-green-600 hover:underline text-sm">
                Voltar ao login
              </Link>
            </div>
          </form>
        )}

        {step === 2 && (
          <form onSubmit={handleReset} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Código</label>
              <input
                type="text"
                value={codigo}
                onChange={(e) => setCodigo(e.target.value)}
                required
                className="mt-1 block w-full rounded border-gray-200 shadow-sm focus:ring-2 focus:ring-green-200 p-2"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Nova senha</label>
              <input
                type="password"
                value={novaSenha}
                onChange={(e) => setNovaSenha(e.target.value)}
                required
                className="mt-1 block w-full rounded border-gray-200 shadow-sm focus:ring-2 focus:ring-green-200 p-2"
              />
            </div>

            <div className="flex justify-between items-center">
              <button className="px-6 py-2 bg-green-600 text-white rounded" disabled={loading}>
                {loading ? "Atualizando..." : "Resetar senha"}
              </button>
              <Link to="/auth/login" className="text-green-600 hover:underline text-sm">
                Voltar ao login
              </Link>
            </div>
          </form>
        )}

        {step === 3 && (
          <div>
            <p className="mb-4">Senha atualizada com sucesso.</p>
            <Link to="/auth/login" className="px-6 py-2 bg-green-600 text-white rounded">
              Ir para login
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
