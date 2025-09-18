const express = require("express");
const router = express.Router();
const pool = require("../db");

// 📌 Relatório de usuários: total, ativos e inadimplentes
router.get("/usuarios", async (req, res) => {
  try {
    const total = await pool.query("SELECT COUNT(*) FROM usuarios");
    const ativos = await pool.query(
      "SELECT COUNT(DISTINCT usuario_id) FROM pagamentos WHERE status = 'pago' AND data_vencimento >= NOW()"
    );
    const inadimplentes = await pool.query(
      "SELECT COUNT(DISTINCT usuario_id) FROM pagamentos WHERE data_vencimento < NOW()"
    );

    res.json({
      total_usuarios: parseInt(total.rows[0].count),
      ativos: parseInt(ativos.rows[0].count),
      inadimplentes: parseInt(inadimplentes.rows[0].count),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📌 Relatório de check-ins por período
router.get("/checkins", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    const result = await pool.query(
      "SELECT COUNT(*) FROM checkins WHERE data_checkin BETWEEN $1 AND $2",
      [inicio, fim]
    );
    res.json({
      periodo: { inicio, fim },
      total_checkins: parseInt(result.rows[0].count),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📌 Relatório financeiro: total recebido no período
router.get("/financeiro", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    const result = await pool.query(
      `SELECT SUM(pl.preco) as total_recebido
       FROM pagamentos p
       JOIN planos pl ON pl.id = p.plano_id
       WHERE p.status = 'pago'
       AND p.data_pagamento BETWEEN $1 AND $2`,
      [inicio, fim]
    );
    res.json({
      periodo: { inicio, fim },
      total_recebido: result.rows[0].total_recebido || 0,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
