const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Token tidak ditemukan. Silakan login.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const result = await query(
      `SELECT a.id_akun, a.username, a.email, u.nama_lengkap
       FROM accounts a
       LEFT JOIN users u ON u.id_akun = a.id_akun
       WHERE a.id_akun = $1`,
      [decoded.id_akun]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Akun tidak ditemukan.' });
    }

    req.user = result.rows[0];
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token sudah kedaluwarsa. Silakan login ulang.' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Token tidak valid.' });
    }
    next(error);
  }
};

module.exports = { authenticate };
