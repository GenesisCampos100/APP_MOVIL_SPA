const {
    initializeApp,
    cert,
    getApps
} = require('firebase-admin/app');

const fs = require('fs');
const path = require('path');

// Railway: credenciales privadas en una variable de entorno.
// Desarrollo local: seguir usando el JSON privado existente.
const credencialesBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64?.trim();
let serviceAccount;

if (credencialesBase64) {
    try {
        const json = Buffer.from(credencialesBase64, 'base64').toString('utf8');
        serviceAccount = JSON.parse(json);
    } catch (error) {
        throw new Error('FIREBASE_SERVICE_ACCOUNT_BASE64 no contiene un JSON valido.');
    }
} else {
    const archivoLocal = path.join(
        __dirname,
        '../../credentials/firebase-service-account.json'
    );

    if (!fs.existsSync(archivoLocal)) {
        throw new Error(
            'Faltan credenciales Firebase. Configura FIREBASE_SERVICE_ACCOUNT_BASE64 ' +
            'o coloca el archivo privado en credentials/firebase-service-account.json.'
        );
    }

    serviceAccount = JSON.parse(fs.readFileSync(archivoLocal, 'utf8'));
}

// Mantener una sola instancia del Admin SDK.
const firebaseApp = getApps().length
    ? getApps()[0]
    : initializeApp({ credential: cert(serviceAccount) });

console.log('Firebase Admin SDK conectado correctamente.');

module.exports = firebaseApp;
