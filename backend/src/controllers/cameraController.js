const { query } = require('../config/database');

const verifyDeviceOwner = async (id_device, id_akun) => {
  const result = await query(
    'SELECT id_device FROM devices WHERE id_device = $1 AND id_akun = $2',
    [id_device, id_akun],
  );
  return result.rows.length > 0;
};

const getCameraStatus = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res.status(404).json({ success: false, message: 'Device tidak ditemukan.' });
    }

    const result = await query(
      `SELECT * FROM device_cameras
       WHERE id_device = $1
       ORDER BY recorded_at DESC
       LIMIT 1`,
      [id_device],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Data kamera tidak ditemukan untuk device ini.' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

const getCameraHistory = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;
    const limit = parseInt(req.query.limit, 10) || 50;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res.status(404).json({ success: false, message: 'Device tidak ditemukan.' });
    }

    const result = await query(
      `SELECT * FROM device_cameras
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

const recordCameraData = async (req, res, next) => {
  try {
    const id_device = req.params.id_device || req.params.deviceId || req.params.id;
    const { fps, values_focus, value_clarity, latency, stream_url, is_streaming } = req.body;

    const result = await query(
      `INSERT INTO device_cameras
         (id_device, fps, values_focus, value_clarity, latency, stream_url, is_streaming)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        id_device,
        fps ?? null,
        values_focus ?? null,
        value_clarity ?? null,
        latency ?? null,
        stream_url ?? null,
        is_streaming ?? false,
      ],
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// Fungsi recordCameraData sekarang diekspor kembali
module.exports = { getCameraStatus, getCameraHistory, recordCameraData };