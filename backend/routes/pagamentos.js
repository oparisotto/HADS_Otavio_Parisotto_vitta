const express = require("express");
const router = express.Router();
const pool = require("../db");

// Criar pagamento
router.post("/", async (req, res) => {
  const { usuario_id, plano_id, status, data_pagamento, data_vencimento } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO pagamentos (usuario_id, plano_id, status, data_pagamento, data_vencimento) VALUES ($1, $2, $3, $4, $5) RETURNING *",
      [usuario_id, plano_id, status || "pago", data_pagamento, data_vencimento]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 🔹 Buscar TODOS os pagamentos
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM pagamentos");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 🔹 Buscar pagamentos por usuário
router.get("/:usuario_id", async (req, res) => {
  const { usuario_id } = req.params;
  try {
    const result = await pool.query(
      "SELECT * FROM pagamentos WHERE usuario_id = $1",
      [usuario_id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Atualizar status do pagamento
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    const result = await pool.query(
      "UPDATE pagamentos SET status = $1 WHERE id = $2 RETURNING *",
      [status, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
