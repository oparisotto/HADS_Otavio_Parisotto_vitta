import { useEffect, useState } from "react";
import axios from "axios";

export default function Alunos() {
  const [usuarios, setUsuarios] = useState([]);
  const [pagamentos, setPagamentos] = useState([]);
  const [planos, setPlanos] = useState([]);
  const [filtro, setFiltro] = useState("todos");
  const [pesquisa, setPesquisa] = useState("");

  useEffect(() => {
    const fetchDados = async () => {
      try {
        const [usuariosRes, pagamentosRes, planosRes] = await Promise.all([
          axios.get("http://localhost:3000/usuarios"),
          axios.get("http://localhost:3000/pagamentos"),
          axios.get("http://localhost:3000/planos"),
        ]);

        setUsuarios(usuariosRes.data);
        setPagamentos(pagamentosRes.data);
        setPlanos(planosRes.data);

        // Debug para conferir os dados que chegam
        console.log("Usuários:", usuariosRes.data);
        console.log("Pagamentos:", pagamentosRes.data);
        console.log("Planos:", planosRes.data);
      } catch (err) {
        console.error("Erro ao carregar dados:", err);
      }
    };

    fetchDados();
  }, []);

  // Montar lista final de alunos
  const alunos = usuarios.map((usuario) => {
    const pagamento = pagamentos.find(
      (p) => Number(p.usuario_id) === Number(usuario.id)
    );

    const plano = pagamento
      ? planos.find((pl) => Number(pl.id) === Number(pagamento.plano_id))
      : null;

    return {
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      status: pagamento ? pagamento.status.toLowerCase() : "sem plano",
      plano: plano ? plano.nome : "-",
    };
  });

  // Aplicar filtro e pesquisa
  const alunosFiltrados = alunos.filter((aluno) => {
    const correspondeFiltro = filtro === "todos" || aluno.status === filtro;
    const correspondePesquisa = aluno.nome
      .toLowerCase()
      .includes(pesquisa.toLowerCase());
    return correspondeFiltro && correspondePesquisa;
  });

  // Retornar cor para status
  const corStatus = (status) => {
    switch (status) {
      case "pago":
        return "text-green-600 font-medium";
      case "pendente":
        return "text-yellow-600 font-medium";
      case "atrasado":
        return "text-red-600 font-medium";
      case "sem plano":
        return "text-gray-500 font-medium";
      default:
        return "text-gray-500 font-medium";
    }
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4">
        <h1 className="text-2xl font-bold mb-2 md:mb-0">Alunos</h1>

        <div className="flex gap-2">
          <input
            type="text"
            placeholder="Pesquisar por nome..."
            value={pesquisa}
            onChange={(e) => setPesquisa(e.target.value)}
            className="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
          <select
            value={filtro}
            onChange={(e) => setFiltro(e.target.value)}
            className="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="todos">Todos</option>
            <option value="pago">Pago</option>
            <option value="pendente">Pendente</option>
            <option value="atrasado">Atrasado</option>
            <option value="sem plano">Sem plano</option>
          </select>
        </div>
      </div>

      <div className="bg-white shadow rounded-lg overflow-x-auto">
        <table className="w-full border-collapse">
          <thead>
            <tr className="bg-gray-100 text-left">
              <th className="p-3 border-b">Nome</th>
              <th className="p-3 border-b">Email</th>
              <th className="p-3 border-b">Status</th>
              <th className="p-3 border-b">Plano</th>
            </tr>
          </thead>
          <tbody>
            {alunosFiltrados.length > 0 ? (
              alunosFiltrados.map((aluno) => (
                <tr key={aluno.id} className="hover:bg-gray-50">
                  <td className="p-3 border-b">{aluno.nome}</td>
                  <td className="p-3 border-b">
                    <a
                      href={`mailto:${aluno.email}`}
                      className="text-indigo-600 hover:underline"
                    >
                      {aluno.email}
                    </a>
                  </td>
                  <td className={`p-3 border-b ${corStatus(aluno.status)}`}>
                    {aluno.status.charAt(0).toUpperCase() +
                      aluno.status.slice(1)}
                  </td>
                  <td className="p-3 border-b">{aluno.plano}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="4" className="p-3 text-center text-gray-500">
                  Nenhum aluno encontrado.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
