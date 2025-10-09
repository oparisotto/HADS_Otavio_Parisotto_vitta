const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const pool = require("../db");

const SECRET = process.env.JWT_SECRET;

// -------------------- LOGIN (Usuário) --------------------
router.post("/login", async (req, res) => {
  const { email, senha } = req.body;
  try {
    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0)
      return res.status(404).json({ message: "Usuário não encontrado" });

    const usuario = result.rows[0];

    if (!usuario.senha) {
      return res.status(500).json({ message: "Usuário sem senha válida" });
    }

    const senhaValida = await bcrypt.compare(senha, usuario.senha);
    if (!senhaValida) return res.status(401).json({ message: "Senha incorreta" });

    if (!SECRET) {
      console.error("JWT_SECRET não definido no .env");
      return res.status(500).json({ message: "Erro interno no servidor" });
    }

    const token = jwt.sign({ id: usuario.id, email: usuario.email }, SECRET, { expiresIn: "8h" });

    res.json({
      message: "Login realizado com sucesso",
      token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
      },
    });
  } catch (err) {
    console.error("Erro no login:", err);
    res.status(500).json({ message: "Erro interno no servidor", error: err.message });
  }
});

// -------------------- REGISTRO (Usuário) --------------------
router.post("/register", async (req, res) => {
  const { nome, email, senha } = req.body;
  try {
    const existe = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (existe.rows.length > 0)
      return res.status(400).json({ message: "Email já cadastrado" });

    const hash = await bcrypt.hash(senha, 10);
    await pool.query(
      "INSERT INTO usuarios (nome, email, senha) VALUES ($1, $2, $3)",
      [nome, email, hash]
    );

    res.json({ message: "Usuário registrado com sucesso" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erro ao registrar usuário" });
  }
});

// -------------------- RECUPERAR SENHA (Usuário) --------------------
let codigosRecuperacao = {}; // Armazena códigos temporariamente

router.post("/forgot-password", async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: "Email é obrigatório" });

  try {
    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0)
      return res.status(404).json({ message: "Email não encontrado" });

    const codigo = Math.floor(100000 + Math.random() * 900000);
    codigosRecuperacao[email] = codigo;

    // Transporter SMTP (mesmo usado no web)
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: process.env.SMTP_SECURE === "true",
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    await transporter.sendMail({
      from: `"Academia Vitta" <${process.env.SMTP_USER}>`,
      to: email,
      subject: "Recuperação de Senha - Vitta",
      text: `Olá! Seu código de recuperação é: ${codigo}`,
    });

    res.json({ message: "Código de recuperação enviado para o email" });
  } catch (err) {
    console.error("Erro ao enviar email:", err);
    res.status(500).json({ message: "Não foi possível enviar o email", error: err.message });
  }
});

// -------------------- RESETAR SENHA (Usuário) --------------------
router.post("/reset-password", async (req, res) => {
  const { email, codigo, novaSenha } = req.body;

  if (codigosRecuperacao[email] != codigo)
    return res.status(400).json({ message: "Código inválido" });

  const hash = await bcrypt.hash(novaSenha, 10);
  await pool.query("UPDATE usuarios SET senha = $1 WHERE email = $2", [hash, email]);

  delete codigosRecuperacao[email];
  res.json({ message: "Senha atualizada com sucesso" });
});

module.exports = router;
