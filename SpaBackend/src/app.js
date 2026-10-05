const express = require('express');
const pool = require('./db');

const app = express();

app.use(express.json());

app.get('/api/servicios', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT *
            FROM servicios
        `);

        res.json(result.rows);

    } catch (error) {
        console.error('Error al obtener servicios:', error.message);

        res.status(500).json({
            error: 'Error al obtener los servicios'
        });
    }
});

module.exports = app;