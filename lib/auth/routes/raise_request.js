const db = require('../db'); // Make sure this uses mysql2/promise
const transporter = require('../config/mailer');
const express = require('express');
const router = express.Router();

/**
 * 🔹 Create new Letter Request
 */
router.post("/letter-request", async (req, res) => {
  try {
    const { user_id, letter_type, description } = req.body;

    if (!user_id || !letter_type || !description) {
      return res.status(400).json({ message: "All fields are required" });
    }

    // Insert request
    const [insertResult] = await db.query(
      "INSERT INTO letter_request (user_id, letter_type, description) VALUES (?, ?, ?)",
      [user_id, letter_type, description]
    );

    const requestId = insertResult.insertId;

    // Fetch user info
    const [userResult] = await db.query(
      "SELECT first_name, last_name FROM users WHERE id = ?",
      [user_id]
    );

    const user = userResult[0];
    const fullName = user ? `${user.first_name} ${user.last_name}` : "Unknown User";

    // Prepare email
    const mailOptions = {
      from: '"Proztec Support" <iventura@proztec.com>',
      to: 'iventura@proztec.com', // ✅ multiple recipients ['hr@proztec.com', 'hr2@proztec.com']
      subject: 'New Letter Request Submitted',
      html: `
        <h3>New Letter Request</h3>
        <p><strong>Requested by:</strong> ${fullName} (User ID: ${user_id})</p>
        <p><strong>Letter Type:</strong> ${letter_type}</p>
        <p><strong>Description:</strong> ${description}</p>
        <p><strong>Request ID:</strong> ${requestId}</p>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Letter request email sent.");

    res.status(201).json({
      message: "Letter request submitted successfully and email sent.",
      id: requestId,
    });

  } catch (err) {
    console.error("❌ Error in /letter-request:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

/**
 * 🔹 Create new Reimbursement Request
 */
router.post("/reimbursement-request", async (req, res) => {
  try {
    const { user_id, amount, description } = req.body;

    if (!user_id || !amount || !description) {
      return res.status(400).json({ message: "All fields are required" });
    }

    // Insert request
    const [insertResult] = await db.query(
      "INSERT INTO reimbursement_request (user_id, amount, description) VALUES (?, ?, ?)",
      [user_id, amount, description]
    );

    const requestId = insertResult.insertId;

    // Fetch user info
    const [userResult] = await db.query(
      "SELECT first_name, last_name FROM users WHERE id = ?",
      [user_id]
    );

    const user = userResult[0];
    const fullName = user ? `${user.first_name} ${user.last_name}` : "Unknown User";

    // Prepare email
    const mailOptions = {
      from: '"Proztec Support" <iventura@proztec.com>',
      to: 'iventura@proztec.com', // ✅ add more recipients if needed['hr@proztec.com', 'finance@proztec.com']
      subject: 'New Reimbursement Request Submitted',
      html: `
        <h3>New Reimbursement Request</h3>
        <p><strong>Requested by:</strong> ${fullName} (User ID: ${user_id})</p>
        <p><strong>Amount:</strong> ${amount}</p>
        <p><strong>Description:</strong> ${description}</p>
        <p><strong>Request ID:</strong> ${requestId}</p>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Reimbursement request email sent.");

    res.status(201).json({
      message: "Reimbursement request submitted successfully and email sent.",
      id: requestId,
    });

  } catch (err) {
    console.error("❌ Error in /reimbursement-request:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

/**
 * 🔹 Fetch all Letter Requests (latest first) + User info
 */
router.get("/letter-request", async (req, res) => {
  try {
    const [results] = await db.query(`
      SELECT 
        lr.*, 
        u.first_name, 
        u.last_name 
      FROM letter_request lr
      JOIN users u ON lr.user_id = u.id
      ORDER BY lr.created_at DESC
    `);
    res.status(200).json(results);
  } catch (err) {
    console.error("❌ Error fetching letter requests:", err);
    res.status(500).json({ message: "Database error" });
  }
});

/**
 * 🔹 Fetch all Reimbursement Requests (latest first) + User info
 */
router.get("/reimbursement-request", async (req, res) => {
  try {
    const [results] = await db.query(`
      SELECT 
        rr.*, 
        u.first_name, 
        u.last_name 
      FROM reimbursement_request rr
      JOIN users u ON rr.user_id = u.id
      ORDER BY rr.created_at DESC
    `);
    res.status(200).json(results);
  } catch (err) {
    console.error("❌ Error fetching reimbursement requests:", err);
    res.status(500).json({ message: "Database error" });
  }
});

module.exports = router;
