const { query } = require('../config/database');

const verifyDeviceOwner = async (id_device, id_akun) => {
  const result = await query(
    'SELECT id_device FROM devices WHERE id_device = $1 AND id_akun = $2',
    [id_device, id_akun],
  );
  return result.rows.length > 0;
};

const getLatestLocation = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res.status(404).json({ success: false, message: 'Device tidak ditemukan.' });
    }

    const result = await query(
      `SELECT id_lokasi, id_device, latitude, longitude, recorded_at
       FROM device_locations
       WHERE id_device = $1
       ORDER BY recorded_at DESC
       LIMIT 1`,
      [id_device],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Data lokasi tidak ditemukan untuk device ini.' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

const getLocationHistory = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;
    const limit = parseInt(req.query.limit, 10) || 50;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res.status(404).json({ success: false, message: 'Device tidak ditemukan.' });
    }

    const result = await query(
      `SELECT id_lokasi, latitude, longitude, recorded_at
       FROM device_locations
       WHERE id_device = $1
       ORDER BY recorded_at DESC
       LIMIT $2`,
      [id_device, limit],
    );

    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

const getLastSeenLocation = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res.status(404).json({ success: false, message: 'Device tidak ditemukan.' });
    }

    const result = await query(
      `SELECT latitude, longitude, recorded_at
       FROM device_locations
       WHERE id_device = $1
       ORDER BY recorded_at DESC
       LIMIT 1`,
      [id_device],
    );

    res.json({ success: true, data: result.rows[0] || null });
  } catch (error) {
    next(error);
  }
};

const recordLocation = async (req, res, next) => {
  try {
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;
    const { latitude, longitude } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'Latitude dan longitude wajib diisi.' });
    }

    const result = await query(
      `INSERT INTO device_locations (id_device, latitude, longitude)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [id_device, latitude, longitude],
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// Seluruh fungsi telah diekspor kembali agar index.js tidak crash
module.exports = { getLatestLocation, getLocationHistory, getLastSeenLocation, recordLocation };