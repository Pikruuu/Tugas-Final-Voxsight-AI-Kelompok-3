const { query } = require('../config/database');

const getDashboard = async (req, res, next) => {
  try {
    const { id_akun } = req.user;

    const devicesResult = await query(
      `SELECT
         d.id_device,
         d.is_active,
         d.registered_at,
         d.last_seen,
         m.battery,
         m.paket_data,
         m.suhu_cpu,
         m.suhu_camera,
         m.internet_active,
         m.recorded_at  AS monitoring_at,
         dl.latitude,
         dl.longitude,
         dl.recorded_at AS location_at
       FROM devices d
       LEFT JOIN LATERAL (
         SELECT * FROM monitoring WHERE id_device = d.id_device ORDER BY recorded_at DESC LIMIT 1
       ) m ON TRUE
       LEFT JOIN LATERAL (
         SELECT * FROM device_locations WHERE id_device = d.id_device ORDER BY recorded_at DESC LIMIT 1
       ) dl ON TRUE
       WHERE d.id_akun = $1
       ORDER BY d.registered_at DESC`,
      [id_akun]
    );

    const devices = devicesResult.rows;

    const summary = {
      total_devices: devices.length,
      active_devices: devices.filter((d) => d.is_active).length,
      inactive_devices: devices.filter((d) => !d.is_active).length,
      low_battery_count: devices.filter((d) => d.battery !== null && d.battery < 20).length,
      low_data_count: devices.filter((d) => d.paket_data !== null && d.paket_data < 100).length,
    };

    const alertResult = await query(
      `SELECT COUNT(*) AS unread_alerts
       FROM alerts al
       JOIN devices d ON d.id_device = al.id_device
       WHERE d.id_akun = $1 AND al.is_read = FALSE`,
      [id_akun]
    );

    res.json({
      success: true,
      data: {
        summary: { ...summary, unread_alerts: parseInt(alertResult.rows[0].unread_alerts) },
        devices,
      },
    });
  } catch (error) {
    next(error);
  }
};

const getDeviceDetail = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const { id_device } = req.params;

    const own = await query(
      `
      SELECT id_device
      FROM devices
      WHERE id_device = $1
      AND id_akun = $2
      `,
      [id_device, id_akun]
    );

    if (own.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Device tidak ditemukan.',
      });
    }

    const monResult = await query(
      `
      SELECT *
      FROM monitoring
      WHERE id_device = $1
      ORDER BY recorded_at DESC
      LIMIT 1
      `,
      [id_device]
    );

    const historyResult = await query(
      `
      SELECT
        battery,
        paket_data,
        suhu_cpu,
        suhu_camera,
        internet_active,
        recorded_at
      FROM monitoring
      WHERE id_device = $1
      AND recorded_at >= NOW() - INTERVAL '24 hours'
      ORDER BY recorded_at ASC
      `,
      [id_device]
    );

    const camResult = await query(
      `
      SELECT *
      FROM device_cameras
      WHERE id_device = $1
      ORDER BY recorded_at DESC
      LIMIT 1
      `,
      [id_device]
    );

    const locResult = await query(
      `
      SELECT *
      FROM device_locations
      WHERE id_device = $1
      ORDER BY recorded_at DESC
      LIMIT 1
      `,
      [id_device]
    );

    const deviceResult = await query(
      `
      SELECT *
      FROM devices
      WHERE id_device = $1
      `,
      [id_device]
    );

    const monitoring = monResult.rows[0];

    res.json({
      success: true,
      data: {
        dashboard: {
          battery: Number(monitoring?.battery || 0),
          used: Number(monitoring?.paket_data || 0),
          remaining: Math.max(
            0,
            2000 - Number(monitoring?.paket_data || 0)
          ),
          isOnline: deviceResult.rows[0].is_active,
        },

        device: deviceResult.rows[0],

        monitoring: monitoring || null,

        monitoring_history: historyResult.rows,

        camera: camResult.rows[0] || null,

        location: locResult.rows[0] || null,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getDashboard, getDeviceDetail };