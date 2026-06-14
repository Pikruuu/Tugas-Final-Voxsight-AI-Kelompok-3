const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const { query } = require('../config/database');

// ─── Helper: generate JWT token ───────────────────────────────────────────────
const generateToken = (payload, secret, expiresIn) =>
  jwt.sign(payload, secret, { expiresIn });

// ─── Helper: generate OTP 6 digit ─────────────────────────────────────────────
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// ─── Helper: kirim email via Gmail ────────────────────────────────────────────
const sendOTPEmail = async (toEmail, otp) => {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: `"VoxSight" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'Kode OTP Reset Password VoxSight',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;">
        <h2 style="color: #1a1a2e;">Reset Password VoxSight</h2>
        <p>Gunakan kode OTP berikut untuk reset password kamu:</p>
        <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px;
                    color: #0f3460; padding: 16px; background: #f0f4ff;
                    border-radius: 8px; text-align: center;">
          ${otp}
        </div>
        <p style="margin-top: 16px;">Kode ini berlaku selama <strong>10 menit</strong>.</p>
        <p style="color: #888; font-size: 12px;">
          Jika kamu tidak merasa melakukan permintaan ini, abaikan email ini.
        </p>
      </div>
    `,
  });
};

// ─── POST /api/auth/register ──────────────────────────────────────────────────
const register = async (req, res, next) => {
  try {
    const { username, email, password, nama_lengkap, nomor_handphone, alamat } = req.body;

    const existing = await query(
      'SELECT id_akun FROM accounts WHERE username = $1 OR email = $2',
      [username, email]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'Username atau email sudah terdaftar.' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const client = await require('../config/database').pool.connect();
    
    try {
      await client.query('BEGIN');

      const accountResult = await client.query(
        `INSERT INTO accounts (username, email, password)
         VALUES ($1, $2, $3) RETURNING id_akun, username, email, created_at`,
        [username, email, hashedPassword]
      );
      const account = accountResult.rows[0];

      await client.query(
        `INSERT INTO users (id_akun, nama_lengkap, nomor_handphone, alamat)
         VALUES ($1, $2, $3, $4)`,
        [account.id_akun, nama_lengkap, nomor_handphone || null, alamat || null]
      );

      await client.query('COMMIT');

      const token = generateToken(
        { id_akun: account.id_akun },
        process.env.JWT_SECRET,
        process.env.JWT_EXPIRES_IN
      );

      return res.status(201).json({
        success: true,
        message: 'Registrasi berhasil.',
        data: {
          id_akun: account.id_akun,
          username: account.username,
          email: account.email,
          nama_lengkap,
          created_at: account.created_at,
        },
        token,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    next(error);
  }
};

// ─── POST /api/auth/login ─────────────────────────────────────────────────────
const login = async (req, res, next) => {
  try {
    const { identifier, password } = req.body;

    const result = await query(
      `SELECT a.id_akun, a.username, a.email, a.password, u.nama_lengkap
       FROM accounts a
       LEFT JOIN users u ON u.id_akun = a.id_akun
       WHERE a.username = $1 OR a.email = $1`,
      [identifier]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Username/email atau password salah.' });
    }

    const account = result.rows[0];
    const isPasswordValid = await bcrypt.compare(password, account.password);

    if (!isPasswordValid) {
      return res.status(401).json({ success: false, message: 'Username/email atau password salah.' });
    }

    const token = generateToken(
      { id_akun: account.id_akun },
      process.env.JWT_SECRET,
      process.env.JWT_EXPIRES_IN
    );
    const refreshToken = generateToken(
      { id_akun: account.id_akun },
      process.env.JWT_REFRESH_SECRET,
      process.env.JWT_REFRESH_EXPIRES_IN
    );

    return res.json({
      success: true,
      message: 'Login berhasil.',
      data: {
        id_akun: account.id_akun,
        username: account.username,
        email: account.email,
        nama_lengkap: account.nama_lengkap,
      },
      token,
      refresh_token: refreshToken,
    });
  } catch (error) {
    next(error);
  }
};

// ─── POST /api/auth/refresh-token ─────────────────────────────────────────────
const refreshToken = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    const decoded = jwt.verify(refresh_token, process.env.JWT_REFRESH_SECRET);
    
    const token = generateToken(
      { id_akun: decoded.id_akun },
      process.env.JWT_SECRET,
      process.env.JWT_EXPIRES_IN
    );

    return res.json({ success: true, token });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Refresh token tidak valid atau kedaluwarsa.' });
  }
};

// ─── POST /api/auth/forgot-password ──────────────────────────────────────────
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    const result = await query('SELECT id_akun FROM accounts WHERE email = $1', [email]);

    if (result.rows.length === 0) {
      return res.json({ success: true, message: 'Jika email terdaftar, kode OTP telah dikirimkan.' });
    }

    const { id_akun } = result.rows[0];
    const otp = generateOTP();

    await query('DELETE FROM password_reset_tokens WHERE id_akun = $1 AND used = FALSE', [id_akun]);
    await query(
      `INSERT INTO password_reset_tokens (id_akun, otp, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '10 minutes')`,
      [id_akun, otp]
    );

    try {
      await sendOTPEmail(email, otp);
    } catch (emailError) {
      console.error('Gagal kirim email OTP:', emailError.message);
      return res.status(500).json({ success: false, message: 'Gagal mengirim email. Coba beberapa saat lagi.' });
    }

    return res.json({ success: true, message: 'Kode OTP telah dikirimkan ke email kamu. Berlaku 10 menit.' });
  } catch (error) {
    next(error);
  }
};

// ─── POST /api/auth/reset-password ───────────────────────────────────────────
const resetPassword = async (req, res, next) => {
  try {
    const { email, otp, new_password } = req.body;
    const accountResult = await query('SELECT id_akun FROM accounts WHERE email = $1', [email]);

    if (accountResult.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Email tidak ditemukan.' });
    }

    const { id_akun } = accountResult.rows[0];
    const tokenResult = await query(
      `SELECT id FROM password_reset_tokens
       WHERE id_akun = $1 AND otp = $2 AND used = FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [id_akun, otp]
    );

    if (tokenResult.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Kode OTP tidak valid atau sudah kedaluwarsa.' });
    }

    const tokenId = tokenResult.rows[0].id;
    const client = await require('../config/database').pool.connect();
    
    try {
      await client.query('BEGIN');
      const hashedPassword = await bcrypt.hash(new_password, 12);
      
      await client.query('UPDATE accounts SET password = $1 WHERE id_akun = $2', [hashedPassword, id_akun]);
      await client.query('UPDATE password_reset_tokens SET used = TRUE WHERE id = $1', [tokenId]);
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

    return res.json({ success: true, message: 'Password berhasil direset. Silakan login.' });
  } catch (error) {
    next(error);
  }
};

// ─── PUT /api/auth/change-password ───────────────────────────────────────────
const changePassword = async (req, res, next) => {
  try {
    const { old_password, new_password } = req.body;
    const { id_akun } = req.user;

    const result = await query('SELECT password FROM accounts WHERE id_akun = $1', [id_akun]);
    const isValid = await bcrypt.compare(old_password, result.rows[0].password);

    if (!isValid) {
      return res.status(400).json({ success: false, message: 'Password lama tidak sesuai.' });
    }

    const hashedPassword = await bcrypt.hash(new_password, 12);
    await query('UPDATE accounts SET password = $1 WHERE id_akun = $2', [hashedPassword, id_akun]);

    return res.json({ success: true, message: 'Password berhasil diubah.' });
  } catch (error) {
    next(error);
  }
};

// ─── GET /api/auth/profile ────────────────────────────────────────────────────
const getProfile = async (req, res) => {
  try {
    const { id_akun } = req.user;
    const result = await query(
      `SELECT a.id_akun, a.username, a.email, a.created_at,
              u.nama_lengkap, u.nomor_handphone, u.alamat, u.updated_at
       FROM accounts a
       LEFT JOIN users u ON u.id_akun = a.id_akun
       WHERE a.id_akun = $1`,
      [id_akun]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    // Mengubah key dari database ke format yang diminta Flutter
    const dbData = result.rows[0];
    const formattedData = {
      nama: dbData.nama_lengkap,
      email: dbData.email,
      no_hp: dbData.nomor_handphone,
      alamat: dbData.alamat,
      is_verified: true // Contoh statis, sesuaikan jika ada field asli
    };

    res.json({ success: true, data: formattedData });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
};

// ─── PUT /api/auth/profile ────────────────────────────────────────────────────
const updateProfile = async (req, res, next) => {
  try {
    const { nama_lengkap, nomor_handphone, alamat } = req.body;
    const { id_akun } = req.user;

    await query(
      `UPDATE users SET nama_lengkap = $1, nomor_handphone = $2, alamat = $3
       WHERE id_akun = $4`,
      [nama_lengkap, nomor_handphone || null, alamat || null, id_akun]
    );

    res.json({ success: true, message: 'Profil berhasil diperbarui.' });
  } catch (error) {
    next(error);
  }
};

// ─── POST /api/auth/upload-avatar (Opsional) ─────────────────────────────────
const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'File foto tidak ditemukan.' });
    }

    const { id_akun } = req.user;
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    
    // Asumsi tabel users punya kolom avatar_url
    await query('UPDATE users SET avatar_url = $1 WHERE id_akun = $2', [avatarUrl, id_akun]);

    return res.status(200).json({
      success: true,
      message: 'Foto profil berhasil diupload!',
      data: { avatarUrl },
    });
  } catch (error) {
    console.error('Upload avatar error:', error);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan saat upload foto.' });
  }
};

module.exports = {
  register,
  login,
  refreshToken,
  forgotPassword,
  resetPassword,
  changePassword,
  getProfile,
  updateProfile,
  uploadAvatar,
};