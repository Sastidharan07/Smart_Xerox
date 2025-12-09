// server.js
// Xerox backend - Node.js + Express + SQLite + Multer + Razorpay (optional)
// Handles file uploads, order management, admin dashboard, and payments

require('dotenv').config();
const express = require('express');
const multer = require('multer');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const session = require('express-session');
const Razorpay = require('razorpay');
const util = require('util');
const { exec } = require('child_process');

const app = express();
const PORT = process.env.PORT || 5000;

// --------- Basic setup & middlewares ----------
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '..', 'public')));
app.use('/uploads', express.static('uploads'));

// Session configuration
app.use(session({
  secret: process.env.SESSION_SECRET || 'xerox-secret-key',
  resave: false,
  saveUninitialized: true,
  cookie: { maxAge: 24 * 60 * 60 * 1000 } // 1 day
}));

// Ensure uploads folder exists
if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads', { recursive: true });
}

// --------- SQLite DB setup ----------
const DB_PATH = path.join(__dirname, 'db.sqlite');
const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) console.error('DB open error:', err);
  else console.log('✅ Connected to SQLite:', DB_PATH);
});

// helper wrapper for db.run to get lastID & changes
function runAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) return reject(err);
      resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}
const getAsync = util.promisify(db.get.bind(db));
const allAsync = util.promisify(db.all.bind(db));

// Create main table if not exists
(async () => {
  try {
    await runAsync(`
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        studentName TEXT,
        filePath TEXT,
        status TEXT DEFAULT 'pending',
        paymentMethod TEXT DEFAULT 'cash',
        amount INTEGER DEFAULT 0,
        bin TEXT,
        lunchTime TEXT,
        pages INTEGER,
        copies INTEGER,
        printType TEXT,
        sides TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
    // Add new columns if they don't exist (for existing DB)
    const columnsToAdd = [
      'studentId INTEGER',
      'bin TEXT',
      'lunchTime TEXT',
      'pages INTEGER',
      'copies INTEGER',
      'printType TEXT',
      'sides TEXT'
    ];
    for (const col of columnsToAdd) {
      try {
        await runAsync(`ALTER TABLE orders ADD COLUMN ${col}`);
      } catch (err) {
        // Column might already exist, ignore
      }
    }

    // Create students table
    await runAsync(`
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        department TEXT,
        year TEXT,
        rollno TEXT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
  } catch (err) {
    console.error('Error creating/updating tables:', err);
  }
})();

// --------- Razorpay (optional) ----------
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'YOUR_KEY_ID',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'YOUR_SECRET'
});

// --------- Multer file upload ----------
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads'),
  filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`)
});
const upload = multer({ storage });

// --------- Admin auth middleware ----------
function checkAdmin(req, res, next) {
  if (!req.session.loggedIn) return res.status(401).json({ error: 'Unauthorized' });
  next();
}

// --------- Routes ----------

// Root -> login page (public/login.html)
app.get('/', (req, res) => {
  if (req.session.loggedIn) return res.redirect('/dashboard');
  res.sendFile(path.join(__dirname, '..', 'public', 'login.html'));
});

// Login API (simple hardcoded admin; change later to DB)
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  // CHANGE: use environment vars or DB in production
  if (username === (process.env.ADMIN_USER || 'admin') && password === (process.env.ADMIN_PASS || '1234')) {
    req.session.loggedIn = true;
    res.json({ message: 'Login successful' });
  } else {
    res.status(401).json({ error: 'Invalid username or password' });
  }
});

// Logout
app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

// Serve dashboard and orders pages (protected)
app.get('/dashboard', (req, res) => {
  if (!req.session.loggedIn) return res.redirect('/');
  res.sendFile(path.join(__dirname, '..', 'public', 'dashboard.html'));
});
app.get('/orders', (req, res) => {
  if (!req.session.loggedIn) return res.redirect('/');
  res.sendFile(path.join(__dirname, '..', 'public', 'orders.html'));
});

// --------- Student-facing API: place order (file upload) ---------
// Note: paymentMethod can be 'cash' or 'online'. amount should be integer (INR).
app.post('/api/upload', upload.array('files', 10), async (req, res) => {
  try {
    const { studentName, paymentMethod, amount, bin, lunchTime, pages, copies, printType, sides } = req.body;
    const files = req.files;
    if (!studentName || !files || files.length === 0) return res.status(400).json({ error: 'Missing studentName or files' });

    const parsedAmount = parseInt(amount) || 0;
    const parsedPages = parseInt(pages) || 0;
    const parsedCopies = parseInt(copies) || 0;
    const pm = (paymentMethod === 'online') ? 'online' : 'cash';

    const filePaths = files.map(f => f.path).join(',');

    const result = await runAsync(
      `INSERT INTO orders (studentName, filePath, status, paymentMethod, amount, bin, lunchTime, pages, copies, printType, sides) VALUES ($1, $2, 'pending', $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
      [studentName, filePaths, pm, parsedAmount, bin, lunchTime, parsedPages, parsedCopies, printType, sides]
    );

    res.json({ message: 'Upload successful', orderId: result.lastID });
  } catch (err) {
    console.error('DB Insert Error', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Student API: fetch their own orders ---------
// Example: GET /api/orders/student?name=Sasti
app.get('/api/orders/student', async (req, res) => {
  try {
    const name = req.query.name;
    if (!name) return res.status(400).json({ error: 'Missing student name (query param ?name=...)' });

    const rows = await allAsync("SELECT * FROM orders WHERE studentName = $1 ORDER BY id DESC", [name]);
    res.json(rows);
  } catch (err) {
    console.error('Error fetching student orders:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Get single order by ID (for mobile app)
app.get('/api/orders/:id', async (req, res) => {
  try {
    const orderId = req.params.id;
    const row = await getAsync("SELECT * FROM orders WHERE id = $1", [orderId]);
    if (!row) return res.status(404).json({ error: "Order not found" });
    res.json(row);
  } catch (err) {
    console.error('Error fetching order by ID:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Admin API: get all orders ---------
app.get('/api/orders', checkAdmin, async (req, res) => {
  try {
    const rows = await allAsync("SELECT * FROM orders ORDER BY id DESC");
    res.json(rows);
  } catch (err) {
    console.error('Error /api/orders', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Mark order completed
app.post('/api/orders/:id/complete', checkAdmin, async (req, res) => {
  const orderId = req.params.id;
  try {
    await runAsync("UPDATE orders SET status='completed' WHERE id = $1", [orderId]);
    res.json({ message: 'Order marked as completed' });
  } catch (err) {
    console.error('Error marking complete:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Print order files
app.post('/api/orders/:id/print', checkAdmin, async (req, res) => {
  const orderId = req.params.id;
  try {
    const order = await getAsync("SELECT * FROM orders WHERE id = $1", [orderId]);
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (!order.filePath) return res.status(400).json({ error: 'No files to print' });

    const files = order.filePath.split(',').map(f => f.trim());
    const uploadDir = 'uploads';

    for (const file of files) {
      const filePath = path.join(uploadDir, path.basename(file));
      if (!fs.existsSync(filePath)) {
        return res.status(404).json({ error: `File not found: ${file}` });
      }
      // Print the file using Windows print command
      exec(`rundll32.exe shell32.dll,ShellExec_RunDLL "${filePath}" print`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Print error for ${file}:`, error);
          return;
        }
        console.log(`Print job sent for ${file}`);
      });
    }

    res.json({ message: 'Print job(s) sent' });
  } catch (err) {
    console.error('Error printing order:', err);
    res.status(500).json({ error: 'Failed to print order' });
  }
});

// --------- Dashboard stats (admin) ----------
app.get('/api/stats', checkAdmin, async (req, res) => {
  try {
    const totalRow = await getAsync("SELECT COUNT(*) AS total FROM orders");
    const pendingRow = await getAsync("SELECT COUNT(*) AS pending FROM orders WHERE status='pending'");
    const completedRow = await getAsync("SELECT COUNT(*) AS completed FROM orders WHERE status='completed'");
    const onlineRow = await getAsync("SELECT COUNT(*) AS online FROM orders WHERE paymentMethod='online'");
    const cashRow = await getAsync("SELECT COUNT(*) AS cash FROM orders WHERE paymentMethod='cash'");
    const totalEarnedRow = await getAsync("SELECT SUM(amount) AS totalEarned FROM orders WHERE status='completed'");

    res.json({
      total: totalRow?.total || 0,
      pending: pendingRow?.pending || 0,
      completed: completedRow?.completed || 0,
      online: onlineRow?.online || 0,
      cash: cashRow?.cash || 0,
      totalEarned: totalEarnedRow?.totalEarned || 0
    });
  } catch (err) {
    console.error('Error /api/stats', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Daily payments (admin) ----------
app.get('/api/daily-payments', checkAdmin, async (req, res) => {
  try {
    // optional ?date=YYYY-MM-DD
    const dateQuery = req.query.date || new Date().toISOString().slice(0, 10);

    const cashRow = await getAsync(
      `SELECT COUNT(*) AS cashCount, SUM(amount) AS cashTotal
       FROM orders WHERE DATE(created_at) = $1 AND paymentMethod='cash'`, [dateQuery]
    );
    const onlineRow = await getAsync(
      `SELECT COUNT(*) AS onlineCount, SUM(amount) AS onlineTotal
       FROM orders WHERE DATE(created_at) = $1 AND paymentMethod='online'`, [dateQuery]
    );

    res.json({
      date: dateQuery,
      cashCount: cashRow?.cashCount || 0,
      cashTotal: cashRow?.cashTotal || 0,
      onlineCount: onlineRow?.onlineCount || 0,
      onlineTotal: onlineRow?.onlineTotal || 0
    });
  } catch (err) {
    console.error('Error /api/daily-payments', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Filtered payments: today/week/month (admin) ----------
app.get('/api/orders-filtered', checkAdmin, async (req, res) => {
  try {
    const filter = req.query.filter || 'today'; // today | week | month
    let dateCondition = "";
    if (filter === 'today') {
      const today = new Date().toISOString().slice(0,10);
      dateCondition = `DATE(created_at)='${today}'`;
    } else if (filter === 'week') {
      const now = new Date();
      const firstDayOfWeek = new Date(now.setDate(now.getDate() - now.getDay())).toISOString().slice(0,10);
      dateCondition = `DATE(created_at) >= '${firstDayOfWeek}'`;
    } else if (filter === 'month') {
      const now = new Date();
      const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0,10);
      dateCondition = `DATE(created_at) >= '${firstDayOfMonth}'`;
    } else {
      return res.status(400).json({ error: 'Invalid filter' });
    }

    const cashRow = await getAsync(`SELECT COUNT(*) AS cashCount, SUM(amount) AS cashTotal FROM orders WHERE ${dateCondition} AND paymentMethod='cash'`);
    const onlineRow = await getAsync(`SELECT COUNT(*) AS onlineCount, SUM(amount) AS onlineTotal FROM orders WHERE ${dateCondition} AND paymentMethod='online'`);

    res.json({
      filter,
      cashCount: cashRow?.cashCount || 0,
      cashTotal: cashRow?.cashTotal || 0,
      onlineCount: onlineRow?.onlineCount || 0,
      onlineTotal: onlineRow?.onlineTotal || 0
    });
  } catch (err) {
    console.error('Error /api/orders-filtered', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Razorpay order creation (optional) ----------
app.post('/api/create-payment', async (req, res) => {
  try {
    const { amount, studentName } = req.body;
    if (!amount) return res.status(400).json({ error: 'Amount required' });

    const options = {
      amount: parseInt(amount) * 100, // paise
      currency: 'INR',
      receipt: `rcpt_${Date.now()}`,
      payment_capture: 1
    };

    const response = await razorpay.orders.create(options);
    res.json({ orderId: response.id, amount: response.amount });
  } catch (err) {
    console.error('Razorpay error', err);
    res.status(500).json({ error: 'Payment creation failed' });
  }
});

// --------- Student registration ----------
app.post('/api/register', async (req, res) => {
  try {
    const { name, department, year, rollno, email, password } = req.body;
    if (!name || !email || !password) return res.status(400).json({ error: 'Name, email, and password are required' });

    const result = await runAsync(
      `INSERT INTO students (name, department, year, rollno, email, password) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [name, department, year, rollno, email, password]
    );

    res.json({ message: 'Student registered successfully', studentId: result.lastID });
  } catch (err) {
    if (err.code === '23505') {
      res.status(400).json({ error: 'Email already exists' });
    } else {
      console.error('Registration error:', err);
      res.status(500).json({ error: 'Database error' });
    }
  }
});

// --------- Student login ----------
app.post('/api/student/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });

    const student = await getAsync("SELECT * FROM students WHERE email = $1 AND password = $2", [email, password]);
    if (!student) return res.status(401).json({ error: 'Invalid email or password' });

    res.json({ message: 'Login successful', studentId: student.id, name: student.name });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Get student profile ----------
app.get('/api/student/profile/:id', async (req, res) => {
  try {
    const studentId = req.params.id;
    const student = await getAsync("SELECT id, name, department, year, rollno, email, created_at FROM students WHERE id = $1", [studentId]);
    if (!student) return res.status(404).json({ error: 'Student not found' });

    res.json(student);
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --------- Utility: reset DB (admin) - deletes all orders ----------
// NOTE: This is destructive. Keep it protected (admin session enforced).
app.post('/api/reset-db', checkAdmin, async (req, res) => {
  try {
    await runAsync("TRUNCATE TABLE orders RESTART IDENTITY CASCADE");
    res.json({ message: 'Database cleared' });
  } catch (err) {
    console.error('Error resetting DB', err);
    res.status(500).json({ error: 'Failed to reset DB' });
  }
});

// --------- Start server ----------
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
