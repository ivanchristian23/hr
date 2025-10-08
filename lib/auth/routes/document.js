const express = require('express');
const multer = require('multer');
const db = require('../db');
const router = express.Router();
const {authenticateToken} = require('../middleware/authMiddleware'); // path to middleware file

// List documents
router.get('/user_documents/:userId',authenticateToken, async (req, res) => {
  const [rows] = await db.query(
    'SELECT id, document_type, admin_only, created_at FROM user_documents WHERE user_id = ?',
    [req.params.userId]
  );
  res.json(rows);
});

// Upload document
const upload = multer(); // memory storage
router.post('/user_documents/:userId', upload.single('document'), async (req, res) => {
  const { document_type, admin_only } = req.body;
  const fileBuffer = req.file.buffer;

  await db.query(
    'INSERT INTO user_documents (user_id, document_type, document, admin_only, created_at, updated_at) VALUES (?, ?, ?, ?, NOW(), NOW())',
    [req.params.userId, document_type, fileBuffer, admin_only]
  );
  res.sendStatus(200);
});

// Download document
router.get('/user_documents/:id/download',authenticateToken, async (req, res) => {
  const [rows] = await db.query('SELECT document_type, document FROM user_documents WHERE id = ?', [req.params.id]);
  if (!rows.length) return res.status(404).send('Not found');

  const doc = rows[0];
  res.setHeader('Content-Disposition', `attachment; filename="${doc.document_type}.pdf"`);
  res.send(doc.document);
});

// ✅ Delete document
router.delete('/user_documents/:id',authenticateToken,async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM user_documents WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Document not found' });
    }

    await db.query('DELETE FROM user_documents WHERE id = ?', [req.params.id]);
    res.json({ message: 'Document deleted successfully' });
  } catch (error) {
    console.error('Error deleting document:', error);
    res.status(500).json({ message: 'Error deleting document', error: error.message });
  }
});


module.exports = router;