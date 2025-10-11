const express = require("express");
const router = express.Router();
const pool = require("../db");

// 🔹 RELATÓRIO DE USUÁRIOS
router.get("/usuarios", async (req, res) => {
  try {
    // Total de usuários
    const totalUsuarios = await pool.query("SELECT COUNT(*) FROM usuarios");
    
    // Usuários com pagamento ativo (último pagamento pago e não vencido)
    const usuariosAtivos = await pool.query(`
      SELECT COUNT(DISTINCT u.id) 
      FROM usuarios u
      INNER JOIN pagamentos p ON u.id = p.usuario_id 
      WHERE p.status = 'pago' 
      AND p.data_vencimento >= CURRENT_DATE
    `);
    
    // Usuários inadimplentes (pagamento vencido ou sem pagamento)
    const usuariosInadimplentes = await pool.query(`
      SELECT COUNT(DISTINCT u.id) 
      FROM usuarios u
      LEFT JOIN pagamentos p ON u.id = p.usuario_id 
      WHERE (p.status IS NULL OR p.status != 'pago' OR p.data_vencimento < CURRENT_DATE)
    `);

    res.json({
      total_usuarios: parseInt(totalUsuarios.rows[0].count),
      ativos: parseInt(usuariosAtivos.rows[0].count),
      inadimplentes: parseInt(usuariosInadimplentes.rows[0].count),
    });
  } catch (err) {
    console.error("Erro ao buscar relatório de usuários:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 RELATÓRIO DE PLANOS
router.get("/planos", async (req, res) => {
  try {
    const result = await pool.query("SELECT COUNT(*) FROM planos");
    res.json({
      total_planos: parseInt(result.rows[0].count),
    });
  } catch (err) {
    console.error("Erro ao buscar relatório de planos:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 RELATÓRIO DE CHECKINS - CORRIGIDO
router.get("/checkins", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`📊 Buscando checkins de ${inicio} até ${fim}`);

    // CORREÇÃO: Converter para DATE para ignorar hora/timezone
    const result = await pool.query(
      `SELECT COUNT(*) FROM checkins 
       WHERE DATE(data_checkin) BETWEEN $1 AND $2`,
      [inicio, fim]
    );

    const total = parseInt(result.rows[0].count);
    console.log(`✅ Checkins encontrados: ${total}`);

    res.json({
      total_checkins: total,
    });
  } catch (err) {
    console.error("Erro ao buscar relatório de checkins:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 RELATÓRIO FINANCEIRO - CORRIGIDO
router.get("/financeiro", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`💰 Buscando financeiro de ${inicio} até ${fim}`);

    // CORREÇÃO: Converter para DATE
    const result = await pool.query(
      `SELECT COALESCE(SUM(pg.preco), 0) as total_recebido
       FROM pagamentos p
       INNER JOIN planos pg ON p.plano_id = pg.id
       WHERE p.status = 'pago' 
       AND DATE(p.data_pagamento) BETWEEN $1 AND $2`,
      [inicio, fim]
    );

    const total = parseFloat(result.rows[0].total_recebido);
    console.log(`✅ Faturamento encontrado: R$ ${total}`);

    res.json({
      total_recebido: total,
    });
  } catch (err) {
    console.error("Erro ao buscar relatório financeiro:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 DADOS PARA GRÁFICO - EVOLUÇÃO DIÁRIA DE CHECKINS - CORRIGIDO
router.get("/grafico-checkins", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`📈 Gráfico checkins: ${inicio} até ${fim}`);

    // CORREÇÃO: Usar DATE() e agrupar por data sem hora
    const result = await pool.query(
      `SELECT 
        DATE(data_checkin) AS dia,
        COUNT(*) AS valor
       FROM checkins 
       WHERE DATE(data_checkin) BETWEEN $1 AND $2
       GROUP BY DATE(data_checkin)
       ORDER BY DATE(data_checkin) ASC`,
      [inicio, fim]
    );

    console.log(`📊 Dados checkins gráfico: ${result.rows.length} dias`);

    // Preenche dias sem checkins com valor 0
    const checkinsExistentes = result.rows.reduce((acc, item) => {
      acc[item.dia.toISOString().split('T')[0]] = parseInt(item.valor);
      return acc;
    }, {});

    const dias = [];
    const dataInicio = new Date(inicio);
    const dataFim = new Date(fim);

    for (let d = new Date(dataInicio); d <= dataFim; d.setDate(d.getDate() + 1)) {
      const dataStr = d.toISOString().split("T")[0];
      dias.push({
        dia: dataStr,
        valor: checkinsExistentes[dataStr] || 0
      });
    }

    res.json(dias);
  } catch (err) {
    console.error("Erro ao buscar dados do gráfico:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 DADOS PARA GRÁFICO - EVOLUÇÃO DIÁRIA DE FATURAMENTO - CORRIGIDO
router.get("/grafico-financeiro", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`📈 Gráfico financeiro: ${inicio} até ${fim}`);

    // CORREÇÃO: Usar DATE() e agrupar por data sem hora
    const result = await pool.query(
      `SELECT 
        DATE(p.data_pagamento) AS dia,
        COALESCE(SUM(pl.preco), 0) AS valor
       FROM pagamentos p
       INNER JOIN planos pl ON p.plano_id = pl.id
       WHERE p.status = 'pago' 
       AND DATE(p.data_pagamento) BETWEEN $1 AND $2
       GROUP BY DATE(p.data_pagamento)
       ORDER BY DATE(p.data_pagamento) ASC`,
      [inicio, fim]
    );

    console.log(`📊 Dados financeiro gráfico: ${result.rows.length} dias`);

    // Preenche dias sem pagamentos com valor 0
    const pagamentosExistentes = result.rows.reduce((acc, item) => {
      acc[item.dia.toISOString().split('T')[0]] = parseFloat(item.valor);
      return acc;
    }, {});

    const dias = [];
    const dataInicio = new Date(inicio);
    const dataFim = new Date(fim);

    for (let d = new Date(dataInicio); d <= dataFim; d.setDate(d.getDate() + 1)) {
      const dataStr = d.toISOString().split("T")[0];
      dias.push({
        dia: dataStr,
        valor: pagamentosExistentes[dataStr] || 0
      });
    }

    res.json(dias);
  } catch (err) {
    console.error("Erro ao buscar dados financeiros do gráfico:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 ROTA DE DEBUG - Para testar os checkins
router.get("/debug-checkins", async (req, res) => {
  const { data } = req.query;
  const dataConsulta = data || new Date().toISOString().split('T')[0];
  
  try {
    console.log(`🔍 Debug checkins na data: ${dataConsulta}`);
    
    // Todos os checkins
    const todosCheckins = await pool.query(
      "SELECT id, usuario_id, data_checkin FROM checkins ORDER BY data_checkin DESC LIMIT 10"
    );

    // Checkins na data específica
    const checkinsHoje = await pool.query(
      "SELECT id, usuario_id, data_checkin FROM checkins WHERE DATE(data_checkin) = $1",
      [dataConsulta]
    );

    // Teste com BETWEEN (como estava antes)
    const checkinsBetween = await pool.query(
      "SELECT COUNT(*) as total FROM checkins WHERE data_checkin BETWEEN $1 AND $2",
      [`${dataConsulta} 00:00:00`, `${dataConsulta} 23:59:59`]
    );

    res.json({
      data_consulta: dataConsulta,
      total_checkins_geral: todosCheckins.rows.length,
      checkins_recentes: todosCheckins.rows,
      total_checkins_na_data: checkinsHoje.rows.length,
      checkins_na_data: checkinsHoje.rows,
      total_com_between: parseInt(checkinsBetween.rows[0].total),
      query_usada: "DATE(data_checkin) = $1"
    });
  } catch (err) {
    console.error("Erro no debug:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;