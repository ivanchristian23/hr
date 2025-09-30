const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const cors = require('cors');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const multer = require('multer');

const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Database connection
const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'hr_app',
  timezone: 'Z',
});

// db.connect(err => {
//   if (err) throw err;
//   console.log('MySQL Connected...');
// });
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'ivanvents@gmail.com',         // replace with your email
    pass: 'mlqx yxgg cumc gcqj',      // use App Password if 2FA enabled
  },
});
transporter.verify((error, success) => {
  if (error) {
    console.log('Error:', error);
  } else {
    console.log('Server is ready to send emails');
  }
});
//Reset Password Functionality
// Generate secure random 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Clean expired OTPs every hour (optional, can run as cron job)
async function cleanExpiredOtps() {
  await db.query('DELETE FROM password_otps WHERE expires_at < NOW()');
}
setInterval(cleanExpiredOtps, 60 * 60 * 1000);

// 1. Request OTP
app.post('/send-otp', async (req, res) => {
  const { email } = req.body;

  try {
    // Check if user exists
    const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      // Don't reveal this info, send success anyway
      return res.json({ success: true, message: 'If email exists, OTP sent' });
    }

    // Generate OTP
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    // Save OTP in DB
    await db.query(
      'INSERT INTO password_otps (email, otp, expires_at, attempts) VALUES (?, ?, ?, 0) ON DUPLICATE KEY UPDATE otp=?, expires_at=?, attempts=0',
      [email, otp, expiresAt, otp, expiresAt]
    );

    // Send OTP via email
    await transporter.sendMail({
      to: email,
      subject: 'Your Password Reset OTP',
      html: `<p>Your OTP code is <b>${otp}</b>. It expires in 5 minutes.</p>`,
    });

    res.json({ success: true, message: 'OTP sent' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 2. Verify OTP
app.post('/verify-otp', async (req, res) => {
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

// 3. Reset Password (after OTP verification)
app.post('/reset-password', async (req, res) => {
  const { email, new_password } = req.body;

  try {
    // Hash new password
    const hashed = await bcrypt.hash(new_password, 10);

    // Update password
    const [result] = await db.query('UPDATE users SET password = ? WHERE email = ?', [hashed, email]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

const secretKey = 'ProztecSecret!@#';
// ✅ Register route
// ✅ Register route
app.post('/register', async (req, res) => {
  const {
    first_name,
    last_name,
    email,
    password,
    date_of_join,
    line_manager_id,
    job_title,
    user_type   // <-- new
  } = req.body;

  try {
    const [existing] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const [managerRows] = await db.query('SELECT name FROM line_managers WHERE manager_id = ?', [line_manager_id]);
    if (managerRows.length === 0) {
      return res.status(400).json({ message: 'Invalid line manager ID' });
    }
    const line_manager_name = managerRows[0].name;

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.query(
      `INSERT INTO users
      (first_name, last_name, email, password, date_of_joining, line_manager_id, line_manager, job_title, user_type)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [first_name, last_name, email, hashedPassword, date_of_join, line_manager_id, line_manager_name, job_title, user_type]
    );

    res.json({ success: true, message: 'User registered' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


//get managers
app.get('/line_managers', async (req, res) => {
  try {
    const [managers] = await db.query('SELECT manager_id,name FROM line_managers');
    res.json({ line_managers: managers });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});



// ✅ Login route
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  console.log(`Login attempt for email: ${email}`);

  try {
    const [result] = await db.query('SELECT * FROM users WHERE email = ?', [email]);

    if (result.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = result[0];
    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, role: user.role }, secretKey, { expiresIn: '1h' });

    res.json({ success: true, message: 'Login successful', role: user.role, token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

//Token Authentication
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, secretKey, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user; // user.id is available
    next();
  });
}

// Home Page User Details
app.get('/user/home', authenticateToken, async (req, res) => {
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
// User My Leaves Home Page
app.get('/user/leaves', authenticateToken, async (req, res) => {
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
// Get User ID
app.get('/user/id', authenticateToken, (req, res) => {
  res.json({ id: req.user.id });
});
app.get('/user/line-manager/:userId', async (req, res) => {
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

app.post('/leaves', upload.single('attachment'), async (req, res) => {
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
    res.status(201).json({ success: true, message: 'Leave created successfully' });

  } catch (err) {
    await connection.rollback();
    console.error("SQL error:", err);
    res.status(500).json({ success: false, message: 'Server error' });
  } finally {
    connection.release();
  }
});

app.get('/manager/requests', authenticateToken, async (req, res) => {
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



app.get('/user/leave-balances', authenticateToken, async (req, res) => {
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

app.get('/user/name/:id', authenticateToken, async (req, res) => {
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

app.put('/leaves/:id', authenticateToken, async (req, res) => {
  const connection = await db.getConnection(); // get transaction connection
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['approved', 'rejected'].includes(status)) {
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

    res.json({ message: `Leave ${status} successfully`, updatedBalance: newBalance });

  } catch (err) {
    await connection.rollback();
    console.error("Error updating leave status:", err);
    res.status(500).send("Server error");
  } finally {
    connection.release();
  }
});

app.get('/leaves/:id/attachment', authenticateToken, async (req, res) => {
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

// Get all users (for manager dropdown)
app.get('/users', async (req, res) => {
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

// Create line manager
app.post('/line-managers', async (req, res) => {
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

//get all employees
app.get('/userslist', async (req, res) => {
  const [rows] = await db.query(
    'SELECT id, first_name, last_name, job_title FROM users'
  );
  res.json(rows);
});

//get all user details from users table and user leaves
app.get('/userslist/:id', async (req, res) => {
  const userId = req.params.id;

  const [userRows] = await db.query(
    'SELECT id, first_name, last_name, line_manager, job_title, date_of_joining FROM users WHERE id = ?',
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



// ✅ Start server
app.listen(3000, () => {
  console.log('API server running on http://localhost:3000');
});
