const mysql = require('mysql2/promise');

const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'hr_app',
  timezone: 'Z',
});

module.exports = db;
