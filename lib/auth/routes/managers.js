const express = require('express');
const db = require('../db');
const router = express.Router();
const {authenticateToken} = require('../middleware/authMiddleware'); // path to middleware file

//get managers
router.get('/', async (req, res) => {
  try {
    const [managers] = await db.query('SELECT manager_id,name FROM line_managers');
    res.json({ line_managers: managers });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.get('/requests', authenticateToken, async (req, res) => {
  try {
    const managerId = req.user.id;
    // console.log("Manager ID:", managerId);

    const sql = `
      SELECT * FROM leave_master
      WHERE line_manager_id = ?
      ORDER BY start_date DESC
    `;

    const [results] = await db.execute(sql, [managerId]);

    // console.log("Leave requests for manager:", JSON.stringify(results, null, 2));
    res.json(results);
  } catch (err) {
    console.error("DB Error:", err);
    res.status(500).send("Server error");
  }
});
// Create line manager
router.post('/line-managers', async (req, res) => {
  const { manager_id, name, department } = req.body;

  if (!manager_id || !name || !department) {
    return res.status(400).json({ message: "All fields are required" });
  }

  try {
    await db.query(
      'INSERT INTO line_managers (manager_id, name, department) VALUES (?, ?, ?)',
      [manager_id, name, department]
    );
    res.json({ success: true, message: "Line Manager created successfully" });
  } catch (err) {
    console.error("Error creating line manager:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});



module.exports = router;
