const express = require("express");
const router = express.Router();
const pool = require("../db");

router.post("/", async (req, res) => {
  const { nome, email, senha, cargo } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO funcionarios (nome, email, senha, cargo) VALUES ($1, $2, $3, $4) RETURNING *",
      [nome, email, senha, cargo]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM funcionarios ORDER BY id DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
