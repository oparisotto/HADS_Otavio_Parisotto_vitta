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

const API_BASE_URL = "http://localhost:3000";

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
  const [erro, setErro] = useState("");

  // 📅 CORREÇÃO: Calcular intervalo de datas CORRETAMENTE
  const calcularDatas = (tipo) => {
    const hoje = new Date();
    let inicioData, fimData;

    switch (tipo) {
      case "hoje":
        // Hoje: do início do dia atual até o fim do dia atual
        inicioData = new Date(hoje);
        fimData = new Date(hoje);
        break;
      
      case "semana":
        // Últimos 7 dias INCLUINDO hoje
        fimData = new Date(hoje);
        inicioData = new Date(hoje);
        inicioData.setDate(hoje.getDate() - 6); // 7 dias incluindo hoje
        break;
      
      case "mes":
        // Últimos 30 dias INCLUINDO hoje
        fimData = new Date(hoje);
        inicioData = new Date(hoje);
        inicioData.setDate(hoje.getDate() - 29); // 30 dias incluindo hoje
        break;
      
      default:
        return;
    }

    // Garantir que as datas estão no formato correto
    setInicio(inicioData.toISOString().split("T")[0]);
    setFim(fimData.toISOString().split("T")[0]);
    
    console.log(`📅 Filtro: ${tipo} | Início: ${inicioData.toISOString().split("T")[0]} | Fim: ${fimData.toISOString().split("T")[0]}`);
  };

  // 🔄 Função para fazer fetch com tratamento de erro
  const fetchComTratamento = async (url) => {
    try {
      console.log(`📡 Fazendo request para: ${url}`);
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log(`✅ Response de ${url}:`, data);
      return data;
    } catch (error) {
      console.error(`❌ Erro ao buscar ${url}:`, error);
      throw error;
    }
  };

  // 🔄 Buscar dados do backend
  const carregarDados = async () => {
    if (!inicio || !fim) return;
    
    setCarregando(true);
    setErro("");

    try {
      console.log("🔄 Iniciando carregamento de dados...");
      console.log(`📊 Período: ${inicio} até ${fim}`);

      const [usuarios, planos, checkins, financeiro, graficoData] = await Promise.all([
        fetchComTratamento(`${API_BASE_URL}/relatorios/usuarios`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/planos`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/checkins?inicio=${inicio}&fim=${fim}`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/financeiro?inicio=${inicio}&fim=${fim}`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/grafico-financeiro?inicio=${inicio}&fim=${fim}`),
      ]);

      setDados({ usuarios, planos, checkins, financeiro });
      setGrafico(graficoData);
      
      console.log("📊 Todos os dados carregados com sucesso!");
      console.log("📈 Checkins no período:", checkins.total_checkins);
    } catch (err) {
      console.error("❌ Erro geral ao carregar relatórios:", err);
      setErro(`Erro ao conectar com o servidor: ${err.message}. Verifique se o backend está rodando.`);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    if (filtro !== "personalizado") {
      console.log(`🎛️ Alterando filtro para: ${filtro}`);
      calcularDatas(filtro);
    }
  }, [filtro]);

  useEffect(() => {
    if (inicio && fim) {
      console.log(`📅 Período selecionado: ${inicio} até ${fim}`);
      carregarDados();
    }
  }, [inicio, fim]);

  // Teste de conexão simples
  const testarConexao = async () => {
    try {
      setErro("");
      const response = await fetch(`${API_BASE_URL}/relatorios/usuarios`);
      if (response.ok) {
        alert("✅ Conexão com o backend está funcionando!");
      } else {
        alert("❌ Erro na conexão com o backend");
      }
    } catch (error) {
      alert(`❌ Não foi possível conectar ao backend: ${error.message}`);
    }
  };

  // 🔄 Função para forçar atualização dos dados
  const recarregarDados = () => {
    if (inicio && fim) {
      carregarDados();
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6 text-center">
        📈 Relatórios Gerais — Academia Vitta
      </h1>

      {/* Botões de controle */}
      <div className="flex justify-center gap-3 mb-4">
        <button
          onClick={testarConexao}
          className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 text-sm"
        >
          Testar Conexão
        </button>
        <button
          onClick={recarregarDados}
          className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 text-sm"
          disabled={carregando}
        >
          {carregando ? "Atualizando..." : "Atualizar Dados"}
        </button>
      </div>

      {/* Informações do período */}
      <div className="text-center mb-4">
        <p className="text-sm text-gray-600">
          Período selecionado: <strong>{inicio}</strong> até <strong>{fim}</strong>
        </p>
        <p className="text-xs text-gray-500">
          Filtro atual: <strong>{filtro}</strong>
        </p>
      </div>

      {/* Mensagem de erro */}
      {erro && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          <strong>Erro: </strong> {erro}
        </div>
      )}

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
              ? "Últimos 7 Dias"
              : f === "mes"
              ? "Últimos 30 Dias"
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
            className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
            disabled={carregando}
          >
            {carregando ? "Carregando..." : "Buscar"}
          </button>
        </div>
      )}

      {/* Cards de resumo */}
      {carregando ? (
        <div className="text-center text-gray-500 mt-6">
          <p>Carregando dados...</p>
          <p className="text-sm">Verifique o console para detalhes</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600">Total de Usuários</h3>
            <p className="text-3xl font-bold text-green-600">
              {dados.usuarios.total_usuarios}
            </p>
            <p className="text-sm text-gray-500 mt-2">
              ✅ Ativos: {dados.usuarios.ativos} | ❌ Inadimplentes: {dados.usuarios.inadimplentes}
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
            <p className="text-sm text-gray-500 mt-2">
              {inicio} até {fim}
            </p>
            <p className="text-xs text-gray-400 mt-1">
              Filtro: {filtro}
            </p>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600">Faturamento</h3>
            <p className="text-3xl font-bold text-green-600">
              R$ {dados.financeiro.total_recebido.toFixed(2)}
            </p>
            <p className="text-sm text-gray-500 mt-2">
              {inicio} até {fim}
            </p>
          </div>
        </div>
      )}

      {/* Gráfico */}
      {grafico.length > 0 && (
        <div className="bg-white border rounded-xl shadow-md p-6">
          <h2 className="text-lg font-semibold text-gray-700 mb-4 text-center">
            Evolução do Faturamento Diário
          </h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={grafico}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="dia" />
              <YAxis />
              <Tooltip 
                formatter={(value) => [`R$ ${parseFloat(value).toFixed(2)}`, 'Faturamento']}
              />
              <Bar dataKey="valor" fill="#16a34a" radius={[5, 5, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}