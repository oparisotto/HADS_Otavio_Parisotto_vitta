const jwt = require("jsonwebtoken");

function authFuncionario(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ message: "Token não fornecido" });

  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, "SEGREDO_SUPER_SECRETO"); // usar variável de ambiente em produção
    if (decoded.tipo !== "funcionario") {
      return res.status(403).json({ message: "Acesso restrito a funcionários" });
    }
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Token inválido" });
  }
}

module.exports = authFuncionario;
