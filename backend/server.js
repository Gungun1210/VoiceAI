require('dotenv').config();
const express      = require('express');
const bcrypt       = require('bcryptjs');
const session      = require('express-session');
const pgSession    = require('connect-pg-simple')(session);
const { Pool }     = require('pg');
const cors         = require('cors');

const app  = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// ── CORS ───────────────────────────────────────────────────
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// ── Session store in PostgreSQL ────────────────────────────
app.use(session({
  store: new pgSession({
    pool,
    tableName: 'user_sessions',   // auto-created by connect-pg-simple
    createTableIfMissing: true,
  }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    sameSite: 'lax',
  },
}));

// ── Create users table if not exists ──────────────────────
pool.query(`
  CREATE TABLE IF NOT EXISTS users (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(255) UNIQUE NOT NULL,
    password   VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
  );
`).then(() => console.log('✅ PostgreSQL connected & tables ready'))
  .catch(err => { console.error('DB error:', err); process.exit(1); });

// ── Auth middleware ────────────────────────────────────────
const protect = (req, res, next) => {
  if (!req.session?.userId)
    return res.status(401).json({ message: 'Not authenticated. Please sign in.' });
  next();
};

// ── POST /api/auth/signup ──────────────────────────────────
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ message: 'All fields are required' });
    if (password.length < 6)
      return res.status(400).json({ message: 'Password must be at least 6 characters' });

    const existing = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (existing.rows.length > 0)
      return res.status(409).json({ message: 'Email already in use' });

    const hashed = await bcrypt.hash(password, 12);
    const result = await pool.query(
      'INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id, name, email',
      [name, email, hashed]
    );
    const user = result.rows[0];

    req.session.userId   = user.id;
    req.session.userName = user.name;

    res.status(201).json({
      message: 'Account created successfully',
      user: { id: user.id, name: user.name, email: user.email },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// ── POST /api/auth/signin ──────────────────────────────────
app.post('/api/auth/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ message: 'Email and password required' });

    const result = await pool.query('SELECT * FROM users WHERE email=$1', [email]);
    const user   = result.rows[0];
    if (!user || !(await bcrypt.compare(password, user.password)))
      return res.status(401).json({ message: 'Invalid email or password' });

    req.session.regenerate((err) => {
      if (err) return res.status(500).json({ message: 'Session error' });
      req.session.userId   = user.id;
      req.session.userName = user.name;
      res.status(200).json({
        message: 'Signed in successfully',
        user: { id: user.id, name: user.name, email: user.email },
      });
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// ── POST /api/auth/signout ─────────────────────────────────
app.post('/api/auth/signout', (req, res) => {
  req.session.destroy((err) => {
    if (err) return res.status(500).json({ message: 'Could not sign out' });
    res.clearCookie('connect.sid');
    res.json({ message: 'Signed out successfully' });
  });
});

// ── GET /api/auth/me ───────────────────────────────────────
app.get('/api/auth/me', protect, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, email, created_at FROM users WHERE id=$1',
      [req.session.userId]
    );
    const user = result.rows[0];
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({ user });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// ── Health check ───────────────────────────────────────────
app.get('/api/health', (_, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));