const express = require("express");
const router = express.Router();
const pool = require("../db");

// Criar funcionário
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

// Listar funcionários
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM funcionarios ORDER BY id DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Atualizar funcionário
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { nome, email, senha, cargo } = req.body;
  try {
    const result = await pool.query(
      "UPDATE funcionarios SET nome = $1, email = $2, senha = $3, cargo = $4 WHERE id = $5 RETURNING *",
      [nome, email, senha, cargo, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Funcionário não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deletar funcionário
router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      "DELETE FROM funcionarios WHERE id = $1 RETURNING *",
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Funcionário não encontrado" });
    }
    res.json({ message: "Funcionário deletado com sucesso" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
