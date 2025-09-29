import { useEffect, useState } from "react";
import { FaTrash, FaEdit } from "react-icons/fa";

export default function Funcionarios() {
  const [funcionarios, setFuncionarios] = useState([]);
  const [novoFuncionario, setNovoFuncionario] = useState({
    nome: "",
    email: "",
    cargo: "",
    senha: "",
  });
  const [editandoId, setEditandoId] = useState(null);
  const [editandoDados, setEditandoDados] = useState({
    nome: "",
    email: "",
    cargo: "",
    senha: "",
  });

  // Buscar funcionários
  useEffect(() => {
    fetch("http://localhost:3000/funcionarios")
      .then((res) => res.json())
      .then((data) => setFuncionarios(data))
      .catch((err) => console.error("Erro ao carregar funcionários:", err));
  }, []);

  // Adicionar funcionário
  const adicionarFuncionario = async () => {
    const { nome, email, cargo, senha } = novoFuncionario;
    if (!nome || !email || !cargo || !senha) {
      alert("Preencha todos os campos!");
      return;
    }

    try {
      const res = await fetch("http://localhost:3000/funcionarios", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(novoFuncionario),
      });

      if (!res.ok) throw new Error("Erro ao adicionar funcionário");
      const data = await res.json();
      setFuncionarios([data, ...funcionarios]);
      setNovoFuncionario({ nome: "", email: "", cargo: "", senha: "" });
    } catch (err) {
      console.error(err);
      alert("Erro ao adicionar funcionário, veja o console.");
    }
  };

  // Deletar funcionário
  const deletarFuncionario = async (id) => {
    try {
      const res = await fetch(`http://localhost:3000/funcionarios/${id}`, {
        method: "DELETE",
      });

      if (!res.ok) throw new Error("Erro ao deletar funcionário");
      setFuncionarios(funcionarios.filter((f) => f.id !== id));
    } catch (err) {
      console.error(err);
      alert("Erro ao deletar funcionário, veja o console.");
    }
  };

  // Entrar no modo edição
  const iniciarEdicao = (func) => {
    setEditandoId(func.id);
    setEditandoDados({
      nome: func.nome,
      email: func.email,
      cargo: func.cargo,
      senha: func.senha || "",
    });
  };

  // Salvar edição
  const salvarEdicao = async (id) => {
    const { nome, email, cargo, senha } = editandoDados;
    if (!nome || !email || !cargo || !senha) {
      alert("Preencha todos os campos!");
      return;
    }

    try {
      const res = await fetch(`http://localhost:3000/funcionarios/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(editandoDados),
      });

      if (!res.ok) throw new Error("Erro ao editar funcionário");
      const data = await res.json();
      setFuncionarios(funcionarios.map((f) => (f.id === id ? data : f)));
      setEditandoId(null);
      setEditandoDados({ nome: "", email: "", cargo: "", senha: "" });
    } catch (err) {
      console.error(err);
      alert("Erro ao editar funcionário, veja o console.");
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Funcionários</h1>

      {/* Formulário para adicionar */}
      <div className="grid grid-cols-4 gap-4 mb-4">
        <input
          type="text"
          placeholder="Nome"
          value={novoFuncionario.nome}
          onChange={(e) =>
            setNovoFuncionario({ ...novoFuncionario, nome: e.target.value })
          }
          className="border p-2 rounded"
        />
        <input
          type="email"
          placeholder="Email"
          value={novoFuncionario.email}
          onChange={(e) =>
            setNovoFuncionario({ ...novoFuncionario, email: e.target.value })
          }
          className="border p-2 rounded"
        />
        <input
          type="text"
          placeholder="Cargo"
          value={novoFuncionario.cargo}
          onChange={(e) =>
            setNovoFuncionario({ ...novoFuncionario, cargo: e.target.value })
          }
          className="border p-2 rounded"
        />
        <input
          type="password"
          placeholder="Senha"
          value={novoFuncionario.senha}
          onChange={(e) =>
            setNovoFuncionario({ ...novoFuncionario, senha: e.target.value })
          }
          className="border p-2 rounded"
        />
      </div>
      <button
        onClick={adicionarFuncionario}
        className="bg-blue-600 text-white px-4 py-2 rounded mb-4"
      >
        Adicionar Funcionário
      </button>

      {/* Tabela */}
      <table className="w-full mt-6 border">
        <thead>
          <tr className="bg-gray-200">
            <th className="p-2 border">ID</th>
            <th className="p-2 border">Nome</th>
            <th className="p-2 border">Email</th>
            <th className="p-2 border">Cargo</th>
            <th className="p-2 border">Senha</th>
            <th className="p-2 border text-right">Ações</th>
          </tr>
        </thead>
        <tbody>
          {funcionarios.map((f) => (
            <tr key={f.id}>
              <td className="p-2 border">{f.id}</td>
              <td className="p-2 border">
                {editandoId === f.id ? (
                  <input
                    type="text"
                    value={editandoDados.nome}
                    onChange={(e) =>
                      setEditandoDados({ ...editandoDados, nome: e.target.value })
                    }
                    className="border p-1 rounded"
                  />
                ) : (
                  f.nome
                )}
              </td>
              <td className="p-2 border">
                {editandoId === f.id ? (
                  <input
                    type="email"
                    value={editandoDados.email}
                    onChange={(e) =>
                      setEditandoDados({ ...editandoDados, email: e.target.value })
                    }
                    className="border p-1 rounded"
                  />
                ) : (
                  f.email
                )}
              </td>
              <td className="p-2 border">
                {editandoId === f.id ? (
                  <input
                    type="text"
                    value={editandoDados.cargo}
                    onChange={(e) =>
                      setEditandoDados({ ...editandoDados, cargo: e.target.value })
                    }
                    className="border p-1 rounded"
                  />
                ) : (
                  f.cargo
                )}
              </td>
              <td className="p-2 border">
                {editandoId === f.id ? (
                  <input
                    type="password"
                    value={editandoDados.senha}
                    onChange={(e) =>
                      setEditandoDados({ ...editandoDados, senha: e.target.value })
                    }
                    className="border p-1 rounded"
                  />
                ) : (
                  "******"
                )}
              </td>
              <td className="p-2 border text-left">
                {editandoId === f.id ? (
                  <button
                    onClick={() => salvarEdicao(f.id)}
                    className="bg-green-600 text-white px-3 py-1 rounded flex items-center gap-1"
                  >
                    <FaEdit /> Salvar
                  </button>
                ) : (
                  <>
                    <button
                      onClick={() => iniciarEdicao(f)}
                      className= "bg-blue-600 text-white px-3 py-1 rounded flex items-center gap-1"
                    >
                      <FaEdit /> Editar
                    </button>
                    <button
                      onClick={() => deletarFuncionario(f.id)}
                      className="bg-red-600 text-white px-3 py-1 rounded flex items-center gap-1"
                    >
                      <FaTrash /> Deletar
                    </button>
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
