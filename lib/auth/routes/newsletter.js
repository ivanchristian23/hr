// routes/newsletter.js
const express = require('express');
const router = express.Router();
const db = require('../db'); // your MySQL connection pool

// Get all newsletter images
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT id, title, description, image_url FROM newsletter ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add a new newsletter image (admin only)
router.post('/', async (req, res) => {
  const { title, description, image_url } = req.body;
  if (!image_url) return res.status(400).json({ message: 'Image URL is required' });

  try {
    const [result] = await db.query(
      'INSERT INTO newsletter (title, description, image_url) VALUES (?, ?, ?)',
      [title, description, image_url]
    );
    res.status(201).json({ message: 'Newsletter item added', id: result.insertId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
