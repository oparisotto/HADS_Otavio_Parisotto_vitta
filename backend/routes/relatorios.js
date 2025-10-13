const express = require("express");
const router = express.Router();
const pool = require("../db");

// 🔹 RELATÓRIO DE CHECKINS - CORRIGIDO PARA DIA COMPLETO
router.get("/checkins", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`📊 Buscando checkins de ${inicio} 00:00:00 até ${fim} 23:59:59`);

    // CORREÇÃO: Usar BETWEEN com timestamps completos
    const result = await pool.query(
      `SELECT COUNT(*) as total 
       FROM checkins 
       WHERE data_checkin BETWEEN $1 AND $2`,
      [`${inicio} 00:00:00`, `${fim} 23:59:59`]
    );

    const total = parseInt(result.rows[0].total);
    console.log(`✅ Checkins encontrados: ${total}`);

    res.json({
      total_checkins: total,
    });
  } catch (err) {
    console.error("❌ Erro ao buscar relatório de checkins:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 RELATÓRIO FINANCEIRO - CORRIGIDO PARA DIA COMPLETO
router.get("/financeiro", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`💰 Buscando financeiro de ${inicio} 00:00:00 até ${fim} 23:59:59`);

    // CORREÇÃO: Usar BETWEEN com timestamps completos
    const result = await pool.query(
      `SELECT COALESCE(SUM(pl.preco), 0) as total_recebido
       FROM pagamentos p
       INNER JOIN planos pl ON p.plano_id = pl.id
       WHERE p.status = 'pago' 
       AND p.data_pagamento BETWEEN $1 AND $2`,
      [`${inicio} 00:00:00`, `${fim} 23:59:59`]
    );

    const total = parseFloat(result.rows[0].total_recebido);
    console.log(`✅ Faturamento encontrado: R$ ${total}`);

    res.json({
      total_recebido: total,
    });
  } catch (err) {
    console.error("❌ Erro ao buscar relatório financeiro:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 DADOS PARA GRÁFICO - EVOLUÇÃO DIÁRIA DE FATURAMENTO - CORRIGIDO
router.get("/grafico-financeiro", async (req, res) => {
  const { inicio, fim } = req.query;

  try {
    if (!inicio || !fim) {
      return res.status(400).json({ message: "Parâmetros 'inicio' e 'fim' são obrigatórios." });
    }

    console.log(`📈 Gráfico financeiro: ${inicio} 00:00:00 até ${fim} 23:59:59`);

    // CORREÇÃO: Agrupar por data completa mas usar BETWEEN para filtro
    const result = await pool.query(
      `SELECT 
        DATE(p.data_pagamento) AS dia,
        COALESCE(SUM(pl.preco), 0) AS valor
       FROM pagamentos p
       INNER JOIN planos pl ON p.plano_id = pl.id
       WHERE p.status = 'pago' 
       AND p.data_pagamento BETWEEN $1 AND $2
       GROUP BY DATE(p.data_pagamento)
       ORDER BY DATE(p.data_pagamento) ASC`,
      [`${inicio} 00:00:00`, `${fim} 23:59:59`]
    );

    console.log(`📊 Dados financeiro gráfico: ${result.rows.length} dias`);

    // Formata os dados para o gráfico
    const dadosFormatados = result.rows.map(item => ({
      dia: item.dia.toISOString().split('T')[0],
      valor: parseFloat(item.valor) || 0
    }));

    console.log("📈 Dados formatados:", dadosFormatados);
    res.json(dadosFormatados);
  } catch (err) {
    console.error("❌ Erro ao buscar dados financeiros do gráfico:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 ROTA DE DEBUG - Para testar os checkins com timestamps
router.get("/debug-checkins-completo", async (req, res) => {
  const { data } = req.query;
  const dataConsulta = data || new Date().toISOString().split('T')[0];
  
  try {
    console.log(`🔍 Debug checkins COMPLETO na data: ${dataConsulta}`);
    
    // Checkins usando BETWEEN com timestamps
    const checkinsBetween = await pool.query(
      `SELECT id, usuario_id, data_checkin 
       FROM checkins 
       WHERE data_checkin BETWEEN $1 AND $2
       ORDER BY data_checkin`,
      [`${dataConsulta} 00:00:00`, `${dataConsulta} 23:59:59`]
    );

    // Checkins usando DATE() (como estava antes)
    const checkinsDate = await pool.query(
      `SELECT id, usuario_id, data_checkin 
       FROM checkins 
       WHERE DATE(data_checkin) = $1
       ORDER BY data_checkin`,
      [dataConsulta]
    );

    res.json({
      data_consulta: dataConsulta,
      periodo: `${dataConsulta} 00:00:00 até ${dataConsulta} 23:59:59`,
      total_com_between: checkinsBetween.rows.length,
      checkins_com_between: checkinsBetween.rows,
      total_com_date: checkinsDate.rows.length,
      checkins_com_date: checkinsDate.rows,
      diferenca: checkinsBetween.rows.length - checkinsDate.rows.length
    });
  } catch (err) {
    console.error("Erro no debug:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 RELATÓRIO DE USUÁRIOS (mantido igual)
router.get("/usuarios", async (req, res) => {
  try {
    console.log("📊 Buscando relatório de usuários...");

    const totalUsuarios = await pool.query("SELECT COUNT(*) FROM usuarios");
    
    const usuariosComPlano = await pool.query(`
      SELECT COUNT(*) 
      FROM usuarios 
      WHERE plano_atual_id IS NOT NULL
      AND status = 'active'
    `);
    
    const usuariosSemPlano = await pool.query(`
      SELECT COUNT(*) 
      FROM usuarios 
      WHERE plano_atual_id IS NULL 
      OR status != 'active'
    `);

    const response = {
      total_usuarios: parseInt(totalUsuarios.rows[0].count),
      ativos: parseInt(usuariosComPlano.rows[0].count),
      inadimplentes: parseInt(usuariosSemPlano.rows[0].count),
    };

    console.log("✅ Relatório usuários:", response);
    res.json(response);
  } catch (err) {
    console.error("❌ Erro ao buscar relatório de usuários:", err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 RELATÓRIO DE PLANOS (mantido igual)
router.get("/planos", async (req, res) => {
  try {
    console.log("📊 Buscando relatório de planos...");
    
    const result = await pool.query("SELECT COUNT(*) FROM planos");
    const response = {
      total_planos: parseInt(result.rows[0].count),
    };

    console.log("✅ Relatório planos:", response);
    res.json(response);
  } catch (err) {
    console.error("❌ Erro ao buscar relatório de planos:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;