// routes/authUsuarios.js
const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const pool = require("../db");

const SECRET = process.env.JWT_SECRET || "fallback_secret";

// ----------------------
// FUNÇÃO: ajustarStatusUsuario
// ----------------------
async function ajustarStatusUsuario(userId, client = null) {
  const runner = client || pool;

  const q = `
    SELECT
      u.id,
      u.plano_atual_id,
      (
        SELECT data_pagamento
        FROM pagamentos
        WHERE usuario_id = u.id AND status = 'pago'
        ORDER BY data_pagamento DESC
        LIMIT 1
      ) AS ultimo_pagamento
    FROM usuarios u
    WHERE u.id = $1
  `;

  const { rows } = await runner.query(q, [userId]);
  if (rows.length === 0) return;

  const user = rows[0];

  // Se não tem plano -> sem_plano + inativo
  if (!user.plano_atual_id) {
    await runner.query(
      `UPDATE usuarios SET status_plano = $1, status = $2 WHERE id = $3`,
      ["sem_plano", "inativo", userId]
    );
    return;
  }

  // Tem plano: verificar último pagamento
  if (!user.ultimo_pagamento) {
    // nunca pagou -> inativo
    await runner.query(
      `UPDATE usuarios SET status_plano = $1, status = $2 WHERE id = $3`,
      ["inativo", "inativo", userId]
    );
    return;
  }

  const ultimo = new Date(user.ultimo_pagamento);
  const dias = Math.floor((Date.now() - ultimo.getTime()) / (1000 * 60 * 60 * 24));

  if (dias < 30) {
    // ativo
    await runner.query(
      `UPDATE usuarios SET status_plano = $1, status = $2 WHERE id = $3`,
      ["ativo", "active", userId]
    );
    return;
  }

  if (dias < 60) {
    // atrasado
    await runner.query(
      `UPDATE usuarios SET status_plano = $1, status = $2 WHERE id = $3`,
      ["atrasado", "inativo", userId]
    );
    return;
  }

  if (dias < 90) {
    // inativo
    await runner.query(
      `UPDATE usuarios SET status_plano = $1, status = $2 WHERE id = $3`,
      ["inativo", "inativo", userId]
    );
    return;
  }

  // >= 90 dias -> remove plano e marca sem_plano
  await runner.query(
    `UPDATE usuarios SET plano_atual_id = NULL, status_plano = $1, status = $2, data_atualizacao_plano = NOW() WHERE id = $3`,
    ["sem_plano", "inativo", userId]
  );
}

// ====================================================================
// LISTAR USUÁRIOS
// ====================================================================
router.get("/", async (req, res) => {
  try {
    console.log("📋 Buscando todos os usuários...");

    // Por padrão ajusta antes de retornar. Para pular: ?skipUpdate=true
    if (req.query.skipUpdate !== "true") {
      const all = await pool.query("SELECT id FROM usuarios");
      for (const u of all.rows) {
        try {
          await ajustarStatusUsuario(u.id);
        } catch (errAdj) {
          console.error(`Erro ajustando usuário ${u.id}:`, errAdj);
        }
      }
    } else {
      console.log("ℹ️ skipUpdate=true — pulando ajuste pré-listagem");
    }

    const result = await pool.query(`
      SELECT 
        u.id,
        u.nome,
        u.email,
        u.status as usuario_status,
        u.plano_atual_id,
        u.status_plano,
        u.data_atualizacao_plano,
        u.created_at,
        p_atual.nome as plano_nome,
        p_atual.descricao as plano_descricao,
        (SELECT status FROM pagamentos 
         WHERE usuario_id = u.id 
         ORDER BY data_pagamento DESC 
         LIMIT 1) as status_pagamento,
        (SELECT pl.nome FROM pagamentos pa
         JOIN planos pl ON pa.plano_id = pl.id
         WHERE pa.usuario_id = u.id 
         ORDER BY pa.data_pagamento DESC 
         LIMIT 1) as plano_ultimo_pagamento,
        (SELECT data_pagamento FROM pagamentos 
         WHERE usuario_id = u.id 
         ORDER BY data_pagamento DESC 
         LIMIT 1) as data_ultimo_pagamento
      FROM usuarios u
      LEFT JOIN planos p_atual ON u.plano_atual_id = p_atual.id
      ORDER BY u.created_at DESC
    `);

    console.log(`✅ ${result.rows.length} usuários encontrados`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Erro ao buscar usuários:", err);
    res.status(500).json({ error: err.message });
  }
});

// ====================================================================
// CORRIGIR STATUS INCONSISTENTES
// ====================================================================
router.post("/corrigir-status", async (req, res) => {
  try {
    console.log("🔧 Corrigindo status inconsistentes...");

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      const resultReativados = await client.query(`
        UPDATE usuarios 
        SET status_plano = 'ativo' 
        WHERE plano_atual_id IS NOT NULL 
        AND status_plano = 'cancelado'
        RETURNING id, nome
      `);

      const resultAjustados = await client.query(`
        UPDATE usuarios 
        SET status_plano = 'inativo' 
        WHERE plano_atual_id IS NULL 
        AND status_plano = 'ativo'
        RETURNING id, nome
      `);

      await client.query("COMMIT");

      res.json({
        success: true,
        message: "Status corrigidos com sucesso",
        dados: {
          reativados: resultReativados.rows.length,
          ajustados: resultAjustados.rows.length,
        },
      });
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("❌ Erro ao corrigir status:", err);
    res.status(500).json({
      success: false,
      message: "Erro interno ao corrigir status",
      error: err.message,
    });
  }
});

// ====================================================================
// LOGIN
// ====================================================================
router.post("/login", async (req, res) => {
  const { email, senha } = req.body;

  try {
    console.log("🔐 Tentativa de login:", email);

    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0) return res.status(404).json({ message: "Usuário não encontrado" });

    const usuario = result.rows[0];

    const senhaValida = await bcrypt.compare(senha, usuario.senha);
    if (!senhaValida) return res.status(401).json({ message: "Senha incorreta" });

    // ajustar status do usuário antes de retornar dados
    try {
      await ajustarStatusUsuario(usuario.id);
    } catch (e) {
      console.error("⚠️ Erro ao ajustar status no login:", e);
    }

    const usuarioAtual = await pool.query("SELECT id, nome, email, status, plano_atual_id, status_plano FROM usuarios WHERE id = $1", [usuario.id]);

    const token = jwt.sign({ id: usuario.id, email: usuario.email }, SECRET, { expiresIn: "8h" });

    res.json({
      message: "Login realizado com sucesso",
      token,
      usuario: usuarioAtual.rows[0],
    });
  } catch (err) {
    console.error("❌ Erro no login:", err);
    res.status(500).json({ message: err.message });
  }
});

// ====================================================================
// BUSCAR PLANO DO USUÁRIO
// ====================================================================
router.get("/:id/plano", async (req, res) => {
  try {
    const { id } = req.params;

    try { await ajustarStatusUsuario(id); } catch (e) { console.error(e); }

    const result = await pool.query(
      `
      SELECT 
        u.id,
        u.nome,
        u.email,
        u.plano_atual_id,
        u.status_plano,
        p.nome as nome_plano,
        p.descricao as descricao_plano,
        p.preco as preco_plano,
        (SELECT status FROM pagamentos 
         WHERE usuario_id = u.id AND status = 'pago'
         ORDER BY data_pagamento DESC 
         LIMIT 1) as status_pagamento
      FROM usuarios u
      LEFT JOIN planos p ON u.plano_atual_id = p.id
      WHERE u.id = $1
    `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: "Usuário não encontrado" });
    }

    const usuario = result.rows[0];

    res.json({
      success: true,
      nome_plano: usuario.nome_plano || "Sem plano",
      descricao_plano: usuario.descricao_plano || "",
      preco_plano: usuario.preco_plano || 0,
      status_plano: usuario.status_plano || "inativo",
      status_pagamento: usuario.status_pagamento || "pendente",
    });
  } catch (err) {
    console.error("❌ Erro ao buscar plano do usuário:", err);
    res.status(500).json({ message: err.message });
  }
});

// ====================================================================
// BUSCAR USUÁRIO ESPECÍFICO
// ====================================================================
router.get("/usuario/:id", async (req, res) => {
  try {
    const { id } = req.params;

    try { await ajustarStatusUsuario(id); } catch (e) { console.error(e); }

    const result = await pool.query(
      `
      SELECT 
        u.id,
        u.nome,
        u.email,
        u.status as usuario_status,
        u.plano_atual_id,
        u.status_plano,
        u.data_atualizacao_plano,
        u.created_at,
        p_atual.nome as plano_nome,
        p_atual.descricao as plano_descricao,
        (SELECT status FROM pagamentos 
         WHERE usuario_id = u.id 
         ORDER BY data_pagamento DESC 
         LIMIT 1) as status_pagamento,
        (SELECT pl.nome FROM pagamentos pa
         JOIN planos pl ON pa.plano_id = pl.id
         WHERE pa.usuario_id = u.id 
         ORDER BY pa.data_pagamento DESC 
         LIMIT 1) as plano_ultimo_pagamento
      FROM usuarios u
      LEFT JOIN planos p_atual ON u.plano_atual_id = p_atual.id
      WHERE u.id = $1
    `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Usuário não encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("❌ Erro ao buscar usuário:", err);
    res.status(500).json({ error: err.message });
  }
});

// ====================================================================
// REGISTER
// ====================================================================
router.post("/register", async (req, res) => {
  try {
    const { nome, email, senha } = req.body;

    const userExists = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (userExists.rows.length > 0) {
      return res.status(400).json({ success: false, message: "Usuário já cadastrado" });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);

    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, senha, status) 
       VALUES ($1, $2, $3, 'pending') 
       RETURNING id, nome, email, status, created_at`,
      [nome, email, hashedPassword]
    );

    const usuario = result.rows[0];

    const token = jwt.sign(
      { userId: usuario.id, email: usuario.email },
      SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: "Usuário registrado com sucesso. Faça o pagamento para ativar sua conta.",
      token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        status: usuario.status
      }
    });
  } catch (error) {
    console.error("❌ Erro no registro:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ====================================================================
// VERIFICAR STATUS
// ====================================================================
router.get("/status/:id", async (req, res) => {
  try {
    const { id } = req.params;

    try { await ajustarStatusUsuario(id); } catch (e) { console.error(e); }

    const result = await pool.query(
      "SELECT id, nome, email, status FROM usuarios WHERE id = $1",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: "Usuário não encontrado" });
    }

    const usuario = result.rows[0];

    res.json({
      success: true,
      status: usuario.status,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email
      }
    });
  } catch (error) {
    console.error("❌ Erro ao verificar status:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ====================================================================
// CANCELAR PLANO
// ====================================================================
router.put("/:id/cancelar-plano", async (req, res) => {
  try {
    const { id } = req.params;

    const usuarioExiste = await pool.query(
      "SELECT id, nome, plano_atual_id FROM usuarios WHERE id = $1",
      [id]
    );

    if (usuarioExiste.rows.length === 0) {
      return res.status(404).json({ success: false, message: "Usuário não encontrado" });
    }

    const usuario = usuarioExiste.rows[0];

    if (!usuario.plano_atual_id) {
      return res.status(400).json({
        success: false,
        message: "Usuário não possui um plano ativo para cancelar"
      });
    }

    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      await client.query(`
        UPDATE usuarios 
        SET status_plano = 'cancelado', data_atualizacao_plano = NOW()
        WHERE id = $1
      `, [id]);

      await client.query(`
        UPDATE pagamentos 
        SET status = 'cancelado'
        WHERE usuario_id = $1 AND status = 'pago'
      `, [id]);

      await client.query('COMMIT');

      // ajustar para refletir cancelamento
      try { await ajustarStatusUsuario(id); } catch (e) { console.error(e); }

      res.json({ success: true, message: "Plano cancelado com sucesso" });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("❌ Erro ao cancelar plano:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================================================================
// REATIVAR PLANO
// ====================================================================
router.put("/:id/reativar-plano", async (req, res) => {
  try {
    const { id } = req.params;

    const usuarioExiste = await pool.query(`
      SELECT id, nome, plano_atual_id, status_plano 
      FROM usuarios 
      WHERE id = $1
    `, [id]);

    if (usuarioExiste.rows.length === 0)
      return res.status(404).json({ success: false, message: "Usuário não encontrado" });

    const usuario = usuarioExiste.rows[0];

    if (usuario.status_plano !== 'cancelado')
      return res.status(400).json({ success: false, message: "Plano não está cancelado" });

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      await client.query(`
        UPDATE usuarios 
        SET status_plano = 'ativo', status = 'active', data_atualizacao_plano = NOW()
        WHERE id = $1
      `, [id]);

      const ultimoPagamento = await client.query(`
        SELECT id FROM pagamentos 
        WHERE usuario_id = $1 
        ORDER BY data_pagamento DESC 
        LIMIT 1
      `, [id]);

      if (ultimoPagamento.rows.length > 0) {
        await client.query(`
          UPDATE pagamentos SET status = 'pago' WHERE id = $1
        `, [ultimoPagamento.rows[0].id]);
      }

      await client.query('COMMIT');

      // ajustar para garantir consistência
      try { await ajustarStatusUsuario(id); } catch (e) { console.error(e); }

      res.json({ success: true, message: "Plano reativado com sucesso" });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("❌ Erro ao reativar plano:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================================================================
// VERIFICAR STATUS DO PLANO
// ====================================================================
router.get("/:id/status-plano", async (req, res) => {
  try {
    const { id } = req.params;

    try { await ajustarStatusUsuario(id); } catch (e) { console.error(e); }

    const result = await pool.query(`
      SELECT 
        id,
        nome,
        email,
        plano_atual_id,
        status_plano,
        data_atualizacao_plano
      FROM usuarios 
      WHERE id = $1
    `, [id]);

    if (result.rows.length === 0)
      return res.status(404).json({ success: false, message: "Usuário não encontrado" });

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (err) {
    console.error("❌ Erro ao verificar status do plano:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================================================================
// RECUPERAR SENHA
// ====================================================================
let codigosRecuperacao = {};

router.post("/forgot-password", async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: "Email é obrigatório" });

  try {
    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0)
      return res.status(404).json({ message: "Email não encontrado" });

    const codigo = Math.floor(100000 + Math.random() * 900000);
    codigosRecuperacao[email] = codigo;

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
    res.status(500).json({ message: "Erro ao enviar email", error: err.message });
  }
});

// ====================================================================
// RESETAR SENHA
// ====================================================================
router.post("/reset-password", async (req, res) => {
  const { email, codigo, novaSenha } = req.body;

  if (codigosRecuperacao[email] != codigo)
    return res.status(400).json({ message: "Código inválido" });

  const hash = await bcrypt.hash(novaSenha, 10);
  await pool.query("UPDATE usuarios SET senha = $1 WHERE email = $2", [hash, email]);

  delete codigosRecuperacao[email];
  res.json({ message: "Senha atualizada com sucesso" });
});

// ====================================================================
// ATUALIZAR STATUS COM BASE NO ÚLTIMO PAGAMENTO (TIMESTAMP) - LOTE
// ====================================================================
router.post("/atualizar-status-tempo", async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const usuarios = await client.query("SELECT id FROM usuarios");

    for (const u of usuarios.rows) {
      try {
        // passar client para que as atualizações fiquem na mesma transação
        await ajustarStatusUsuario(u.id, client);
      } catch (errUser) {
        console.error(`Erro ajustando usuário ${u.id} em lote:`, errUser);
        // não abortar todo o processo por causa de 1 falha; continuar
      }
    }

    await client.query("COMMIT");
    res.json({ success: true, message: "Status atualizados em lote com sucesso" });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("❌ Erro ao atualizar status em lote:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    client.release();
  }
});

// ====================================================================
module.exports = router;
