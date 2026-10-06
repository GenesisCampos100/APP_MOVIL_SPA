const app = require('./src/app');

const PORT = 3000;

app.get("/", (req, res) => {
    res.send("API de AuraSpa funcionando correctamente");
});

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});