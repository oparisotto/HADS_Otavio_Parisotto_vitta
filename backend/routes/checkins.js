const express = require("express");
const router = express.Router();
const pool = require("../db");

router.post("/", async(req, res) =>{
    const { usuario_id } = req.body;

    try {
        const pagamento = await pool.query(
            "SELECT * FROM pagamentos WHERE usuario_id = $1 AND status = 'pago' ORDER BY data_vencimento DESC LIMIT 1",
            [usuario_id]
        );

        if(pagamento.rows.length === 0) {
            return res.status(400).json({ message: "Usuário não possui pagamento ativo." })
        }

        const hoje = new Date();
        const vencimento = new Date(pagamento.rows[0].data_vencimento);

        if(vencimento < hoje){
            return res.status(400).json({ message: "Pagamento vencido. Usuário bloqueado para check-in."})
        }

        const novoCheckin = await pool.query(
            "INSERT INTO checkins (usuario_id) VALUES ($1) RETURNING *",
            [usuario_id]
        );

        res.status(201).json({ message: "Check-in realizado com sucesso!", checkin: novoCheckin.rows[0]});
    } catch (err) {
        res.status(500).json({ error: err.message});
    }
});

router.get("/:usuario_id", async (req, res) => {
    const { usuario_id } = req.params;

    try {
        const result = await pool.query(
            `SELECT c.id, c.data_checkin, u.nome, u.email
            FROM checkins c
            JOIN usuarios u ON u.id = c.usuario_id
            WHERE c.usuario_id = $1
            ORDER BY c.data_checkin DESC`,
            [usuario_id]
        );

        res.json(result.rows);
    } catch (err){
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;