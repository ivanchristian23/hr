const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

const db = mysql.createConnection({
  host: 'localhost',
  user: 'your_mysql_user',
  password: 'your_mysql_password',
  database: 'your_database',
});

db.connect(err => {
  if (err) throw err;
  console.log('MySQL Connected...');
});

app.post('/register', async (req, res) => {
  const { first_name, last_name, email, password } = req.body;

  // Check if user already exists
  const checkSql = 'SELECT * FROM users WHERE email = ?';
  db.query(checkSql, [email], async (err, result) => {
    if (err) return res.status(500).json({ message: 'Server error' });

    if (result.length > 0) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    try {
      const hashedPassword = await bcrypt.hash(password, 10);
      const insertSql = `
        INSERT INTO users (first_name, last_name, email, password)
        VALUES (?, ?, ?, ?)
      `;
      db.query(
        insertSql,
        [first_name, last_name, email, hashedPassword],
        (err, result) => {
          if (err) return res.status(500).json({ message: 'Insert failed' });
          return res.json({ success: true, message: 'User registered' });
        }
      );
    } catch (error) {
      return res.status(500).json({ message: 'Hashing error' });
    }
  });
});

app.listen(3000, () => {
  console.log('Register API running on http://localhost:3000');
});
