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
  const [debugInfo, setDebugInfo] = useState("");

  // 📅 CORREÇÃO: Calcular intervalo de datas CORRETAMENTE (considerando fuso horário)
  const calcularDatas = (tipo) => {
    // Usar Date local para evitar problemas de fuso horário
    const hoje = new Date();
    
    // Ajustar para o fuso horário local
    const offset = hoje.getTimezoneOffset();
    const hojeAjustado = new Date(hoje.getTime() - (offset * 60 * 1000));
    
    let inicioData, fimData;

    switch (tipo) {
      case "hoje":
        // Hoje: data atual local
        inicioData = new Date(hojeAjustado);
        fimData = new Date(hojeAjustado);
        break;
      
      case "semana":
        // Últimos 7 dias INCLUINDO hoje
        fimData = new Date(hojeAjustado);
        inicioData = new Date(hojeAjustado);
        inicioData.setDate(hojeAjustado.getDate() - 6);
        break;
      
      case "mes":
        // Últimos 30 dias INCLUINDO hoje
        fimData = new Date(hojeAjustado);
        inicioData = new Date(hojeAjustado);
        inicioData.setDate(hojeAjustado.getDate() - 29);
        break;
      
      default:
        return;
    }

    // Formatar para YYYY-MM-DD (sem problemas de fuso horário)
    const formatarData = (data) => {
      const year = data.getFullYear();
      const month = String(data.getMonth() + 1).padStart(2, '0');
      const day = String(data.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };
    
    const inicioFormatado = formatarData(inicioData);
    const fimFormatado = formatarData(fimData);
    
    setInicio(inicioFormatado);
    setFim(fimFormatado);
    
    console.log(`📅 Filtro: ${tipo}`);
    console.log(`📅 Data local: ${hoje.toLocaleDateString('pt-BR')}`);
    console.log(`📅 Início: ${inicioFormatado} | Fim: ${fimFormatado}`);
    
    setDebugInfo(`Filtro: ${tipo} | Período: ${inicioFormatado} até ${fimFormatado} | Hoje: ${hoje.toLocaleDateString('pt-BR')}`);
  };

  // 🔄 Função para fazer fetch com tratamento de erro
  const fetchComTratamento = async (url) => {
    try {
      console.log(`📡 Fazendo request para: ${url}`);
      const response = await fetch(url);
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText}`);
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
    if (!inicio || !fim) {
      setErro("Datas de início e fim são obrigatórias");
      return;
    }
    
    setCarregando(true);
    setErro("");
    setDebugInfo(prev => `${prev} | 🔄 Buscando dados...`);

    try {
      console.log("🔄 Iniciando carregamento de dados...");
      console.log(`📊 Período: ${inicio} até ${fim}`);

      // Buscar dados básicos (não dependem do período)
      const [usuarios, planos] = await Promise.all([
        fetchComTratamento(`${API_BASE_URL}/relatorios/usuarios`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/planos`)
      ]);

      // Buscar dados do período
      const [checkins, financeiro, graficoData] = await Promise.all([
        fetchComTratamento(`${API_BASE_URL}/relatorios/checkins?inicio=${inicio}&fim=${fim}`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/financeiro?inicio=${inicio}&fim=${fim}`),
        fetchComTratamento(`${API_BASE_URL}/relatorios/grafico-financeiro?inicio=${inicio}&fim=${fim}`)
      ]);

      setDados({ 
        usuarios, 
        planos, 
        checkins, 
        financeiro 
      });
      setGrafico(graficoData);
      
      console.log("📊 Todos os dados carregados com sucesso!");
      console.log("👤 Usuários:", usuarios);
      console.log("📋 Planos:", planos);
      console.log("✅ Checkins:", checkins);
      console.log("💰 Financeiro:", financeiro);
      console.log("📈 Gráfico:", graficoData);

      const hoje = new Date().toLocaleDateString('pt-BR');
      setDebugInfo(`✅ Dados carregados | Hoje: ${hoje} | Checkins: ${checkins.total_checkins} | Faturamento: R$ ${financeiro.total_recebido}`);

    } catch (err) {
      console.error("❌ Erro geral ao carregar relatórios:", err);
      setErro(`Erro ao carregar dados: ${err.message}`);
      setDebugInfo(`❌ Erro: ${err.message}`);
    } finally {
      setCarregando(false);
    }
  };

  // Efeito para calcular datas quando o filtro muda
  useEffect(() => {
    if (filtro !== "personalizado") {
      console.log(`🎛️ Alterando filtro para: ${filtro}`);
      calcularDatas(filtro);
    }
  }, [filtro]);

  // Efeito para carregar dados quando as datas mudam
  useEffect(() => {
    if (inicio && fim) {
      console.log(`📅 Datas alteradas: ${inicio} até ${fim}`);
      carregarDados();
    }
  }, [inicio, fim]);

  // Carregar dados iniciais
  useEffect(() => {
    if (!inicio) {
      calcularDatas("hoje");
    }
  }, []);

  // 🔍 Teste de conexão
  const testarConexao = async () => {
    try {
      setErro("");
      setDebugInfo("Testando conexão...");
      
      const response = await fetch(`${API_BASE_URL}/relatorios/health`);
      if (response.ok) {
        const data = await response.json();
        const hoje = new Date().toLocaleDateString('pt-BR');
        setDebugInfo(`✅ Backend OK | Hoje: ${hoje} | ${data.message}`);
        alert("✅ Conexão com o backend está funcionando!");
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      setDebugInfo(`❌ Falha na conexão: ${error.message}`);
      alert(`❌ Não foi possível conectar ao backend: ${error.message}`);
    }
  };

  // 🔍 Verificar dados existentes no banco
  const verificarDadosBanco = async () => {
    try {
      setDebugInfo("Verificando dados no banco...");
      const data = await fetchComTratamento(`${API_BASE_URL}/relatorios/debug-data`);
      const hoje = new Date().toLocaleDateString('pt-BR');
      setDebugInfo(`📊 Banco | Hoje: ${hoje} | ${data.total_usuarios} usuários, ${data.total_planos} planos, ${data.pagamentos_pagos} pagamentos, ${data.checkins_hoje} checkins hoje`);
      alert(`Dados no banco (Hoje: ${hoje}):\n- ${data.total_usuarios} usuários\n- ${data.total_planos} planos\n- ${data.pagamentos_pagos} pagamentos\n- ${data.checkins_hoje} checkins hoje`);
    } catch (error) {
      setDebugInfo(`❌ Erro ao verificar banco: ${error.message}`);
    }
  };

  // 🔍 Verificar data atual do sistema
  const verificarDataSistema = () => {
    const agora = new Date();
    const dataLocal = agora.toLocaleDateString('pt-BR');
    const dataISO = agora.toISOString().split('T')[0];
    const offset = agora.getTimezoneOffset();
    
    console.log('📅 Debug data sistema:');
    console.log('📍 Data local:', dataLocal);
    console.log('🌐 Data ISO:', dataISO);
    console.log('⏰ Fuso horário (minutos):', offset);
    console.log('🕒 Hora atual:', agora.toLocaleTimeString('pt-BR'));
    
    setDebugInfo(`📅 Sistema: ${dataLocal} | ISO: ${dataISO} | Fuso: ${offset}min`);
    alert(`Data do sistema:\n📍 Local: ${dataLocal}\n🌐 ISO: ${dataISO}\n⏰ Hora: ${agora.toLocaleTimeString('pt-BR')}\n🕒 Fuso: ${offset} minutos`);
  };

  // 🔄 Função para forçar atualização dos dados
  const recarregarDados = () => {
    if (inicio && fim) {
      carregarDados();
    }
  };

  // Formatar data para exibição
  const formatarDataExibicao = (data) => {
    return new Date(data + 'T00:00:00').toLocaleDateString('pt-BR');
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6 text-center">
        📈 Relatórios Gerais — Academia Vitta
      </h1>

      {/* Informações de debug */}
      <div className="mb-4 p-3 bg-gray-100 rounded text-sm">
        <div className="flex justify-between items-center">
          <span className="text-gray-700 font-mono text-xs">{debugInfo}</span>
          <div className="flex gap-2">
            <button
              onClick={verificarDataSistema}
              className="bg-gray-500 text-white px-3 py-1 rounded hover:bg-gray-600 text-xs"
              title="Ver data do sistema"
            >
              📅 Data
            </button>
            <button
              onClick={testarConexao}
              className="bg-blue-500 text-white px-3 py-1 rounded hover:bg-blue-600 text-xs"
            >
              Testar Conexão
            </button>
            <button
              onClick={verificarDadosBanco}
              className="bg-purple-500 text-white px-3 py-1 rounded hover:bg-purple-600 text-xs"
            >
              Ver Banco
            </button>
            <button
              onClick={recarregarDados}
              className="bg-green-500 text-white px-3 py-1 rounded hover:bg-green-600 text-xs"
              disabled={carregando}
            >
              {carregando ? "⏳" : "🔄"}
            </button>
          </div>
        </div>
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
          <div>
            <label className="block text-sm text-gray-600 mb-1">Data Início</label>
            <input
              type="date"
              value={inicio}
              onChange={(e) => setInicio(e.target.value)}
              className="border p-2 rounded"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-600 mb-1">Data Fim</label>
            <input
              type="date"
              value={fim}
              onChange={(e) => setFim(e.target.value)}
              className="border p-2 rounded"
            />
          </div>
          <div className="flex items-end">
            <button
              onClick={carregarDados}
              className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
              disabled={carregando || !inicio || !fim}
            >
              {carregando ? "Carregando..." : "Buscar"}
            </button>
          </div>
        </div>
      )}

      {/* Informações do período */}
      <div className="text-center mb-6 p-4 bg-blue-50 rounded-lg">
        <h3 className="text-lg font-semibold text-blue-800 mb-2">
          Período Selecionado
        </h3>
        <p className="text-blue-600 text-lg">
          <strong>{formatarDataExibicao(inicio)}</strong> até <strong>{formatarDataExibicao(fim)}</strong>
        </p>
        <p className="text-sm text-blue-500 mt-1">
          Filtro: <strong>{filtro}</strong> | {carregando ? "🔄 Carregando..." : "✅ Pronto"}
        </p>
        <p className="text-xs text-blue-400 mt-1">
          Data de hoje: <strong>{new Date().toLocaleDateString('pt-BR')}</strong>
        </p>
      </div>

      {/* Cards de resumo */}
      {carregando ? (
        <div className="text-center text-gray-500 mt-6 p-8">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-green-600 mb-2"></div>
          <p>Carregando dados...</p>
          <p className="text-sm mt-2">Período: {formatarDataExibicao(inicio)} até {formatarDataExibicao(fim)}</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600 font-semibold">Total de Usuários</h3>
            <p className="text-3xl font-bold text-green-600 my-2">
              {dados.usuarios.total_usuarios}
            </p>
            <div className="text-xs text-gray-500 space-y-1">
              <div className="flex justify-between">
                <span>✅ Ativos:</span>
                <span className="font-medium">{dados.usuarios.ativos}</span>
              </div>
              <div className="flex justify-between">
                <span>❌ Inadimplentes:</span>
                <span className="font-medium">{dados.usuarios.inadimplentes}</span>
              </div>
            </div>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600 font-semibold">Planos Disponíveis</h3>
            <p className="text-3xl font-bold text-blue-600 my-2">
              {dados.planos.total_planos}
            </p>
            <p className="text-xs text-gray-500">Cadastrados no sistema</p>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600 font-semibold">Check-ins</h3>
            <p className="text-3xl font-bold text-orange-600 my-2">
              {dados.checkins.total_checkins}
            </p>
            <p className="text-xs text-gray-500">
              No período selecionado
            </p>
            <p className="text-xs text-gray-400 mt-1">
              {formatarDataExibicao(inicio)} - {formatarDataExibicao(fim)}
            </p>
          </div>

          <div className="bg-white border rounded-xl shadow-md p-5 text-center">
            <h3 className="text-gray-600 font-semibold">Faturamento</h3>
            <p className="text-3xl font-bold text-green-600 my-2">
              R$ {dados.financeiro.total_recebido.toFixed(2)}
            </p>
            <p className="text-xs text-gray-500">
              Recebido no período
            </p>
            <p className="text-xs text-gray-400 mt-1">
              {formatarDataExibicao(inicio)} - {formatarDataExibicao(fim)}
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
          <p className="text-sm text-gray-500 text-center mb-4">
            Período: {formatarDataExibicao(inicio)} até {formatarDataExibicao(fim)}
          </p>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={grafico}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis 
                dataKey="dia" 
                tickFormatter={(value) => new Date(value + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' })}
              />
              <YAxis />
              <Tooltip 
                formatter={(value) => [`R$ ${parseFloat(value).toFixed(2)}`, 'Faturamento']}
                labelFormatter={(label) => `Data: ${new Date(label + 'T00:00:00').toLocaleDateString('pt-BR')}`}
              />
              <Bar dataKey="valor" fill="#16a34a" radius={[5, 5, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Mensagem quando não há dados no gráfico */}
      {!carregando && grafico.length === 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
          <p className="text-yellow-700">
            📊 Nenhum dado de faturamento encontrado para o período selecionado.
          </p>
          <p className="text-sm text-yellow-600 mt-1">
            Tente selecionar um período diferente ou verifique se há pagamentos registrados.
          </p>
        </div>
      )}
    </div>
  );
}