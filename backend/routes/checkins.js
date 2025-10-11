const express = require("express");
const router = express.Router();
const pool = require("../db");

// Rota de check-in (POST)
router.post("/", async (req, res) => {
  const { usuario_id } = req.body;

  try {
    // Verifica pagamento ativo
    const pagamento = await pool.query(
      "SELECT * FROM pagamentos WHERE usuario_id = $1 AND status = 'pago' ORDER BY data_vencimento DESC LIMIT 1",
      [usuario_id]
    );

    if (pagamento.rows.length === 0) {
      return res.status(400).json({ message: "Usuário não possui pagamento ativo." });
    }

    const hoje = new Date();
    const vencimento = new Date(pagamento.rows[0].data_vencimento);

    if (vencimento < hoje) {
      return res.status(400).json({ message: "Pagamento vencido. Usuário bloqueado para check-in." });
    }

    // Insere novo check-in
    const novoCheckin = await pool.query(
      "INSERT INTO checkins (usuario_id) VALUES ($1) RETURNING *",
      [usuario_id]
    );

    res.status(201).json({ message: "Check-in realizado com sucesso!", checkin: novoCheckin.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rota para buscar estatísticas de checkins do usuário
router.get("/stats/:usuario_id", async (req, res) => {
  const { usuario_id } = req.params;
  
  try {
    // Checkins diários (hoje)
    const diarios = await pool.query(
      `SELECT COUNT(*) FROM checkins 
       WHERE usuario_id = $1 
       AND DATE(data_checkin) = CURRENT_DATE`,
      [usuario_id]
    );

    // Checkins semanais (últimos 7 dias)
    const semanais = await pool.query(
      `SELECT COUNT(*) FROM checkins 
       WHERE usuario_id = $1 
       AND data_checkin >= CURRENT_DATE - INTERVAL '7 days'`,
      [usuario_id]
    );

    // Checkins mensais (últimos 30 dias)
    const mensais = await pool.query(
      `SELECT COUNT(*) FROM checkins 
       WHERE usuario_id = $1 
       AND data_checkin >= CURRENT_DATE - INTERVAL '30 days'`,
      [usuario_id]
    );

    res.json({
      diarios: parseInt(diarios.rows[0].count),
      semanais: parseInt(semanais.rows[0].count),
      mensais: parseInt(mensais.rows[0].count),
    });
  } catch (err) {
    console.error('Erro ao buscar estatísticas:', err);
    res.status(500).json({ error: err.message });
  }
});

// Rota GET: check-ins totais por dia com preenchimento de dias sem check-in
router.get("/", async (req, res) => {
  const { inicio, fim } = req.query; // datas opcionais: YYYY-MM-DD

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    // Consulta os check-ins existentes
    const result = await pool.query(
      `
      SELECT 
        TO_CHAR(data_checkin, 'YYYY-MM-DD') AS data,
        COUNT(*) AS total
      FROM checkins
      WHERE data_checkin BETWEEN $1 AND $2
      GROUP BY data_checkin
      ORDER BY data_checkin ASC
      `,
      [inicio, fim]
    );

    const checkinsExistentes = result.rows.reduce((acc, item) => {
      acc[item.data] = parseInt(item.total);
      return acc;
    }, {});

    // Preenche todos os dias do período com 0 caso não haja check-ins
    const dias = [];
    const dataInicio = new Date(inicio);
    const dataFim = new Date(fim);

    for (let d = new Date(dataInicio); d <= dataFim; d.setDate(d.getDate() + 1)) {
      const dataStr = d.toISOString().split("T")[0];
      dias.push({
        data: dataStr,
        total: checkinsExistentes[dataStr] || 0
      });
    }

    res.json(dias); // [{data: '2025-09-12', total: 0}, ...]
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;