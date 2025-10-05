const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const db = require('../db');
const transporter = require('../config/mailer');

const router = express.Router();

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function cleanExpiredOtps() {
  await db.query('DELETE FROM password_otps WHERE expires_at < NOW()');
}
setInterval(cleanExpiredOtps, 60 * 60 * 1000);

// send OTP request
router.post('/send-otp', async (req, res) => {
  const { email } = req.body;
  try {
    const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) return res.json({ success: true, message: 'If email exists, OTP sent' });

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await db.query(
      'INSERT INTO password_otps (email, otp, expires_at, attempts) VALUES (?, ?, ?, 0) ON DUPLICATE KEY UPDATE otp=?, expires_at=?, attempts=0',
      [email, otp, expiresAt, otp, expiresAt]
    );

    await transporter.sendMail({
      to: email,
      subject: 'Password Reset OTP',
      html: `<p>Your OTP code is <b>${otp}</b>. It expires in 5 minutes.</p>`,
    });

    res.json({ success: true, message: 'OTP sent' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 2. Verify OTP
router.post('/verify-otp', async (req, res) => {
  const { email, otp } = req.body;

  try {
    const [rows] = await db.query('SELECT * FROM password_otps WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    const record = rows[0];

    // Check expiry
    if (new Date(record.expires_at) < new Date()) {
      return res.status(400).json({ success: false, message: 'OTP expired' });
    }

    // Check max attempts
    if (record.attempts >= 5) {
      return res.status(429).json({ success: false, message: 'Too many attempts, try again later' });
    }

    if (record.otp !== otp) {
      // Increment attempts
      await db.query('UPDATE password_otps SET attempts = attempts + 1 WHERE email = ?', [email]);
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    // OTP correct — delete OTP record to prevent reuse
    await db.query('DELETE FROM password_otps WHERE email = ?', [email]);

    res.json({ success: true, message: 'OTP verified' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
  const { email, new_password } = req.body;
  try {
    const hashed = await bcrypt.hash(new_password, 10);
    const [result] = await db.query('UPDATE users SET password = ? WHERE email = ?', [hashed, email]);
    if (result.affectedRows === 0)
      return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
