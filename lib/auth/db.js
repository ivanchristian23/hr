const mysql = require('mysql2/promise');

const db = mysql.createPool({
  host: 'localhost',
  user: 'coolb8_proztec',
  password: '-Y?4zY=8I=Qt',
  database: 'coolb8_hr_app',
  timezone: 'Z',
});

module.exports = db;
