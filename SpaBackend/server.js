
require('dotenv').config();

const app = require('./src/app');

const PORT = process.env.PORT || 3000;

// Ruta principal para comprobar que el servidor funciona.
app.get('/', (req, res) => {
    res.send('API de AuraSpa funcionando correctamente');
});

// Iniciar el backend compartido.
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor ejecutándose en el puerto ${PORT}`);
});
