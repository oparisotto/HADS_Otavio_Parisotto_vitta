const express = require("express");
const router = express.Router();
const pool = require("../db");

// Criar plano
router.post("/", async (req, res) => {
  const { nome, descricao, preco, limite_checkins } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO planos (nome, descricao, preco, limite_checkins) VALUES ($1, $2, $3, $4) RETURNING *",
      [nome, descricao, preco, limite_checkins]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Listar planos
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM planos ORDER BY id DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Atualizar plano
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { nome, descricao, preco, limite_checkins } = req.body;
  try {
    const result = await pool.query(
      "UPDATE planos SET nome=$1, descricao=$2, preco=$3, limite_checkins=$4 WHERE id=$5 RETURNING *",
      [nome, descricao, preco, limite_checkins, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Plano não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deletar plano
router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query("DELETE FROM planos WHERE id=$1 RETURNING *", [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Plano não encontrado" });
    }
    res.json({ message: "Plano deletado com sucesso" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
