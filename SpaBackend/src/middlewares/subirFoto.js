
const multer = require('multer');

const almacenamiento = multer.memoryStorage();

const subir = multer({
    storage: almacenamiento,

    limits: {
        fileSize: 5 * 1024 * 1024,
        files: 1
    },

    fileFilter: (req, file, callback) => {
        const formatosPermitidos = [
            'image/jpeg',
            'image/png',
            'image/webp',
            'application/octet-stream'
        ];

        if (!formatosPermitidos.includes(file.mimetype)) {
            return callback(
                new Error('Solo se permiten imágenes JPG, PNG o WEBP')
            );
        }

        callback(null, true);
    }
});

const recibirFoto = (req, res, next) => {
    subir.single('foto')(req, res, (error) => {
        if (error instanceof multer.MulterError) {
            if (error.code === 'LIMIT_FILE_SIZE') {
                return res.status(413).json({
                    error: 'La fotografía no puede superar los 5 MB'
                });
            }

            return res.status(400).json({
                error: 'No se pudo recibir la fotografía'
            });
        }

        if (error) {
            return res.status(400).json({
                error: error.message
            });
        }

        next();
    });
};

module.exports = recibirFoto;
