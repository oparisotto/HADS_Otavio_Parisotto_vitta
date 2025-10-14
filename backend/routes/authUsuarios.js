const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const pool = require("../db");

const SECRET = process.env.JWT_SECRET;

// -------------------- LISTAR USUÁRIOS (COM FILTRO CORRETO) --------------------
router.get("/", async (req, res) => {
    try {
        console.log("📋 Buscando todos os usuários...");
        
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

// -------------------- CORRIGIR STATUS INCONSISTENTES --------------------
router.post("/corrigir-status", async (req, res) => {
  try {
    console.log("🔧 Corrigindo status inconsistentes...");
    
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      const resultReativados = await client.query(
        `UPDATE usuarios 
         SET status_plano = 'ativo' 
         WHERE plano_atual_id IS NOT NULL 
         AND status_plano = 'cancelado'
         RETURNING id, nome`
      );

      console.log(`✅ ${resultReativados.rows.length} usuários reativados automaticamente`);

      const resultAjustados = await client.query(
        `UPDATE usuarios 
         SET status_plano = 'inativo' 
         WHERE plano_atual_id IS NULL 
         AND status_plano = 'ativo'
         RETURNING id, nome`
      );

      console.log(`🔄 ${resultAjustados.rows.length} usuários ajustados para inativo`);

      await client.query('COMMIT');

      res.json({
        success: true,
        message: "Status corrigidos com sucesso",
        dados: {
          reativados: resultReativados.rows.length,
          ajustados: resultAjustados.rows.length
        }
      });

    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

  } catch (err) {
    console.error("❌ Erro ao corrigir status:", err);
    res.status(500).json({
      success: false,
      message: "Erro interno ao corrigir status",
      error: err.message
    });
  }
});

// -------------------- LOGIN (CORRIGIDO) --------------------
router.post("/login", async (req, res) => {
  const { email, senha } = req.body;
  
  try {
    console.log('🔐 Tentativa de login para:', email);
    
    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0) {
      console.log('❌ Usuário não encontrado:', email);
      return res.status(404).json({ message: "Usuário não encontrado" });
    }

    const usuario = result.rows[0];
    console.log('✅ Usuário encontrado:', { 
      id: usuario.id, 
      nome: usuario.nome, 
      email: usuario.email 
    });

    if (!usuario.senha) {
      return res.status(500).json({ message: "Usuário sem senha válida" });
    }

    const senhaValida = await bcrypt.compare(senha, usuario.senha);
    if (!senhaValida) {
      console.log('❌ Senha incorreta para:', email);
      return res.status(401).json({ message: "Senha incorreta" });
    }

    if (!SECRET) {
      console.error("JWT_SECRET não definido no .env");
      return res.status(500).json({ message: "Erro interno no servidor" });
    }

    const token = jwt.sign({ id: usuario.id, email: usuario.email }, SECRET, { expiresIn: "8h" });

    console.log('✅ Login bem-sucedido para:', usuario.nome);
    
    // ✅ CORREÇÃO: Retornar dados COMPLETOS do usuário
    res.json({
      message: "Login realizado com sucesso",
      token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        status: usuario.status,
        plano_atual_id: usuario.plano_atual_id,
        status_plano: usuario.status_plano
      },
    });
  } catch (err) {
    console.error("❌ Erro no login:", err);
    res.status(500).json({ message: "Erro interno no servidor", error: err.message });
  }
});

// -------------------- BUSCAR PLANO DO USUÁRIO ESPECÍFICO --------------------
router.get("/:id/plano", async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🔍 Buscando plano do usuário ID: ${id}`);

    const result = await pool.query(`
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
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
    }

    const usuario = result.rows[0];
    
    console.log(`✅ Plano encontrado para ${usuario.nome}:`, {
      plano_id: usuario.plano_atual_id,
      plano_nome: usuario.nome_plano,
      status_plano: usuario.status_plano,
      status_pagamento: usuario.status_pagamento
    });

    res.json({
      success: true,
      nome_plano: usuario.nome_plano || 'Sem plano',
      descricao_plano: usuario.descricao_plano || '',
      preco_plano: usuario.preco_plano || 0,
      status_plano: usuario.status_plano || 'inativo',
      status_pagamento: usuario.status_pagamento || 'pendente'
    });

  } catch (err) {
    console.error("❌ Erro ao buscar plano do usuário:", err);
    res.status(500).json({
      success: false,
      message: "Erro interno ao buscar plano",
      error: err.message
    });
  }
});

// -------------------- BUSCAR USUÁRIO ESPECÍFICO --------------------
router.get("/usuario/:id", async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🔍 Buscando usuário específico ID: ${id}`);
    
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
         LIMIT 1) as plano_ultimo_pagamento
      FROM usuarios u
      LEFT JOIN planos p_atual ON u.plano_atual_id = p_atual.id
      WHERE u.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Usuário não encontrado" });
    }
    
    const usuario = result.rows[0];
    console.log(`✅ Usuário encontrado:`, usuario);
    
    res.json(usuario);
  } catch (err) {
    console.error("❌ Erro ao buscar usuário:", err);
    res.status(500).json({ error: err.message });
  }
});

// ---------- REGISTER (COM STATUS PENDING) ----------
router.post("/register", async (req, res) => {
  try {
    const { nome, email, senha } = req.body;

    console.log("📝 Tentando registrar usuário:", { nome, email });

    const userExists = await pool.query(
      "SELECT * FROM usuarios WHERE email = $1", 
      [email]
    );

    if (userExists.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Usuário já cadastrado"
      });
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(senha, saltRounds);

    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, senha, status) 
       VALUES ($1, $2, $3, 'pending') 
       RETURNING id, nome, email, status, created_at`,
      [nome, email, hashedPassword]
    );

    const usuario = result.rows[0];
    
    const token = jwt.sign(
      { userId: usuario.id, email: usuario.email },
      process.env.JWT_SECRET || "fallback_secret",
      { expiresIn: '24h' }
    );

    console.log("✅ Usuário registrado com status pending:", usuario.id);

    res.json({
      success: true,
      message: "Usuário registrado com sucesso. Faça o pagamento para ativar sua conta.",
      token: token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        status: usuario.status
      }
    });

  } catch (error) {
    console.error("❌ Erro no registro:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// ---------- VERIFICAR STATUS DO USUÁRIO ----------
router.get("/status/:id", async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log("🔍 Verificando status do usuário:", id);

    const result = await pool.query(
      "SELECT id, nome, email, status FROM usuarios WHERE id = $1",
      [id]
    );

    if (result.rows.length > 0) {
      const usuario = result.rows[0];
      console.log("📊 Status do usuário:", usuario.status);
      
      res.json({
        success: true,
        status: usuario.status,
        usuario: {
          id: usuario.id,
          nome: usuario.nome,
          email: usuario.email
        }
      });
    } else {
      res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
    }
  } catch (error) {
    console.error("❌ Erro ao verificar status:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// ---------- ATIVAR USUÁRIO (APÓS PAGAMENTO) ----------
router.put("/ativar/:id", async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log("🎯 Ativando usuário:", id);

    const result = await pool.query(
      "UPDATE usuarios SET status = 'active' WHERE id = $1 RETURNING id, nome, email, status",
      [id]
    );

    if (result.rows.length > 0) {
      const usuario = result.rows[0];
      console.log("✅ Usuário ativado:", usuario.id);
      
      res.json({
        success: true,
        message: "Usuário ativado com sucesso",
        usuario: usuario
      });
    } else {
      res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
    }
  } catch (error) {
    console.error("❌ Erro ao ativar usuário:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// ---------- CANCELAR PLANO DO USUÁRIO ----------
router.put("/:id/cancelar-plano", async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log("❌ Cancelando plano do usuário:", id);

    const usuarioExiste = await pool.query(
      "SELECT id, nome, plano_atual_id FROM usuarios WHERE id = $1",
      [id]
    );

    if (usuarioExiste.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
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

      const resultUsuario = await client.query(
        `UPDATE usuarios 
         SET status_plano = 'cancelado', data_atualizacao_plano = $1 
         WHERE id = $2 
         RETURNING id, nome, email, plano_atual_id, status_plano`,
        [new Date(), id]
      );

      await client.query(
        `UPDATE pagamentos 
         SET status = 'cancelado' 
         WHERE usuario_id = $1 AND status = 'pago'`,
        [id]
      );

      await client.query('COMMIT');

      const usuarioAtualizado = resultUsuario.rows[0];
      console.log("✅ Plano cancelado com sucesso:", usuarioAtualizado.nome);

      res.json({
        success: true,
        message: "Plano cancelado com sucesso",
        usuario: usuarioAtualizado
      });

    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

  } catch (err) {
    console.error("❌ Erro ao cancelar plano:", err);
    res.status(500).json({
      success: false,
      message: "Erro interno ao cancelar plano",
      error: err.message
    });
  }
});

// ---------- REATIVAR PLANO ----------
router.put("/:id/reativar-plano", async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log("✅ Reativando plano do usuário:", id);

    const usuarioExiste = await pool.query(
      "SELECT id, nome, plano_atual_id, status_plano FROM usuarios WHERE id = $1",
      [id]
    );

    if (usuarioExiste.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
    }

    const usuario = usuarioExiste.rows[0];

    if (usuario.status_plano !== 'cancelado') {
      return res.status(400).json({
        success: false,
        message: "O plano do usuário não está cancelado"
      });
    }

    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      const resultUsuario = await client.query(
        `UPDATE usuarios 
         SET status_plano = 'ativo', data_atualizacao_plano = $1 
         WHERE id = $2 
         RETURNING id, nome, email, plano_atual_id, status_plano`,
        [new Date(), id]
      );

      const ultimoPagamento = await client.query(
        `SELECT id FROM pagamentos 
         WHERE usuario_id = $1 
         ORDER BY data_pagamento DESC 
         LIMIT 1`,
        [id]
      );

      if (ultimoPagamento.rows.length > 0) {
        const pagamentoId = ultimoPagamento.rows[0].id;
        
        await client.query(
          `UPDATE pagamentos SET status = 'pago' WHERE id = $1`,
          [pagamentoId]
        );
        
        console.log("✅ Último pagamento reativado:", pagamentoId);
      }

      await client.query('COMMIT');

      const usuarioAtualizado = resultUsuario.rows[0];
      console.log("✅ Plano reativado com sucesso:", usuarioAtualizado.nome);

      res.json({
        success: true,
        message: "Plano reativado com sucesso",
        usuario: usuarioAtualizado
      });

    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

  } catch (err) {
    console.error("❌ Erro ao reativar plano:", err);
    res.status(500).json({
      success: false,
      message: "Erro interno ao reativar plano",
      error: err.message
    });
  }
});

// ---------- VERIFICAR STATUS DO PLANO ----------
router.get("/:id/status-plano", async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log("🔍 Verificando status do plano do usuário:", id);

    const result = await pool.query(
      `SELECT 
        id,
        nome,
        email,
        plano_atual_id,
        status_plano,
        data_atualizacao_plano
       FROM usuarios 
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
    }

    const usuario = result.rows[0];
    
    res.json({
      success: true,
      data: {
        usuario_id: usuario.id,
        plano_atual_id: usuario.plano_atual_id,
        status_plano: usuario.status_plano || 'ativo',
        data_atualizacao: usuario.data_atualizacao_plano
      }
    });

  } catch (err) {
    console.error("❌ Erro ao verificar status do plano:", err);
    res.status(500).json({
      success: false,
      message: "Erro interno ao verificar status do plano",
      error: err.message
    });
  }
});

// -------------------- RECUPERAR SENHA --------------------
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
    res.status(500).json({ message: "Não foi possível enviar o email", error: err.message });
  }
});

// -------------------- RESETAR SENHA --------------------
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