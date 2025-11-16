import { useEffect, useState } from "react";
import axios from "axios";

export default function Alunos() {
  const [usuarios, setUsuarios] = useState([]);
  const [pagamentos, setPagamentos] = useState([]);
  const [planos, setPlanos] = useState([]);
  const [filtro, setFiltro] = useState("todos");
  const [pesquisa, setPesquisa] = useState("");
  const [atualizar, setAtualizar] = useState(0);
  const [loading, setLoading] = useState(true);

  // 🔄 FUNÇÃO PARA RECARREGAR DADOS
  const fetchDados = async () => {
    try {
      setLoading(true);
      console.log("🔄 Buscando dados atualizados...");
      
      const [usuariosRes, pagamentosRes, planosRes] = await Promise.all([
        axios.get("http://localhost:3000/usuarios"),
        axios.get("http://localhost:3000/pagamentos"),
        axios.get("http://localhost:3000/planos"),
      ]);

      setUsuarios(usuariosRes.data);
      setPagamentos(pagamentosRes.data);
      setPlanos(planosRes.data);

      console.log("✅ Dados atualizados carregados");
    } catch (err) {
      console.error("Erro ao carregar dados:", err);
      alert("Erro ao carregar dados dos alunos");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDados();
  }, [atualizar]);

  // 🔄 MONTAR LISTA DE ALUNOS - CORRIGIDO
  const alunos = usuarios.map((usuario) => {
    // PEGAR PLANO ATUAL
    const planoAtual = usuario.plano_atual_id
      ? planos.find((p) => Number(p.id) === Number(usuario.plano_atual_id))
      : null;

    // 🚀 AGORA O STATUS VEM 100% DE "status_plano"
    let status = usuario.status_plano || "sem_plano";

    let statusDisplay = {
      ativo: "Ativo",
      atrasado: "Atrasado",
      inativo: "Inativo",
      cancelado: "Cancelado",
      sem_plano: "Sem plano",
    }[status] || "Sem plano";

    return {
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      status,
      status_display: statusDisplay,
      plano: planoAtual ? planoAtual.nome : "Sem Plano",
      plano_atual_id: usuario.plano_atual_id,
      tem_plano: !!planoAtual,
    };
  });

  // 🔍 APLICAR FILTRO E PESQUISA
  const alunosFiltrados = alunos.filter((aluno) => {
    const correspondePesquisa =
      aluno.nome.toLowerCase().includes(pesquisa.toLowerCase()) ||
      aluno.email.toLowerCase().includes(pesquisa.toLowerCase());

    let correspondeFiltro = true;

    switch (filtro) {
      case "ativo":
        correspondeFiltro = aluno.status === "ativo";
        break;
      case "atrasado":
        correspondeFiltro = aluno.status === "atrasado";
        break;
      case "inativo":
        correspondeFiltro = aluno.status === "inativo";
        break;
      case "cancelado":
        correspondeFiltro = aluno.status === "cancelado";
        break;
      case "sem_plano":
        correspondeFiltro = aluno.status === "sem_plano";
        break;
      default:
        correspondeFiltro = true;
    }

    return correspondeFiltro && correspondePesquisa;
  });

  // 🎨 CORES DOS STATUS
  const corStatus = (status) => {
    switch (status) {
      case "ativo":
        return "text-green-600 bg-green-50 font-medium px-2 py-1 rounded";
      case "atrasado":
        return "text-orange-600 bg-orange-50 font-medium px-2 py-1 rounded";
      case "inativo":
      case "cancelado":
        return "text-red-600 bg-red-50 font-medium px-2 py-1 rounded";
      case "sem_plano":
      default:
        return "text-gray-600 bg-gray-100 font-medium px-2 py-1 rounded";
    }
  };

  // LOADING
  if (loading) {
    return (
      <div className="p-6 bg-gray-50 min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando dados dos alunos...</p>
        </div>
      </div>
    );
  }

  // TELA
  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      {/* CABEÇALHO */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Gestão de Alunos</h1>
          <p className="text-gray-600">Total: {alunos.length} alunos</p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 mt-4 md:mt-0">
          <input
            type="text"
            placeholder="Pesquisar por nome ou email..."
            value={pesquisa}
            onChange={(e) => setPesquisa(e.target.value)}
            className="border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />

          <select
            value={filtro}
            onChange={(e) => setFiltro(e.target.value)}
            className="border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="todos">Todos</option>
            <option value="ativo">Ativo</option>
            <option value="atrasado">Atrasado</option>
            <option value="inativo">Inativo</option>
            <option value="cancelado">Cancelado</option>
            <option value="sem_plano">Sem Plano</option>
          </select>

          <button
            onClick={() => setAtualizar((prev) => prev + 1)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors text-sm font-medium"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
            </svg>
            Atualizar
          </button>
        </div>
      </div>

      {/* TABELA */}
      <div className="bg-white shadow-lg rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-gray-800 text-white">
                <th className="p-4 text-left font-semibold">Aluno</th>
                <th className="p-4 text-left font-semibold">Contato</th>
                <th className="p-4 text-left font-semibold">Status</th>
                <th className="p-4 text-left font-semibold">Plano</th>
              </tr>
            </thead>
            <tbody>
              {alunosFiltrados.length > 0 ? (
                alunosFiltrados.map((aluno) => (
                  <tr key={aluno.id} className="border-b border-gray-200 hover:bg-gray-50">
                    <td className="p-4">
                      <div className="font-medium text-gray-900">{aluno.nome}</div>
                      <div className="text-xs text-gray-500">ID: {aluno.id}</div>
                    </td>
                    
                    <td className="p-4">
                      <a
                        href={`mailto:${aluno.email}`}
                        className="text-blue-600 hover:underline text-sm"
                      >
                        {aluno.email}
                      </a>
                    </td>
                    
                    <td className="p-4">
                      <span className={corStatus(aluno.status)}>
                        {aluno.status_display}
                      </span>
                    </td>
                    
                    <td className="p-4">
                      <div className="text-sm font-medium text-gray-900">
                        {aluno.plano}
                        {aluno.plano_atual_id && (
                          <div className="text-xs text-gray-500 mt-1">
                            ID do plano: {aluno.plano_atual_id}
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="4" className="p-8 text-center text-gray-500">
                    Nenhum aluno encontrado.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
