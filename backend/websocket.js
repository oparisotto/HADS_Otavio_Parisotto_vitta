// websocket.js
const WebSocket = require('ws');
const pool = require('./db');

function setupWebSocket(server) {
  const wss = new WebSocket.Server({ server });

  // Armazenar conexões ativas
  const clients = new Set();

  wss.on('connection', function connection(ws) {
    console.log('🔌 Novo cliente conectado via WebSocket');
    clients.add(ws);

    // Enviar mensagem de boas-vindas
    ws.send(JSON.stringify({
      type: 'connection',
      message: 'Conectado ao dashboard em tempo real'
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

  // 🔄 Monitorar mudanças no banco de dados
  setInterval(async () => {
    try {
      // Verificar se há novos checkins
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
          timestamp: new Date().toISOString()
        });
      }

      // Verificar se há novos pagamentos
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
          timestamp: new Date().toISOString()
        });
      }

    } catch (error) {
      console.error('❌ Erro ao monitorar mudanças:', error);
    }
  }, 3000); // Verificar a cada 3 segundos

  console.log('🚀 WebSocket server configurado para atualizações em tempo real');
  return { broadcast, clients };
}

module.exports = setupWebSocket;