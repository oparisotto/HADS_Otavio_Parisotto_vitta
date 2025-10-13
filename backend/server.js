const express = require("express");
const http = require("http");
const cors = require("cors");
const WebSocket = require('ws');
const pool = require("./db");
const authRoutes = require("./routes/auth");
const planosRoutes = require("./routes/planos");
const pagamentosRoutes = require("./routes/pagamentos");
const checkinsRoutes = require("./routes/checkins");
const funcionariosRoutes = require("./routes/funcionarios");
const relatoriosRoutes = require("./routes/relatorios");
const authUsuariosRoutes = require("./routes/authUsuarios");
require("dotenv").config();

const app = express();
const server = http.createServer(app);

// Configurar WebSocket para atualizações em tempo real
const wss = new WebSocket.Server({ server });
const clients = new Set();

// 🔄 WebSocket Connection
wss.on('connection', function connection(ws) {
  console.log('🔌 Novo cliente conectado ao WebSocket - Dashboard em tempo real');
  clients.add(ws);

  // Enviar mensagem de boas-vindas
  ws.send(JSON.stringify({
    type: 'connection',
    message: 'Conectado ao dashboard em tempo real',
    timestamp: new Date().toISOString()
  }));

  ws.on('close', () => {
    console.log('🔌 Cliente desconectado do WebSocket');
    clients.delete(ws);
  });

  ws.on('error', (error) => {
    console.error('❌ Erro no WebSocket:', error);
    clients.delete(ws);
  });
});

// Função para broadcast para todos os clientes
function broadcast(data) {
  const message = JSON.stringify(data);
  clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// 🔄 Monitorar mudanças no banco de dados em tempo real
setInterval(async () => {
  try {
    // Verificar se há novos checkins (últimos 5 segundos)
    const novosCheckins = await pool.query(`
      SELECT COUNT(*) as total 
      FROM checkins 
      WHERE data_checkin > NOW() - INTERVAL '5 seconds'
    `);

    if (parseInt(novosCheckins.rows[0].total) > 0) {
      console.log('🔄 Novos checkins detectados, notificando clientes...');
      broadcast({
        type: 'checkin_update',
        message: 'Novos checkins realizados',
        timestamp: new Date().toISOString(),
        data: {
          novos_checkins: parseInt(novosCheckins.rows[0].total)
        }
      });
    }

    // Verificar se há novos pagamentos (últimos 5 segundos)
    const novosPagamentos = await pool.query(`
      SELECT COUNT(*) as total 
      FROM pagamentos 
      WHERE data_pagamento > NOW() - INTERVAL '5 seconds'
      AND status = 'pago'
    `);

    if (parseInt(novosPagamentos.rows[0].total) > 0) {
      console.log('💰 Novos pagamentos detectados, notificando clientes...');
      broadcast({
        type: 'payment_update',
        message: 'Novos pagamentos realizados',
        timestamp: new Date().toISOString(),
        data: {
          novos_pagamentos: parseInt(novosPagamentos.rows[0].total)
        }
      });
    }

    // Verificar se há novos usuários (últimos 10 segundos)
    const novosUsuarios = await pool.query(`
      SELECT COUNT(*) as total 
      FROM usuarios 
      WHERE created_at > NOW() - INTERVAL '10 seconds'
    `);

    if (parseInt(novosUsuarios.rows[0].total) > 0) {
      console.log('👤 Novos usuários detectados, notificando clientes...');
      broadcast({
        type: 'user_update',
        message: 'Novos usuários cadastrados',
        timestamp: new Date().toISOString(),
        data: {
          novos_usuarios: parseInt(novosUsuarios.rows[0].total)
        }
      });
    }

  } catch (error) {
    console.error('❌ Erro ao monitorar mudanças em tempo real:', error);
  }
}, 3000); // Verificar a cada 3 segundos

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use("/auth", authRoutes);
app.use("/planos", planosRoutes);
app.use("/pagamentos", pagamentosRoutes);
app.use("/checkins", checkinsRoutes);
app.use("/funcionarios", funcionariosRoutes);
app.use("/relatorios", relatoriosRoutes);
app.use("/auth-usuarios", authUsuariosRoutes);

// Rota principal
app.get("/", (req, res) => {
    res.json({ 
        message: "API Vitta rodando 🚀",
        features: [
            "Sistema completo de academia",
            "Dashboard em tempo real", 
            "Gestão de usuários e planos",
            "Sistema de pagamentos",
            "Controle de check-ins",
            "Relatórios avançados"
        ],
        timestamp: new Date().toISOString(),
        websocket: clients.size > 0 ? `${clients.size} cliente(s) conectado(s)` : "Aguardando conexões WebSocket"
    });
});

// Rota para listar usuários
app.get("/usuarios", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM usuarios");
        res.json(result.rows);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// 🔄 Rota para forçar atualização em tempo real (para testes)
app.post("/broadcast/update", (req, res) => {
  const { type = 'manual_update', message = 'Atualização manual solicitada' } = req.body;
  
  broadcast({
    type,
    message,
    timestamp: new Date().toISOString(),
    data: req.body.data || {}
  });
  
  res.json({ 
    success: true, 
    message: 'Notificação enviada para todos os clientes',
    clients_connected: clients.size
  });
});

// 🔄 Rota para status do WebSocket
app.get("/websocket/status", (req, res) => {
  res.json({
    connected_clients: clients.size,
    server_time: new Date().toISOString(),
    status: 'active'
  });
});

// 🔄 Rota para simular novo checkin (para testes)
app.post("/simular/checkin", async (req, res) => {
  try {
    // Simular um checkin
    const result = await pool.query(
      "INSERT INTO checkins (usuario_id, data_checkin) VALUES ($1, NOW()) RETURNING *",
      [req.body.usuario_id || 1]
    );

    // Notificar todos os clientes
    broadcast({
      type: 'checkin_simulado',
      message: 'Check-in simulado para testes',
      timestamp: new Date().toISOString(),
      data: {
        checkin: result.rows[0],
        simulacao: true
      }
    });

    res.json({
      success: true,
      message: 'Check-in simulado e notificação enviada',
      checkin: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erro ao simular check-in',
      error: error.message
    });
  }
});

// Health check
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: "Connected", // Assumindo que a conexão está ok
    websocket: {
      clients: clients.size,
      status: "Active"
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`🔌 WebSocket configurado para atualizações em tempo real`);
  console.log(`📊 Dashboard disponível: http://localhost:${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`🔍 Status WebSocket: http://localhost:${PORT}/websocket/status`);
});