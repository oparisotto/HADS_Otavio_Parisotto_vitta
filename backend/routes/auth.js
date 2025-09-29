const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const pool = require("../db");

router.post("/register", async (req, res) => {
    const {nome, email, senha, tipo} = req.body;

    try{
        const userExists = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
        if (userExists.rows.length > 0){
            return res.status(400).json({ message: "Email já cadastrado"});
        }

        const hashedPassword = await bcrypt.hash(senha, 10);

        const newUser = await pool.query(
            "INSERT INTO usuarios (nome, email, senha, tipo) VALUES ($1, $2, $3, $4) RETURNING *",
            [nome, email, hashedPassword, tipo || "aluno"]
        );

        res.status(201).json({ message: "Usuário cadastrado com sucesso!", user: newUser.rows[0] });
    } catch (err) {
        res.status(500).json({ messge: err.message });
    }
});

router.post("/login", async (req, res) => {
    const { email, senha } = req.body;

    try {
        const user = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);

        if (user.rows.length === 0){
            return res.status(400).json({ message: "Usuário não encontrado"})
        }

        const validPassword = await bcrypt.compare(senha, user.rows[0].senha);
        if (!validPassword){
            return res.status(400).json({ message: "Senha inválida" });
        }

        res.json({ message: "Login realizado com sucesso!", });
    } catch (err) {
        res.status(500).json({ message: err.message});
    }
});

router.post("/recover", async (req, res) => {
    const { email } = req.body;

    try {
        const user = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);

        if (user.rows.length === 0 ){
            return res.status(400).json({ message: "Usuário não encontrado"});
        }

        res.json({ message: `Instruções de recuperação enviadas para ${email} `});
    } catch (err){
        res.status(500).json({ message: err.message});
    }
});

module.exports = router;