const axios = require('axios');

class AsaasAPI {
  constructor() {
    this.apiKey = '$aact_hmlg_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6OmI3NTE1NzA5LTg1MjUtNDgwZC1iOTBmLWVlZDIzYjU0MGQzMjo6JGFhY2hfYjk3NzYxNzktMmQ2YS00NzExLTlhNDQtZTFjODQyMTMzMWY5';
    this.baseURL = 'https://sandbox.asaas.com/api/v3';
    
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        'Content-Type': 'application/json',
        'access_token': this.apiKey
      },
      timeout: 10000
    });

    console.log('🔑 Configurado para Sandbox Asaas');
  }

  // ---------- CLIENTES ----------
  async criarCliente(dados) {
    try {
      const response = await this.client.post('/customers', dados);
      return response.data;
    } catch (error) {
      throw new Error(`Erro ao criar cliente: ${error.response?.data?.errors?.[0]?.description || error.message}`);
    }
  }

  async buscarClientePorEmail(email) {
    try {
      const response = await this.client.get(`/customers?email=${email}`);
      return response.data;
    } catch (error) {
      return { data: [] };
    }
  }

  // ---------- PAGAMENTOS ----------
  async criarPagamentoBoleto(dados) {
    try {
      console.log('📄 Criando boleto...');
      const response = await this.client.post('/payments', {
        ...dados,
        billingType: 'BOLETO',
        dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] // 5 dias
      });
      console.log('✅ Boleto criado:', response.data.id);
      return response.data;
    } catch (error) {
      throw new Error(`Erro ao criar boleto: ${error.response?.data?.errors?.[0]?.description || error.message}`);
    }
  }

  async criarPagamentoCartao(dados) {
    try {
      console.log('💳 Criando pagamento com cartão...');
      const response = await this.client.post('/payments', {
        ...dados,
        billingType: 'CREDIT_CARD',
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] // 3 dias
      });
      console.log('✅ Pagamento cartão criado:', response.data.id);
      return response.data;
    } catch (error) {
      console.error('❌ Erro detalhado cartão:', error.response?.data);
      throw new Error(`Erro ao criar pagamento cartão: ${error.response?.data?.errors?.[0]?.description || error.message}`);
    }
  }

  // Método para gerar link de pagamento (alternativa ao PIX)
  async criarLinkPagamento(dados) {
    try {
      console.log('🔗 Criando link de pagamento...');
      const response = await this.client.post('/paymentLinks', {
        ...dados,
        billingType: ['CREDIT_CARD', 'BOLETO'] // Aceita cartão e boleto
      });
      console.log('✅ Link de pagamento criado:', response.data.id);
      return response.data;
    } catch (error) {
      throw new Error(`Erro ao criar link: ${error.response?.data?.errors?.[0]?.description || error.message}`);
    }
  }

  async getQrCodePix(paymentId) {
    try {
      console.log('⚠️ PIX não disponível no sandbox');
      // Simular QR Code pois PIX não está disponível
      return {
        encodedImage: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
        payload: '00020101021226860014br.gov.bcb.pix2561qrcode.asaas.com/qr/mock/123456'
      };
    } catch (error) {
      throw new Error(`PIX não disponível: ${error.message}`);
    }
  }
}

module.exports = new AsaasAPI();