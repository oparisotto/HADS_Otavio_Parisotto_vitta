const express = require("express");
const router = express.Router();
const pool = require("../db");


router.get("/usuarios", async (req, res) => {
  try {
    const total = await pool.query("SELECT COUNT(*) FROM usuarios");

    const ativos = await pool.query(
      `SELECT COUNT(DISTINCT usuario_id) 
       FROM pagamentos 
       WHERE status = 'pago' AND data_vencimento >= NOW()`
    );

    const inadimplentes = await pool.query(
      `SELECT COUNT(DISTINCT usuario_id) 
       FROM pagamentos 
       WHERE data_vencimento < NOW()`
    );

    res.json({
      total_usuarios: parseInt(total.rows[0].count) || 0,
      ativos: parseInt(ativos.rows[0].count) || 0,
      inadimplentes: parseInt(inadimplentes.rows[0].count) || 0,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/checkins", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    const result = await pool.query(
      "SELECT COUNT(*) FROM checkins WHERE data_checkin BETWEEN $1 AND $2",
      [inicio, fim]
    );

    res.json({
      periodo: { inicio, fim },
      total_checkins: parseInt(result.rows[0].count) || 0,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/financeiro", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    const result = await pool.query(
      `SELECT COALESCE(SUM(pl.preco), 0) as total_recebido
       FROM pagamentos p
       JOIN planos pl ON pl.id = p.plano_id
       WHERE p.status = 'pago'
       AND p.data_pagamento BETWEEN $1 AND $2`,
      [inicio, fim]
    );

    res.json({
      periodo: { inicio, fim },
      total_recebido: parseFloat(result.rows[0].total_recebido) || 0,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/planos", async (req, res) => {
  try {
    const total = await pool.query("SELECT COUNT(*) FROM planos");

    res.json({
      total_planos: parseInt(total.rows[0].count) || 0,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
