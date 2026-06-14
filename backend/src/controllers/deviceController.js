const { query } = require('../config/database');

// GET /api/devices  — semua device milik user
const getDevices = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const result = await query(
      `SELECT d.*,
              m.battery, m.paket_data, m.internet_active, m.recorded_at AS monitoring_at
       FROM devices d
       LEFT JOIN LATERAL (
         SELECT battery, paket_data, internet_active, recorded_at
         FROM monitoring WHERE id_device = d.id_device ORDER BY recorded_at DESC LIMIT 1
       ) m ON TRUE
       WHERE d.id_akun = $1
       ORDER BY d.registered_at DESC`,
      [id_akun]
    );
    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

// POST /api/devices  — daftarkan device baru
const registerDevice = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const result = await query(
      `INSERT INTO devices (id_akun) VALUES ($1) RETURNING *`,
      [id_akun]
    );
    res.status(201).json({ success: true, message: 'Device berhasil didaftarkan.', data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/devices/:id_device
const deleteDevice = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const { id_device } = req.params;

    const result = await query(
      'DELETE FROM devices WHERE id_device = $1 AND id_akun = $2 RETURNING id_device',
      [id_device, id_akun]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Device tidak ditemukan.' });
    }

    res.json({ success: true, message: 'Device berhasil dihapus.' });
  } catch (error) {
    next(error);
  }
};

module.exports = { getDevices, registerDevice, deleteDevice };
