const express = require('express');
const db = require('../db');
const router = express.Router();
const {authenticateToken} = require('../middleware/authMiddleware'); // path to middleware file

// Home Page User Details
router.get('/user/home', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT 
      u.first_name, 
      u.last_name, 
      u.job_title, 
      u.date_of_joining, 
      u.line_manager,
      l.allowed_leave,
      l.consumed_annual_leave,
      l.sick_leave_balance,
      l.consumed_sick_leave,
      l.compassionate_leave_consumed,
      l.balance
    FROM users u
    LEFT JOIN user_leaves l ON u.id = l.user_id
    WHERE u.id = ?
  `;

  try {
    const [results] = await db.query(sql, [userId]);

    if (results.length === 0) {
      console.log("No user found for ID:", userId);
      return res.status(404).send("User not found");
    }

    res.json(results[0]);
  } catch (err) {
    console.error("SQL error:", err);
    res.status(500).send("Server error");
  }
});
// Get User ID
router.get('/user/id', authenticateToken, (req, res) => {
  res.json({ id: req.user.id });
});

//Get line manager for user
router.get('/user/line-manager/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const [rows] = await db.query(
      "SELECT line_manager_id FROM users WHERE id = ?",
      [userId]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json({ line_manager_id: rows[0].line_manager_id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});
//get leave balance
router.get('/user/leave-balances', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(
      `SELECT balance, consumed_annual_leave, sick_leave_balance, consumed_sick_leave,
              compassionate_leave_consumed, maternity_leaves_consumed
       FROM user_leaves
       WHERE user_id = ?`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Leave balances not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error("SQL error:", err);
    res.status(500).json({ message: "Server error" });
  }
});
//get user name
router.get('/user/name/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.execute(
      "SELECT CONCAT(first_name, ' ', last_name) AS name FROM users WHERE id = ?",
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ name: rows[0].name });
  } catch (err) {
    console.error("Error fetching user name:", err);
    res.status(500).send("Server error");
  }
});

// Get all users (for manager dropdown)
router.get('/linemanagerDropdown', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, CONCAT(first_name, " ", last_name) AS name FROM users'
    );
    console.log(res.json(rows));
    res.json(rows);
  } catch (err) {
    console.error("Error fetching users:", err);
    res.status(500).json({ message: "Server error" });
  }
});
//get all employees
router.get('/userslist', async (req, res) => {
  const [rows] = await db.query(
    'SELECT id, first_name, last_name, job_title FROM users'
  );
  res.json(rows);
});

//get all user details from users table and user leaves
router.get('/userslist/:id', async (req, res) => {
  const userId = req.params.id;

  const [userRows] = await db.query(
    'SELECT id, first_name, last_name, line_manager, job_title, date_of_joining,user_type FROM users WHERE id = ?',
    [userId]
  );

  const [leaveRows] = await db.query(
    'SELECT allowed_leave, consumed_annual_leave, sick_leave_balance, consumed_sick_leave, compassionate_leave_consumed, maternity_leaves_consumed, balance FROM user_leaves WHERE user_id = ?',
    [userId]
  );

  res.json({
    ...userRows[0],
    leaves: leaveRows[0]
  });
});
// Update personal info
router.put('/edit_user_info/:id', async (req, res) => {
  const { id } = req.params;
  const { job_title, line_manager, user_type } = req.body;

  try {
    await db.query(
      'UPDATE users SET job_title = ?, line_manager = ?, user_type = ? WHERE id = ?',
      [job_title, line_manager, user_type, id]
    );
    res.json({ success: true, message: 'Personal info updated' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Database error' });
  }
});

// Update leave info + insert into audit log
router.put('/edit_user_leave/:id', async (req, res) => {
  const { id } = req.params;
  const {
    allowed_leave,
    consumed_annual_leave,
    sick_leave_balance,
    consumed_sick_leave,
    compassionate_leave_consumed,
    maternity_leaves_consumed,
    balance
  } = req.body;

  const connection = await db.getConnection(); // ensure transaction safety

  try {
    await connection.beginTransaction();

    // 1️⃣ Update the main user_leaves table
    await connection.query(
      `UPDATE user_leaves 
       SET allowed_leave=?, consumed_annual_leave=?, sick_leave_balance=?, 
           consumed_sick_leave=?, compassionate_leave_consumed=?, 
           maternity_leaves_consumed=?, balance=?, updated_at=NOW() 
       WHERE user_id=?`,
      [
        allowed_leave,
        consumed_annual_leave,
        sick_leave_balance,
        consumed_sick_leave,
        compassionate_leave_consumed,
        maternity_leaves_consumed,
        balance,
        id
      ]
    );

    // 2️⃣ Insert an audit record
    await connection.query(
      `INSERT INTO user_leave_audit (
          user_id,
          allowed_leave,
          consumed_annual_leave,
          sick_leave_balance,
          consumed_sick_leave,
          compassionate_leave_consumed,
          maternity_leaves_consumed,
          balance,
          created_at,
          updated_at
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        id,
        allowed_leave,
        consumed_annual_leave,
        sick_leave_balance,
        consumed_sick_leave,
        compassionate_leave_consumed,
        maternity_leaves_consumed,
        balance
      ]
    );

    await connection.commit();
    res.json({ success: true, message: 'Leave info updated and audit logged' });

  } catch (err) {
    await connection.rollback();
    console.error('Error updating leave info:', err);
    res.status(500).json({ message: 'Database error' });
  } finally {
    connection.release();
  }
});


// Get leave audit for a specific user
router.get('/user_leave_audit/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT 
          allowed_leave,
          consumed_annual_leave,
          sick_leave_balance,
          consumed_sick_leave,
          compassionate_leave_consumed,
          maternity_leaves_consumed,
          balance,
          created_at,
          updated_at
       FROM user_leave_audit
       WHERE user_id = ?
       ORDER BY created_at DESC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error('Error fetching user leave audit:', err);
    res.status(500).json({ message: 'Failed to fetch leave audit' });
  }
});



module.exports = router;