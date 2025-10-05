const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const pool = require("../db"); // seu pool de conexão PostgreSQL

// =================== LOGIN FUNCIONÁRIO ===================
router.post("/login", async (req, res) => {
  const { email, senha } = req.body;

  try {
    // Buscar funcionário pelo email
    const result = await pool.query(
      "SELECT * FROM funcionarios WHERE email = $1",
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ msg: "Funcionário não encontrado" });
    }

    const funcionario = result.rows[0];

    // Comparar senha
    const isMatch = await bcrypt.compare(senha, funcionario.senha);
    if (!isMatch) {
      return res.status(400).json({ msg: "Senha incorreta" });
    }

    // Login bem-sucedido
    res.json({
      msg: "Login realizado com sucesso",
      funcionario: {
        id: funcionario.id,
        nome: funcionario.nome,
        email: funcionario.email,
        cargo: funcionario.cargo,
        data_admissao: funcionario.data_admissao
      }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// =================== REGISTRAR FUNCIONÁRIO ===================
router.post("/register", async (req, res) => {
  const { nome, email, senha, cargo } = req.body;

  try {
    // Verificar se já existe funcionário com o email
    const existing = await pool.query(
      "SELECT * FROM funcionarios WHERE email = $1",
      [email]
    );
    if (existing.rows.length > 0) {
      return res.status(400).json({ msg: "Email já cadastrado" });
    }

    // Criptografar senha
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(senha, salt);

    // Inserir no banco
    const result = await pool.query(
      "INSERT INTO funcionarios (nome, email, senha, cargo, data_admissao) VALUES ($1, $2, $3, $4, NOW()) RETURNING *",
      [nome, email, hashedPassword, cargo]
    );

    const novoFuncionario = result.rows[0];

    res.json({
      msg: "Funcionário cadastrado com sucesso",
      funcionario: {
        id: novoFuncionario.id,
        nome: novoFuncionario.nome,
        email: novoFuncionario.email,
        cargo: novoFuncionario.cargo,
        data_admissao: novoFuncionario.data_admissao
      }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

module.exports = router;
