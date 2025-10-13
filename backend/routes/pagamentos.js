const express = require("express");
const router = express.Router();
const pool = require("../db");
const asaas = require("../config/asaas");

// ---------- CRIAR CLIENTE NO ASAAS ----------
router.post("/criar-cliente", async (req, res) => {
  console.log("🔧 Rota /criar-cliente chamada");
  
  try {
    const { nome, email, cpfCnpj } = req.body;

    console.log("📧 Dados recebidos:", { nome, email, cpfCnpj });

    if (!nome || !email || !cpfCnpj) {
      return res.status(400).json({
        success: false,
        message: "Nome, email e CPF/CNPJ são obrigatórios"
      });
    }

    // Verificar se asaas está disponível
    if (!asaas) {
      console.error("❌ Asaas não está definido");
      return res.status(500).json({
        success: false,
        message: "Serviço de pagamento não configurado"
      });
    }

    if (typeof asaas.criarCliente !== 'function') {
      console.error("❌ asaas.criarCliente não é uma função");
      return res.status(500).json({
        success: false,
        message: "Função criarCliente não disponível"
      });
    }

    console.log("📤 Chamando Asaas...");
    
    // ✅ CORREÇÃO: Removemos a verificação por email que não existe
    // Criar cliente diretamente - se já existir, o Asaas retorna erro
    const cliente = await asaas.criarCliente({
      name: nome,
      email: email,
      cpfCnpj: cpfCnpj.replace(/\D/g, '') // Remove caracteres não numéricos
    });

    console.log("✅ Cliente criado no Asaas:", cliente.id);
    
    res.json({
      success: true,
      id: cliente.id,
      name: cliente.name,
      email: cliente.email
    });

  } catch (error) {
    console.error("❌ Erro em /criar-cliente:", error.message);
    
    // Se o erro for que o cliente já existe, tratamos de forma amigável
    if (error.message.includes('já existe') || error.message.includes('already exists')) {
      return res.status(400).json({
        success: false,
        message: "Já existe um cliente com este email ou CPF/CNPJ"
      });
    }
    
    res.status(500).json({
      success: false,
      message: error.message || "Erro interno do servidor"
    });
  }
});

// ---------- CRIAR COBRANÇA CARTAO ----------
router.post("/criar-cobranca-cartao", async (req, res) => {
  try {
    const {
      customer,
      value,
      creditCard,
      creditCardHolderInfo
    } = req.body;

    console.log("💳 Criando cobrança cartão:", { customer, value });

    const cobranca = await asaas.criarPagamentoCartao({
      customer,
      value: parseFloat(value),
      creditCard: {
        holderName: creditCard.holderName,
        number: creditCard.number.replace(/\s/g, ''),
        expiryMonth: creditCard.expiryMonth,
        expiryYear: creditCard.expiryYear,
        ccv: creditCard.ccv
      },
      creditCardHolderInfo: {
        name: creditCardHolderInfo.name,
        email: creditCardHolderInfo.email,
        cpfCnpj: creditCardHolderInfo.cpfCnpj.replace(/\D/g, ''),
        postalCode: creditCardHolderInfo.postalCode || '80210010',
        addressNumber: creditCardHolderInfo.addressNumber || '123',
        addressComplement: creditCardHolderInfo.addressComplement || '',
        phone: creditCardHolderInfo.phone || '4133333333',
        mobilePhone: creditCardHolderInfo.mobilePhone || '41999999999'
      },
      remoteIp: req.ip || '127.0.0.1'
    });

    res.json({
      success: true,
      id: cobranca.id,
      value: cobranca.value,
      status: cobranca.status
    });

  } catch (error) {
    console.error("❌ Erro ao criar cobrança cartão:", error.message);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// ---------- SALVAR ASSINATURA (ROTA PRINCIPAL) ----------
router.post("/", async (req, res) => {
  try {
    const { usuario_id, plano_id, customer_id, subscription_id, status } = req.body;
    
    console.log("💾 SALVANDO ASSINATURA NO BANCO - DADOS RECEBIDOS:", { 
      usuario_id, 
      plano_id, 
      customer_id,
      subscription_id,
      status 
    });

    // ✅ VALIDAÇÃO: Verificar se todos os campos obrigatórios estão presentes
    if (!usuario_id || !plano_id || !subscription_id) {
      return res.status(400).json({
        success: false,
        message: "Dados incompletos: usuario_id, plano_id e subscription_id são obrigatórios"
      });
    }

    // ✅ VALIDAÇÃO CRÍTICA: Verificar se usuario_id não é 0
    if (usuario_id === 0) {
      return res.status(400).json({
        success: false,
        message: "ID do usuário inválido (0). Faça login novamente."
      });
    }

    // ✅ VALIDAÇÃO: Verificar se usuário existe
    const usuarioExiste = await pool.query(
      "SELECT id, nome, email, plano_atual_id FROM usuarios WHERE id = $1",
      [usuario_id]
    );

    if (usuarioExiste.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuário não encontrado"
      });
    }

    const usuario = usuarioExiste.rows[0];
    console.log("✅ Usuário validado:", usuario.nome, usuario.email);

    // ✅ VERIFICAR SE PLANO EXISTE
    const planoExiste = await pool.query(
      "SELECT id, nome, preco FROM planos WHERE id = $1",
      [plano_id]
    );

    if (planoExiste.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Plano não encontrado"
      });
    }

    const plano = planoExiste.rows[0];
    console.log("✅ Plano validado:", plano.nome, "R$", plano.preco);

    // ✅ VALIDAÇÃO E MAPEAMENTO DO STATUS
    console.log("📊 Status recebido do Flutter:", status);
    
    // Mapear status para valores permitidos no banco
    let statusParaBanco;
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
      case 'CONFIRMED':
      case 'RECEIVED':
      case 'APPROVED':
      case 'PAGO':
        statusParaBanco = 'pago';
        break;
      case 'PENDING':
      case 'AWAITING_PAYMENT':
      case 'IN_ANALYSIS':
      case 'PENDENTE':
        statusParaBanco = 'pendente';
        break;
      case 'OVERDUE':
      case 'EXPIRED':
      case 'VENCIDO':
        statusParaBanco = 'vencido';
        break;
      case 'CANCELLED':
      case 'CANCELED':
      case 'CANCELADO':
        statusParaBanco = 'cancelado';
        break;
      case 'REFUNDED':
      case 'REEMBOLSADO':
        statusParaBanco = 'reembolsado';
        break;
      case 'INACTIVE':
      case 'INATIVO':
        statusParaBanco = 'inativo';
        break;
      default:
        console.warn('⚠️ Status não reconhecido, usando "pendente" como fallback:', status);
        statusParaBanco = 'pendente';
    }

    console.log("📊 Status mapeado para banco:", statusParaBanco);

    // ✅ VERIFICAR SE O STATUS É VÁLIDO ANTES DE INSERIR
    const statusValidos = ['pago', 'pendente', 'vencido', 'cancelado', 'reembolsado', 'inativo'];
    if (!statusValidos.includes(statusParaBanco)) {
      return res.status(400).json({
        success: false,
        message: `Status inválido: ${statusParaBanco}. Status permitidos: ${statusValidos.join(', ')}`
      });
    }

    // ✅ INICIAR TRANSACTION PARA GARANTIR CONSISTÊNCIA
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      console.log("💾 Salvando pagamento...");

      // 1. ✅ SALVAR PAGAMENTO
      const resultPagamento = await client.query(
        `INSERT INTO pagamentos 
         (usuario_id, plano_id, status, data_pagamento, data_vencimento, asaas_payment_id) 
         VALUES ($1, $2, $3, $4, $5, $6) 
         RETURNING *`,
        [
          usuario_id, 
          plano_id, 
          statusParaBanco, // ✅ USAR STATUS VALIDADO
          new Date(),
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 dias
          subscription_id
        ]
      );

      const assinaturaSalva = resultPagamento.rows[0];
      console.log("✅ Pagamento salvo - ID:", assinaturaSalva.id);

      // 2. ✅ ATUALIZAR PLANO DO USUÁRIO
      console.log("🔄 Atualizando plano do usuário...");
      
      const resultUsuario = await client.query(
        `UPDATE usuarios 
         SET plano_atual_id = $1, data_atualizacao_plano = $2 
         WHERE id = $3 
         RETURNING id, nome, plano_atual_id`,
        [plano_id, new Date(), usuario_id]
      );

      const usuarioAtualizado = resultUsuario.rows[0];
      console.log("✅ Plano do usuário atualizado:", usuarioAtualizado.plano_atual_id);

      // 3. ✅ SE HOUVER PLANO ANTERIOR, MARCAR COMO INATIVO
      if (usuario.plano_atual_id && usuario.plano_atual_id !== plano_id) {
        console.log("📋 Marcando plano anterior como inativo...");
        
        await client.query(
          `UPDATE pagamentos 
           SET status = 'inativo' 
           WHERE usuario_id = $1 AND plano_id = $2 AND status = 'pago'`,
          [usuario_id, usuario.plano_atual_id]
        );
        
        console.log("✅ Plano anterior marcado como inativo");
      }

      await client.query('COMMIT');

      console.log("✅✅✅ PAGAMENTO SALVO E PLANO ATUALIZADO COM SUCESSO! ✅✅✅");
      console.log("   📋 ID Pagamento:", assinaturaSalva.id);
      console.log("   👤 Usuario ID:", assinaturaSalva.usuario_id);
      console.log("   📋 Plano ID:", assinaturaSalva.plano_id);
      console.log("   📊 Status:", assinaturaSalva.status);
      
      res.status(201).json({
        success: true,
        data: {
          pagamento: assinaturaSalva,
          usuario: usuarioAtualizado,
          plano: plano
        },
        message: "Pagamento realizado e plano atualizado com sucesso"
      });

    } catch (err) {
      await client.query('ROLLBACK');
      
      // ✅ TRATAMENTO ESPECÍFICO PARA ERRO DE CONSTRAINT
      if (err.message.includes('viola a restrição de verificação')) {
        console.error('❌ ERRO DE CONSTRAINT - Status inválido:', err.message);
        return res.status(400).json({
          success: false,
          error: err.message,
          message: "Status de pagamento inválido. Contate o suporte."
        });
      }
      
      throw err;
    } finally {
      client.release();
    }

  } catch (err) {
    console.error("❌ ERRO AO SALVAR PAGAMENTO:", err);
    res.status(500).json({ 
      success: false,
      error: err.message,
      message: "Erro interno ao salvar pagamento"
    });
  }
});

// ---------- BUSCAR ÚLTIMO PAGAMENTO PAGO (CORRIGIDA) ----------
router.get("/ultimo-pago/:usuarioId", async (req, res) => {
  try {
    const { usuarioId } = req.params;
    
    console.log("🔍 Buscando último pagamento pago do usuário:", usuarioId);

    const result = await pool.query(
      `SELECT 
        p.id,
        p.usuario_id,
        p.plano_id,
        p.status,
        p.data_pagamento,
        p.data_vencimento,
        pl.nome as nome_plano,
        pl.preco
        -- REMOVIDO: pl.periodo (não existe na tabela)
       FROM pagamentos p
       LEFT JOIN planos pl ON p.plano_id = pl.id
       WHERE p.usuario_id = $1 
       AND p.status IN ('pago', 'active')
       ORDER BY p.data_pagamento DESC
       LIMIT 1`,
      [usuarioId]
    );

    if (result.rows.length > 0) {
      const pagamento = result.rows[0];
      console.log("✅ Último pagamento encontrado:", pagamento.nome_plano);
      
      res.json({
        id: pagamento.id,
        usuario_id: pagamento.usuario_id,
        plano_id: pagamento.plano_id,
        status: pagamento.status,
        nome_plano: pagamento.nome_plano,
        preco: pagamento.preco,
        // REMOVIDO: periodo
        data_pagamento: pagamento.data_pagamento,
        data_vencimento: pagamento.data_vencimento
      });
    } else {
      console.log("📭 Nenhum pagamento encontrado para o usuário");
      
      // 🔄 TENTAR BUSCAR PLANO ATUAL DO USUÁRIO COMO FALLBACK
      const usuarioResult = await pool.query(
        `SELECT 
          u.plano_atual_id,
          pl.nome as plano_nome
         FROM usuarios u
         LEFT JOIN planos pl ON u.plano_atual_id = pl.id
         WHERE u.id = $1`,
        [usuarioId]
      );

      if (usuarioResult.rows.length > 0 && usuarioResult.rows[0].plano_atual_id) {
        const usuario = usuarioResult.rows[0];
        console.log("🔄 Usando plano atual do usuário como fallback:", usuario.plano_nome);
        
        res.json({
          nome_plano: usuario.plano_nome || "Sem plano",
          status: "active"
        });
      } else {
        res.json({
          nome_plano: "Sem plano",
          status: "sem_plano"
        });
      }
    }
  } catch (err) {
    console.error("❌ Erro ao buscar último pagamento:", err);
    res.status(500).json({ 
      message: "Erro interno ao buscar pagamento",
      error: err.message 
    });
  }
});

// ---------- CRIAR COBRANÇA PIX ----------
router.post("/criar-cobranca-pix", async (req, res) => {
  try {
    const { customerId, value } = req.body;

    console.log("💰 Criando cobrança PIX:", { customerId, value });

    // Simular PIX pois pode não estar disponível no sandbox
    const cobrancaPix = {
      id: `pix_${Date.now()}`,
      status: "PENDING", 
      value: parseFloat(value),
      billingType: "PIX",
      dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      pixQrCode: "00020101021226930014br.gov.bcb.pix2561qrcode.asaas.com/qr/mock/pix_simulado_1234567895204000053039865405130.005802BR5913Loja Teste6008Sao Paulo62070503***6304",
      pixPayload: "00020126930014br.gov.bcb.pix2561qrcode.asaas.com/qr/mock/pix_simulado_1234567895204000053039865405130.005802BR5913Loja Teste6008Sao Paulo62070503***6304",
      encodedImage: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    };

    res.json({
      success: true,
      cobranca: cobrancaPix,
      message: "Pagamento PIX criado com sucesso"
    });

  } catch (error) {
    console.error("❌ Erro ao criar cobrança PIX:", error.message);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// ---------- ROTAS COMPATIBILIDADE ASAAS ----------
router.post("/asaas/criar-cliente", async (req, res) => {
  try {
    const { nome, email, cpfCnpj } = req.body;

    console.log("👤 Criando cliente via rota /asaas/criar-cliente:", { nome, email, cpfCnpj });

    const cliente = await asaas.criarCliente({
      name: nome,
      email: email,
      cpfCnpj: cpfCnpj.replace(/\D/g, '')
    });

    res.json({
      success: true,
      cliente: {
        id: cliente.id,
        name: cliente.name,
        email: cliente.email
      }
    });

  } catch (error) {
    console.error("❌ Erro em /asaas/criar-cliente:", error.message);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

router.post("/asaas/criar-cobranca-cartao", async (req, res) => {
  try {
    const cobranca = await asaas.criarPagamentoCartao(req.body);
    
    res.json({
      success: true,
      cobranca: {
        id: cobranca.id,
        status: cobranca.status,
        value: cobranca.value
      }
    });

  } catch (error) {
    console.error("❌ Erro em /asaas/criar-cobranca-cartao:", error.message);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

router.post("/asaas/criar-cobranca-pix", async (req, res) => {
  try {
    // Simular PIX
    const cobrancaPix = {
      id: `pix_${Date.now()}`,
      status: "PENDING", 
      value: req.body.value,
      billingType: "PIX",
      pixQrCode: "00020101021226930014br.gov.bcb.pix2561qrcode.asaas.com/qr/mock/pix_simulado",
      pixPayload: "00020126930014br.gov.bcb.pix2561qrcode.asaas.com/qr/mock/pix_simulado"
    };

    res.json({
      success: true,
      cobranca: cobrancaPix
    });

  } catch (error) {
    console.error("❌ Erro em /asaas/criar-cobranca-pix:", error.message);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// ---------- DEBUG: VER TODOS OS PAGAMENTOS ----------
router.get("/debug/todos", async (req, res) => {
  try {
    console.log("🐛 DEBUG: Buscando TODOS os pagamentos...");
    
    const result = await pool.query(`
      SELECT 
        p.id,
        p.usuario_id,
        p.plano_id,
        p.status,
        p.data_pagamento,
        p.data_vencimento,
        p.asaas_payment_id,
        p.data_criacao,
        u.nome as usuario_nome,
        u.email as usuario_email,
        pl.nome as plano_nome,
        pl.preco as plano_preco
      FROM pagamentos p
      LEFT JOIN usuarios u ON p.usuario_id = u.id
      LEFT JOIN planos pl ON p.plano_id = pl.id
      ORDER BY p.id DESC
      LIMIT 20
    `);

    console.log(`📋 Encontrados ${result.rows.length} pagamentos`);
    
    // Log detalhado de cada pagamento
    result.rows.forEach(pagamento => {
      console.log(`   → ID: ${pagamento.id}, Usuário: ${pagamento.usuario_nome} (${pagamento.usuario_id}), Plano: ${pagamento.plano_nome}, Status: ${pagamento.status}`);
    });
    
    res.json({
      success: true,
      count: result.rows.length,
      pagamentos: result.rows
    });

  } catch (error) {
    console.error("❌ Erro no debug:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ---------- ROTAS ADICIONAIS (MANTIDAS PARA COMPATIBILIDADE) ----------

// Buscar TODOS os pagamentos
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM pagamentos");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Buscar pagamentos por usuário
router.get("/usuario/:usuario_id", async (req, res) => {
  const { usuario_id } = req.params;
  try {
    const result = await pool.query(
      "SELECT * FROM pagamentos WHERE usuario_id = $1",
      [usuario_id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Atualizar status do pagamento
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    const result = await pool.query(
      "UPDATE pagamentos SET status = $1 WHERE id = $2 RETURNING *",
      [status, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;