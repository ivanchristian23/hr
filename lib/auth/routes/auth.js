const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { secretKey } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/register', async (req, res) => {
  const {
    first_name, last_name, email, password,
    date_of_join, line_manager_id, job_title, user_type
  } = req.body;

  try {
    const [existing] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (existing.length > 0)
      return res.status(400).json({ message: 'Email already registered' });

    const [managerRows] = await db.query('SELECT name FROM line_managers WHERE manager_id = ?', [line_manager_id]);
    if (managerRows.length === 0)
      return res.status(400).json({ message: 'Invalid line manager ID' });

    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await db.query(
      `INSERT INTO users
      (first_name, last_name, email, password, date_of_joining, line_manager_id, line_manager, job_title, user_type)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [first_name, last_name, email, hashedPassword, date_of_join, line_manager_id, managerRows[0].name, job_title, user_type]
    );

    const userId = result.insertId;
    const allowedLeave = user_type === 'Head Office Employee' ? 30 : 14;

    await db.query(
      `INSERT INTO user_leaves 
      (user_id, allowed_leave, consumed_annual_leave, sick_leave_balance, consumed_sick_leave, compassionate_leave_consumed, maternity_leaves_consumed, balance, created_at, updated_at)
      VALUES (?, ?, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW())`,
      [userId, allowedLeave]
    );

    res.json({ success: true, message: 'User registered and leave record created' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [result] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (result.length === 0) return res.status(401).json({ message: 'Invalid credentials' });

    const user = result[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, role: user.role }, secretKey, { expiresIn: '1h' });
    res.json({ success: true, token, role: user.role });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
