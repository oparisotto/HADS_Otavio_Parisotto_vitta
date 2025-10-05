import { useEffect, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";

export default function RelatoriosDashboard() {
  const [filtro, setFiltro] = useState("hoje");
  const [inicio, setInicio] = useState("");
  const [fim, setFim] = useState("");
  const [dados, setDados] = useState({
    usuarios: { total_usuarios: 0, ativos: 0, inadimplentes: 0 },
    planos: { total_planos: 0 },
    checkins: { total_checkins: 0 },
    financeiro: { total_recebido: 0 },
  });
  const [grafico, setGrafico] = useState([]);
  const [carregando, setCarregando] = useState(false);

  // 📅 Calcular intervalo de datas conforme o filtro
  const calcularDatas = (tipo) => {
    const hoje = new Date();
    let inicioData, fimData;

    switch (tipo) {
      case "hoje":
        inicioData = fimData = hoje;
        break;
      case "semana":
        fimData = hoje;
        inicioData = new Date();
        inicioData.setDate(hoje.getDate() - 7);
        break;
      case "mes":
        fimData = hoje;
        inicioData = new Date();
        inicioData.setMonth(hoje.getMonth() - 1);
        break;
      default:
        return;
    }

    setInicio(inicioData.toISOString().split("T")[0]);
    setFim(fimData.toISOString().split("T")[0]);
  };

  // 🔄 Buscar dados do backend
  const carregarDados = async () => {
    if (!inicio || !fim) return;
    setCarregando(true);

    try {
      const [usuarios, planos, checkins, financeiro] = await Promise.all([
        fetch("http://localhost:3000/relatorios/usuarios").then((r) => r.json()),
        fetch("http://localhost:3000/relatorios/planos").then((r) => r.json()),
        fetch(
          `http://localhost:3000/relatorios/checkins?inicio=${inicio}&fim=${fim}`
        ).then((r) => r.json()),
        fetch(
          `http://localhost:3000/relatorios/financeiro?inicio=${inicio}&fim=${fim}`
        ).then((r) => r.json()),
      ]);

      setDados({ usuarios, planos, checkins, financeiro });

      // 🔹 Gerar dados fake de gráfico (exemplo de evolução diária)
      // (Opcionalmente, pode criar uma rota real pra isso)
      const dias = [];
      const dataInicio = new Date(inicio);
      const dataFim = new Date(fim);

      for (
        let d = new Date(dataInicio);
        d <= dataFim;
        d.setDate(d.getDate() + 1)
      ) {
        dias.push({
          dia: d.toISOString().split("T")[0],
          valor: Math.floor(Math.random() * 1000) + 200, // simula receita diária
        });
      }

      setGrafico(dias);
    } catch (err) {
      console.error("Erro ao carregar relatórios:", err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    if (filtro !== "personalizado") calcularDatas(filtro);
  }, [filtro]);

  useEffect(() => {
    if (inicio && fim) carregarDados();
  }, [inicio, fim]);

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6 text-center">
        📈 Relatórios Gerais — Academia Vitta
      </h1>

      {/* Filtros */}
      <div className="flex flex-wrap justify-center gap-3 mb-6">
        {["hoje", "semana", "mes", "personalizado"].map((f) => (
          <button
            key={f}
            className={`px-4 py-2 rounded capitalize ${
              filtro === f
                ? "bg-green-600 text-white"
                : "bg-gray-200 hover:bg-gray-300"
            }`}
            onClick={() => setFiltro(f)}
          >
            {f === "hoje"
              ? "Hoje"
              : f === "semana"
              ? "Semana Passada"
              : f === "mes"
              ? "Mês Passado"
              : "Personalizado"}
          </button>
        ))}
      </div>

      {/* Filtro personalizado */}
      {filtro === "personalizado" && (
        <div className="flex justify-center gap-3 mb-6">
          <input
            type="date"
            value={inicio}
            onChange={(e) => setInicio(e.target.value)}
            className="border p-2 rounded"
          />
          <input
            type="date"
            value={fim}
            onChange={(e) => setFim(e.target.value)}
            className="border p-2 rounded"
          />
          <button
            onClick={carregarDados}
            className="bg-green-600 text-white px-4 py-2 rounded"
          >
            Buscar
          </button>
        </div>
      )}

      {/* Cards de resumo */}
      {carregando ? (
        <p className="text-center text-gray-500 mt-6">Carregando dados...</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600">Total de Usuários</h3>
            <p className="text-3xl font-bold text-green-600">
              {dados.usuarios.total_usuarios}
            </p>
            <p className="text-sm text-gray-500">
              Ativos: {dados.usuarios.ativos} | Inadimplentes:{" "}
              {dados.usuarios.inadimplentes}
            </p>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600">Planos Disponíveis</h3>
            <p className="text-3xl font-bold text-blue-600">
              {dados.planos.total_planos}
            </p>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600">Check-ins no Período</h3>
            <p className="text-3xl font-bold text-orange-600">
              {dados.checkins.total_checkins}
            </p>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600">Faturamento</h3>
            <p className="text-3xl font-bold text-green-600">
              R$ {dados.financeiro.total_recebido.toFixed(2)}
            </p>
            <p className="text-sm text-gray-500">
              {inicio} até {fim}
            </p>
          </div>
        </div>
      )}

      {/* Gráfico */}
      <div className="bg-white border rounded-xl shadow-md p-6">
        <h2 className="text-lg font-semibold text-gray-700 mb-4 text-center">
          Evolução do Faturamento
        </h2>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={grafico}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="dia" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="valor" fill="#16a34a" radius={[5, 5, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
