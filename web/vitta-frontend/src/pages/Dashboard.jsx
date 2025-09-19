// src/pages/Dashboard.jsx
import { useEffect, useState } from "react";
import axios from "axios";
import {
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer
} from "recharts";

const COLORS = ["#00C49F", "#FF8042", "#0088FE"];

export default function Dashboard() {
  const [usuarios, setUsuarios] = useState(null);
  const [checkins, setCheckins] = useState([]);
  const [financeiro, setFinanceiro] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const hoje = new Date();

        // Usuários
        const usuariosRes = await axios.get("http://localhost:3000/relatorios/usuarios");
        setUsuarios(usuariosRes.data);

        // Check-ins últimos 7 dias
        const seteDiasAtras = new Date();
        seteDiasAtras.setDate(hoje.getDate() - 6); // inclui hoje

        const checkinsRes = await axios.get("http://localhost:3000/relatorios/checkins", {
          params: {
            inicio: seteDiasAtras.toISOString().split("T")[0],
            fim: hoje.toISOString().split("T")[0],
          },
        });

        // Transformar em array contínuo de dias
        let checkinsArray = [];
        if (Array.isArray(checkinsRes.data)) {
          checkinsArray = checkinsRes.data.map(item => ({
            data: item.data,
            total: parseInt(item.total)
          }));
        } else if (typeof checkinsRes.data === "object" && checkinsRes.data !== null) {
          checkinsArray = Object.keys(checkinsRes.data).map(key => ({
            data: key,
            total: parseInt(checkinsRes.data[key])
          }));
        }

        // Preencher dias sem check-in e formatar para dd/mm
        const dias = [];
        const dataInicio = new Date(seteDiasAtras);
        const dataFim = new Date(hoje);
        const checkinsMap = checkinsArray.reduce((acc, item) => {
          acc[item.data] = item.total;
          return acc;
        }, {});

        for (let d = new Date(dataInicio); d <= dataFim; d.setDate(d.getDate() + 1)) {
          const dataStr = d.toISOString().split("T")[0]; // yyyy-mm-dd
          const diaMes = `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}`;
          dias.push({
            data: diaMes,
            total: checkinsMap[dataStr] || 0
          });
        }

        setCheckins(dias);

        // Financeiro últimos 30 dias
        const trintaDiasAtras = new Date();
        trintaDiasAtras.setDate(hoje.getDate() - 29);

        const financeiroRes = await axios.get("http://localhost:3000/relatorios/financeiro", {
          params: {
            inicio: trintaDiasAtras.toISOString().split("T")[0],
            fim: hoje.toISOString().split("T")[0],
          },
        });

        setFinanceiro([
          { name: "Recebido", total: parseFloat(financeiroRes.data.total_recebido || 0) }
        ]);

      } catch (err) {
        console.error("Erro ao carregar dashboard:", err);
      }
    };

    fetchData();
  }, []);

  if (!usuarios) {
    return <p className="text-center mt-10">Carregando dashboard...</p>;
  }

  const usuariosData = [
    { name: "Ativos", value: usuarios.ativos || 0 },
    { name: "Inadimplentes", value: usuarios.inadimplentes || 0 },
  ];

  return (
    <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Card de Usuários */}
      <div className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-bold mb-4">Usuários</h2>
        <p>Total: {usuarios.total_usuarios || 0}</p>
        <ResponsiveContainer width="100%" height={250}>
          <PieChart>
            <Pie
              data={usuariosData}
              dataKey="value"
              cx="50%"
              cy="50%"
              outerRadius={80}
              label
            >
              {usuariosData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index]} />
              ))}
            </Pie>
            <Tooltip />
          </PieChart>
        </ResponsiveContainer>
      </div>

      {/* Card de Check-ins */}
      <div className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-bold mb-4">Check-ins (últimos 7 dias)</h2>
        <ResponsiveContainer width="100%" height={250}>
          <BarChart data={Array.isArray(checkins) ? checkins : []}>
            <XAxis dataKey="data" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="total" fill="#FF8042" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Card Financeiro */}
      <div className="bg-white shadow rounded p-4 md:col-span-2">
        <h2 className="text-lg font-bold mb-4">Financeiro (últimos 30 dias)</h2>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={Array.isArray(financeiro) ? financeiro : []}>
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="total" fill="#00C49F" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
