const express = require("express");
const router = express.Router();
const pool = require("../db");

router.post("/", async (req, res) =>{
    const { nome, descricao, preco, limite_checkins } = req.body;
    try {
        const result = await pool.query(
            "INSERT INTO planos (nome, descricao, preco, limite_checkins) VALUES ($1, $2, $3, $4) RETURNING *",
            [nome, descricao, preco, limite_checkins]
        );
        res.status(201).json(result.rows[0]);
    } catch(err) {
        res.status(500).json({ error: err.message});
    }
});

router.get("/", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM planos");
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;