
require('dotenv').config();

const app = require('./src/app');

const PORT = process.env.PORT || 3000;

const supabase = require('./src/config/supabase');

async function probarStorage() {
    const { data, error } = await supabase.storage.listBuckets();

    if (error) {
        console.error('Error conectando con Supabase Storage:', error.message);
        return;
    }

    console.log(
        'Buckets disponibles:',
        data.map(bucket => bucket.name)
    );
}

probarStorage();

// Ruta principal para comprobar que el servidor funciona.
app.get('/', (req, res) => {
    res.send('API de AuraSpa funcionando correctamente');
});

// Iniciar el backend compartido.
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor ejecutándose en el puerto ${PORT}`);
});
