import { useEffect, useState } from "react";
import { FaTrash, FaEdit, FaPlus } from "react-icons/fa";

export default function Planos() {
  const [planos, setPlanos] = useState([]);
  const [busca, setBusca] = useState("");
  const [novoPlano, setNovoPlano] = useState({
    nome: "",
    descricao: "",
    preco: "",
    limite_checkins: "",
  });
  const [editandoId, setEditandoId] = useState(null);
  const [mostrarModal, setMostrarModal] = useState(false);
  const [erro, setErro] = useState(""); // <- mensagem de erro

  // Buscar planos no backend
  const carregarPlanos = async () => {
    const res = await fetch("http://localhost:3000/planos");
    const data = await res.json();
    setPlanos(data);
  };

  useEffect(() => {
    carregarPlanos();
  }, []);

  // Criar novo plano
  const adicionarPlano = async () => {
    if (!novoPlano.nome || !novoPlano.descricao || !novoPlano.preco || !novoPlano.limite_checkins) {
      setErro("⚠️ Todos os campos devem ser preenchidos.");
      return;
    }
    setErro(""); // limpa erro se estiver tudo certo

    const res = await fetch("http://localhost:3000/planos", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(novoPlano),
    });
    const data = await res.json();
    setPlanos([data, ...planos]);
    resetarFormulario();
  };

  // Atualizar plano
  const atualizarPlano = async (id) => {
    if (!novoPlano.nome || !novoPlano.descricao || !novoPlano.preco || !novoPlano.limite_checkins) {
      setErro("⚠️ Todos os campos devem ser preenchidos.");
      return;
    }
    setErro("");

    const res = await fetch(`http://localhost:3000/planos/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(novoPlano),
    });
    const data = await res.json();
    setPlanos(planos.map((p) => (p.id === id ? data : p)));
    resetarFormulario();
  };

  // Deletar plano
  const deletarPlano = async (id) => {
    await fetch(`http://localhost:3000/planos/${id}`, { method: "DELETE" });
    setPlanos(planos.filter((p) => p.id !== id));
  };

  // Resetar formulário/modal
  const resetarFormulario = () => {
    setNovoPlano({ nome: "", descricao: "", preco: "", limite_checkins: "" });
    setEditandoId(null);
    setMostrarModal(false);
    setErro("");
  };

  // Filtragem
  const planosFiltrados = planos.filter((p) =>
    p.nome.toLowerCase().includes(busca.toLowerCase())
  );

  return (
    <div className="p-6">
      {/* Cabeçalho */}
      <div className="flex justify-between items-center mb-6">
        <input
          type="text"
          placeholder="Pesquisar plano..."
          value={busca}
          onChange={(e) => setBusca(e.target.value)}
          className="border p-2 rounded w-1/3 shadow-sm"
        />
        <button
          className="bg-green-600 hover:bg-green-700 transition text-white px-4 py-2 rounded flex items-center shadow"
          onClick={() => setMostrarModal(true)}
        >
          <FaPlus className="mr-2" /> Novo Plano
        </button>
      </div>

      {/* Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {planosFiltrados.map((plano) => (
          <div
            key={plano.id}
            className="bg-white border rounded-xl shadow-md p-5 flex flex-col justify-between"
          >
            <div>
              <h3 className="text-xl font-bold text-gray-800 mb-2 text-center">
                {plano.nome}
              </h3>
              <p className="text-gray-600 text-sm mb-3 text-center">
                {plano.descricao}
              </p>
              <p className="text-lg font-semibold text-green-600 text-center">
                R$ {plano.preco}
              </p>
              <p className="text-gray-500 text-center">
                Limite: {plano.limite_checkins} check-ins
              </p>
            </div>

            <div className="flex gap-3 justify-center mt-4">
              <button
                className="bg-blue-500 hover:bg-blue-600 transition text-white px-3 py-2 rounded flex items-center gap-1"
                onClick={() => {
                  setNovoPlano(plano);
                  setEditandoId(plano.id);
                  setMostrarModal(true);
                }}
              >
                <FaEdit /> Editar
              </button>
              <button
                className="bg-red-500 hover:bg-red-600 transition text-white px-3 py-2 rounded flex items-center gap-1"
                onClick={() => deletarPlano(plano.id)}
              >
                <FaTrash /> Deletar
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Modal */}
      {mostrarModal && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-40">
          <div className="bg-white p-6 rounded-xl shadow-lg w-full max-w-lg">
            <h2 className="text-xl font-bold mb-4 text-center text-gray-800">
              {editandoId ? "Editar Plano" : "Cadastrar Novo Plano"}
            </h2>

            {/* Form */}
            <div className="grid grid-cols-1 gap-3">
              <input
                type="text"
                placeholder="Nome do Plano"
                value={novoPlano.nome}
                onChange={(e) =>
                  setNovoPlano({ ...novoPlano, nome: e.target.value })
                }
                className="border p-3 rounded focus:ring focus:ring-green-300 outline-none"
              />
              <textarea
                placeholder="Descrição"
                value={novoPlano.descricao}
                onChange={(e) =>
                  setNovoPlano({ ...novoPlano, descricao: e.target.value })
                }
                className="border p-3 rounded h-24 resize-none focus:ring focus:ring-green-300 outline-none"
              />
              <input
                type="number"
                placeholder="Preço"
                value={novoPlano.preco}
                onChange={(e) =>
                  setNovoPlano({ ...novoPlano, preco: e.target.value })
                }
                className="border p-3 rounded focus:ring focus:ring-green-300 outline-none"
              />
              <input
                type="number"
                placeholder="Limite de Check-ins"
                value={novoPlano.limite_checkins}
                onChange={(e) =>
                  setNovoPlano({
                    ...novoPlano,
                    limite_checkins: e.target.value,
                  })
                }
                className="border p-3 rounded focus:ring focus:ring-green-300 outline-none"
              />
            </div>

            {/* Mensagem de erro */}
            {erro && (
              <p className="text-red-600 text-sm mt-3 text-center">{erro}</p>
            )}

            {/* Botões */}
            <div className="flex justify-end gap-3 mt-6">
              <button
                className="bg-gray-400 hover:bg-gray-500 transition text-white px-4 py-2 rounded"
                onClick={resetarFormulario}
              >
                Cancelar
              </button>
              <button
                className="bg-green-600 hover:bg-green-700 transition text-white px-4 py-2 rounded"
                onClick={() =>
                  editandoId ? atualizarPlano(editandoId) : adicionarPlano()
                }
              >
                {editandoId ? "Salvar Alterações" : "Adicionar Plano"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
