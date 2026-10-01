const express = require("express");

const app = express();

const PORT = 3000;

app.get("/", (req, res) => {
    res.send("API de BookinSpa funcionando correctamente");
});

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});