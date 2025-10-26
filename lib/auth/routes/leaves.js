const express = require('express');
const db = require('../db');
const router = express.Router();
const { authenticateToken } = require('../middleware/authMiddleware'); // path to middleware file
const multer = require('multer');
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });
const transporter = require('../config/mailer');
// User My Leaves Home Page
router.get('/user/leaves', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT 
      start_date, 
      end_date, 
      leave_type, 
      status, 
      balance
    FROM leave_master
    WHERE user_id = ?
    ORDER BY start_date DESC
  `;

  try {
    const [results] = await db.query(sql, [userId]);
    res.json(results);
  } catch (err) {
    console.error("SQL error:", err);
    res.status(500).send("Server error");
  }
});
// create leave
router.post('/createleaves', upload.single('attachment'), async (req, res) => {
  const {
    user_id,
    line_manager_id,
    start_date,
    end_date,
    leave_type,
    count,
    details,
    status
  } = req.body;

  // File buffer (null if no file uploaded)
  const attachmentBuffer = req.file ? req.file.buffer : null;

  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();

    // 1️⃣ Check if same date range exists
    const [existing] = await connection.query(
      `SELECT id FROM leave_master 
       WHERE user_id = ? 
       AND start_date = ? 
       AND end_date = ?`,
      [user_id, start_date, end_date]
    );

    if (existing.length > 0) {
      await connection.rollback();
      return res.status(400).json({ message: "Leave for these dates already exists" });
    }

    // 2️⃣ Get current leave balances
    const [rows] = await connection.query(
      `SELECT balance, consumed_annual_leave, sick_leave_balance, consumed_sick_leave,
              compassionate_leave_consumed, maternity_leaves_consumed
       FROM user_leaves
       WHERE user_id = ?`,
      [user_id]
    );

    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: "Leave balances not found" });
    }

    let {
      balance,
      consumed_annual_leave,
      sick_leave_balance,
      consumed_sick_leave,
      compassionate_leave_consumed,
      maternity_leaves_consumed
    } = rows[0];

    // 3️⃣ Deduct leave balance
    if (leave_type === "Annual Leave") {
      if (balance < count) {
        await connection.rollback();
        return res.status(400).json({ message: "Not enough annual leave balance" });
      }
      balance -= count;
      consumed_annual_leave += count;
    } else if (leave_type === "Sick Leave") {
      if (sick_leave_balance < count) {
        await connection.rollback();
        return res.status(400).json({ message: "Not enough sick leave balance" });
      }
      sick_leave_balance -= count;
      consumed_sick_leave += count;
    } else if (leave_type === "Compassionate Leave") {
      compassionate_leave_consumed += count;
    } else if (leave_type === "Maternity Leave") {
      maternity_leaves_consumed += count;
    }

    // 4️⃣ Update balances
    await connection.query(
      `UPDATE user_leaves
       SET balance = ?, consumed_annual_leave = ?, sick_leave_balance = ?, consumed_sick_leave = ?,
           compassionate_leave_consumed = ?, maternity_leaves_consumed = ?
       WHERE user_id = ?`,
      [
        balance,
        consumed_annual_leave,
        sick_leave_balance,
        consumed_sick_leave,
        compassionate_leave_consumed,
        maternity_leaves_consumed,
        user_id
      ]
    );

    // Determine balance snapshot
    let remainingBalance;
    if (leave_type === "Annual Leave") {
      remainingBalance = balance;
    } else if (leave_type === "Sick Leave") {
      remainingBalance = sick_leave_balance;
    } else {
      remainingBalance = 0;
    }

    // 5️⃣ Insert leave request with attachment BLOB
    await connection.query(
      `INSERT INTO leave_master
      (user_id, start_date, end_date, line_manager_id, leave_type, count, user_details, status, balance, attachment, attachment_filename, attachment_mimetype, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        user_id,
        start_date,
        end_date,
        line_manager_id,
        leave_type,
        count,
        details || null,
        status || "Pending",
        remainingBalance,
        attachmentBuffer,
        req.file ? req.file.originalname : null, // store filename
        req.file ? req.file.mimetype : null      // store mimetype
      ]
    );


    await connection.commit();

    // 🔹 Fetch emails of user and line manager
    const [userRows] = await connection.query(
      `SELECT first_name, last_name, email FROM users WHERE id = ?`,
      [user_id]
    );
    const [managerRows] = await connection.query(
      `SELECT first_name, last_name, email FROM users WHERE id = ?`,
      [line_manager_id]
    );

    const user = userRows[0];
    const manager = managerRows[0];

    // Fallback if not found
    const userEmail = user?.email || null;
    const managerEmail = manager?.email || null;
    const userName = user ? `${user.first_name} ${user.last_name}` : 'Unknown User';
    const managerName = manager ? `${manager.first_name} ${manager.last_name}` : 'Unknown Manager';

    // 🔹 Email body content
    const emailBody = `
  <h3>New Leave Request Submitted</h3>
  <p><strong>Requested by:</strong> ${userName}</p>
  <p><strong>Leave Type:</strong> ${leave_type}</p>
  <p><strong>Duration:</strong> ${start_date} to ${end_date}</p>
  <p><strong>Count:</strong> ${count} days</p>
  <p><strong>Details:</strong> ${details || 'N/A'}</p>
  <p><strong>Status:</strong> ${status || 'Pending'}</p>
`;

    // 🔹 Send email to requester
    if (userEmail) {
      await transporter.sendMail({
        from: '"HR Leave System" <iventura@proztec.com>',
        to: userEmail,
        subject: 'Your Leave Request Has Been Submitted',
        html: `
      <p>Dear ${userName},</p>
      <p>Your leave request has been successfully submitted for approval.</p>
      ${emailBody}
      <p>Thank you.</p>
    `,
      });
    }

    // 🔹 Send email to line manager
    if (managerEmail) {
      await transporter.sendMail({
        from: '"HR Leave System" <iventura@proztec.com>',
        to: managerEmail,
        cc: ['hr@proztec.com', userEmail],
        subject: `New Leave Request from ${userName}`,
        html: `
      <p>Dear ${managerName},</p>
      <p>You have a new leave request awaiting your review:</p>
      ${emailBody}
      <p>Please log in to approve or reject the request.</p>
    `,
      });
    }

    res.status(201).json({ success: true, message: 'Leave created successfully and email sent' });

  } catch (err) {
    await connection.rollback();
    console.error("SQL error:", err);
    res.status(500).json({ success: false, message: 'Server error' });
  } finally {
    connection.release();
  }
});
// approve or reject leave
router.put('/:id', authenticateToken, async (req, res) => {
  const connection = await db.getConnection(); // get transaction connection
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['routerroved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: "Invalid status" });
    }

    await connection.beginTransaction();

    // 1. Fetch leave details
    const [leaveRows] = await connection.execute(
      "SELECT user_id, leave_type, count, balance FROM leave_master WHERE id = ?",
      [id]
    );

    if (leaveRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: "Leave not found" });
    }

    const leave = leaveRows[0];
    const { user_id, leave_type, count } = leave;
    let newBalance = leave.balance;
    console.log(count);

    // 2. If rejected, update user_leaves first
    if (status === 'rejected') {
      if (leave_type === 'Annual Leave') {
        await connection.execute(
          `UPDATE user_leaves 
           SET balance = balance + ?, 
               consumed_annual_leave = consumed_annual_leave - ? 
           WHERE user_id = ?`,
          [count, count, user_id]
        );
        newBalance = (parseFloat(newBalance) + parseFloat(count)).toFixed(2); // reflect in leave_master
      }
      else if (leave_type === 'Sick Leave') {
        await connection.execute(
          `UPDATE user_leaves 
           SET sick_leave_balance = sick_leave_balance + ?, 
               consumed_sick_leave = consumed_sick_leave - ? 
           WHERE user_id = ?`,
          [count, count, user_id]
        );
        newBalance = (parseFloat(newBalance) + parseFloat(count)).toFixed(2);
      }
      else if (leave_type === 'Compassionate Leave') {
        await connection.execute(
          `UPDATE user_leaves 
           SET compassionate_leave_consumed = compassionate_leave_consumed - ? 
           WHERE user_id = ?`,
          [count, user_id]
        );
        // No "balance" in user_leaves for this leave type
      }
      else if (leave_type === 'Maternity Leave') {
        await connection.execute(
          `UPDATE user_leaves 
           SET maternity_leaves_consumed = maternity_leaves_consumed - ? 
           WHERE user_id = ?`,
          [count, user_id]
        );
      }
    }
    console.log(newBalance);
    // 3. Update leave_master with status + updated balance
    await connection.execute(
      "UPDATE leave_master SET status = ?, balance = ? WHERE id = ?",
      [status, newBalance, id]
    );

    await connection.commit();

    // 🔹 Fetch user info
    const [userRows] = await connection.query(
      `SELECT first_name, last_name, email, line_manager_id FROM users WHERE id = ?`,
      [leave.user_id]
    );

    if (userRows.length > 0) {
      const user = userRows[0];
      const userName = `${user.first_name} ${user.last_name}`;
      const lineManagerId = user?.line_manager_id || null
      // fetch manager email
      const [managerRows] = await connection.query(
        `SELECT first_name, last_name, email FROM users WHERE id = ?`,
        [lineManagerId]
      );
      const manager = managerRows[0];
      const managerEmail = manager?.email || null;
      
      // Send status update email
      await transporter.sendMail({
        from: '"Prozte Support" <iventura@proztec.com>',
        to: user.email,
        cc: ['hr@proztec.com', managerEmail],
        subject: `Your Leave Request Has Been ${status.charAt(0).toUpperCase() + status.slice(1)}`,
        html: `
      <p>Dear ${userName},</p>
      <p>Your leave request has been <strong>${status}</strong>.</p>
      <p><strong>Leave Type:</strong> ${leave.leave_type}</p>
      <p><strong>Days:</strong> ${leave.count}</p>
      <p><strong>Updated Balance:</strong> ${newBalance}</p>
      <p>Thank you.</p>
    `,
      });
    }

    res.json({ message: `Leave ${status} successfully`, updatedBalance: newBalance });

  } catch (err) {
    await connection.rollback();
    console.error("Error updating leave status:", err);
    res.status(500).send("Server error");
  } finally {
    connection.release();
  }
});
// retrieve attachment
router.get('/:id/attachment', authenticateToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT attachment, attachment_filename, attachment_mimetype FROM leave_master WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0 || !rows[0].attachment) {
      return res.status(404).send('No attachment found');
    }

    res.setHeader('Content-Type', rows[0].attachment_mimetype || 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${rows[0].attachment_filename || 'attachment.bin'}"`);
    res.send(rows[0].attachment);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error retrieving attachment');
  }
});

module.exports = router;