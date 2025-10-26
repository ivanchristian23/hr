const db = require('../db');
const transporter = require('../config/mailer');
const express = require('express');
const router = express.Router();

// Create new letter request
router.post("/letter-request", (req, res) => {
  const { user_id, letter_type, description } = req.body;

  if (!user_id || !letter_type || !description) {
    return res.status(400).json({ message: "All fields are required" });
  }

  const insertSql = "INSERT INTO letter_request (user_id, letter_type, description) VALUES (?, ?, ?)";
  db.query(insertSql, [user_id, letter_type, description], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }

    const requestId = result.insertId;

    // Fetch user's name
    const userSql = "SELECT first_name, last_name FROM users WHERE id = ?";
    db.query(userSql, [user_id], (userErr, userResult) => {
      if (userErr) {
        console.error(userErr);
        return res.status(500).json({ message: "Failed to fetch user info" });
      }

      const user = userResult[0];
      const fullName = user ? `${user.first_name} ${user.last_name}` : "Unknown User";

      // Email details
      const mailOptions = {
        from: '"Proztec Support" <iventura@proztec.com>',
        to: 'hr@proztec.com',
        subject: 'New Letter Request Submitted',
        html: `
          <h3>New Letter Request</h3>
          <p><strong>Requested by:</strong> ${fullName} (User ID: ${user_id})</p>
          <p><strong>Letter Type:</strong> ${letter_type}</p>
          <p><strong>Description:</strong> ${description}</p>
          <p><strong>Request ID:</strong> ${requestId}</p>
        `,
      };

      // Send email
      transporter.sendMail(mailOptions, (error, info) => {
        if (error) {
          console.error("Email sending failed:", error);
          return res.status(201).json({
            message: "Letter request submitted, but email failed to send.",
            id: requestId,
          });
        }

        console.log("✅ Email sent:", info.response);
        res.status(201).json({
          message: "Letter request submitted successfully and email sent.",
          id: requestId,
        });
      });
    });
  });
});


// Create new reimbursement request
router.post("/reimbursement-request", (req, res) => {
  const { user_id, amount, description } = req.body;

  if (!user_id || !amount || !description) {
    return res.status(400).json({ message: "All fields are required" });
  }

  const insertSql = "INSERT INTO reimbursement_request (user_id, amount, description) VALUES (?, ?, ?)";
  db.query(insertSql, [user_id, amount, description], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }

    const requestId = result.insertId;

    // Fetch user's name
    const userSql = "SELECT first_name, last_name FROM users WHERE id = ?";
    db.query(userSql, [user_id], (userErr, userResult) => {
      if (userErr) {
        console.error(userErr);
        return res.status(500).json({ message: "Failed to fetch user info" });
      }

      const user = userResult[0];
      const fullName = user ? `${user.first_name} ${user.last_name}` : "Unknown User";

      // Email details
      const mailOptions = {
        from: '"Proztec Support" <iventura@proztec.com>',
        to: 'hr@proztec.com',
        subject: 'New Reimbursement Request Submitted',
        html: `
          <h3>New Reimbursement Request</h3>
          <p><strong>Requested by:</strong> ${fullName} (User ID: ${user_id})</p>
          <p><strong>Amount:</strong> ${amount}</p>
          <p><strong>Description:</strong> ${description}</p>
          <p><strong>Request ID:</strong> ${requestId}</p>
        `,
      };

      // Send email
      transporter.sendMail(mailOptions, (error, info) => {
        if (error) {
          console.error("Email sending failed:", error);
          return res.status(201).json({
            message: "Reimbursement request submitted, but email failed to send.",
            id: requestId,
          });
        }

        console.log("✅ Email sent:", info.response);
        res.status(201).json({
          message: "Reimbursement request submitted successfully and email sent.",
          id: requestId,
        });
      });
    });
  });
});

// Fetch all letter requests (latest first)
router.get("/letter-request", (req, res) => {
  const sql = "SELECT * FROM letter_request ORDER BY created_at DESC";
  db.query(sql, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }
    res.status(200).json(results);
  });
});

// Fetch all reimbursement requests (latest first)
router.get("/reimbursement-request", (req, res) => {
  const sql = "SELECT * FROM reimbursement_request ORDER BY created_at DESC";
  db.query(sql, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }
    res.status(200).json(results);
  });
});


module.exports = router;