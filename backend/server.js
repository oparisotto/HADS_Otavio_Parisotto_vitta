const express = require("express");
const cors = require("cors");
const pool = require("./db");
const authRoutes = require("./routes/auth");
const planosRoutes = require("./routes/planos");
const pagamentosRoutes = require("./routes/pagamentos");
const checkinsRoutes = require("./routes/checkins");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());
app.use("/auth", authRoutes);
app.use("/planos", planosRoutes);
app.use("/pagamentos", pagamentosRoutes);
app.use("/checkins", checkinsRoutes);
app.get("/", (req, res) =>{
    res.send("API Vitta rodando 🚀")
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));

app.get("/usuarios", async (req, res) => {
    try{
        const result = await pool.query("SELECT * FROM usuarios");
        res.json(result.rows);
    } catch (err) {
        res.status(500).send(err.message);
    }
});