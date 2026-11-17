
const {
    initializeApp,
    cert,
    getApps
} = require('firebase-admin/app');

const path = require('path');

// Cargar las credenciales privadas.
const serviceAccount = require(
    path.join(
        __dirname,
        '../../credentials/firebase-service-account.json'
    )
);

// Inicializar Firebase Admin una sola vez.
const firebaseApp = getApps().length
    ? getApps()[0]
    : initializeApp({
        credential: cert(serviceAccount)
    });

console.log('Firebase Admin SDK conectado correctamente.');

module.exports = firebaseApp;
