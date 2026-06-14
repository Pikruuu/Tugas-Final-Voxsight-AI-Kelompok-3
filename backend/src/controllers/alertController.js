const { query } = require("../config/database");
const alertService = require("../utils/alertService");

const verifyDeviceOwner = async (id_device, id_akun) => {
  const result = await query(
    "SELECT id_device FROM devices WHERE id_device = $1 AND id_akun = $2",
    [id_device, id_akun],
  );
  return result.rows.length > 0;
};

const getAlerts = async (req, res, next) => {
  try {
    console.log("REQ USER =", req.user);
    const id_akun = "597a34a0-2f53-467f-8ada-670e6884fa42";
    const { is_read, severity, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereConditions = ["d.id_akun = $1"];
    let params = [id_akun];
    let paramIdx = 2;

    if (is_read !== undefined) {
      whereConditions.push(`al.is_read = $${paramIdx++}`);
      params.push(is_read === "true");
    }
    if (severity) {
      whereConditions.push(`al.severity = $${paramIdx++}`);
      params.push(severity);
    }

    const whereClause = whereConditions.join(" AND ");

    const countResult = await query(
      `SELECT COUNT(*) AS total
       FROM alerts al
       JOIN devices d ON d.id_device = al.id_device
       WHERE ${whereClause}`,
      params,
    );

    // Data dengan pagination
    const result = await query(
      `SELECT al.*, d.is_active AS device_active
       FROM alerts al
       JOIN devices d ON d.id_device = al.id_device
       WHERE ${whereClause}
       ORDER BY al.triggered_at DESC
       LIMIT $${paramIdx} OFFSET $${paramIdx + 1}`,
      [...params, parseInt(limit), offset],
    );

    res.json({
      success: true,
      data: {
        total: parseInt(countResult.rows[0].total),
        page: parseInt(page),
        limit: parseInt(limit),
        alerts: result.rows,
      },
    });
  } catch (error) {
    console.error("Get alerts error:");
    console.error(error);
    next(error);
  }
};

const getUnreadCount = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const result = await query(
      `SELECT COUNT(*) AS count
       FROM alerts al
       JOIN devices d ON d.id_device = al.id_device
       WHERE d.id_akun = $1 AND al.is_read = FALSE`,
      [id_akun],
    );
    res.json({
      success: true,
      data: { unread_count: parseInt(result.rows[0].count) },
    });
  } catch (error) {
    next(error);
  }
};

const getDeviceAlerts = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const { id_device } = req.params;
    const { limit = 20 } = req.query;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res
        .status(404)
        .json({ success: false, message: "Device tidak ditemukan." });
    }

    const result = await query(
      `SELECT * FROM alerts
       WHERE id_device = $1
       ORDER BY triggered_at DESC
       LIMIT $2`,
      [id_device, parseInt(limit)],
    );

    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

const markAsRead = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const { id } = req.params;

    const result = await query(
      `UPDATE alerts
       SET is_read = TRUE
       WHERE id = $1
         AND id_device IN (SELECT id_device FROM devices WHERE id_akun = $2)
       RETURNING *`,
      [id, id_akun],
    );

    if (result.rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Alert tidak ditemukan." });
    }

    res.json({
      success: true,
      message: "Alert ditandai sudah dibaca.",
      data: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

const markAllAsRead = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const { id_device } = req.query; 

    let whereClause =
      "id_device IN (SELECT id_device FROM devices WHERE id_akun = $1)";
    let params = [id_akun];

    if (id_device) {
      whereClause += " AND id_device = $2";
      params.push(id_device);
    }

    const result = await query(
      `UPDATE alerts SET is_read = TRUE WHERE is_read = FALSE AND ${whereClause}`,
      params,
    );

    res.json({
      success: true,
      message: `${result.rowCount} alert ditandai sudah dibaca.`,
    });
  } catch (error) {
    next(error);
  }
};

const recordMonitoring = async (req, res, next) => {
  try {
    const { id_device } = req.params;
    const { suhu_cpu, suhu_camera, battery, paket_data, internet_active } =
      req.body;

    const result = await query(
      `INSERT INTO monitoring
         (id_device, suhu_cpu, suhu_camera, battery, paket_data, internet_active)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        id_device,
        suhu_cpu || null,
        suhu_camera || null,
        battery ?? null,
        paket_data ?? null,
        internet_active ?? false,
      ],
    );

    // Update last_seen
    await query("UPDATE devices SET last_seen = NOW() WHERE id_device = $1", [
      id_device,
    ]);

    const triggeredAlerts = await alertService.checkMonitoringAlerts(
      id_device,
      {
        battery,
        paket_data,
        is_active: true,
      },
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      alerts_triggered: triggeredAlerts.length,
      alerts: triggeredAlerts,
    });
  } catch (error) {
    next(error);
  }
};

const updateDeviceStatus = async (req, res, next) => {
  try {
    const { id_akun } = req.user;
    const { id_device } = req.params;
    const { is_active } = req.body;

    if (!(await verifyDeviceOwner(id_device, id_akun))) {
      return res
        .status(404)
        .json({ success: false, message: "Device tidak ditemukan." });
    }

    await query(
      `UPDATE devices SET is_active = $1, last_seen = NOW() WHERE id_device = $2`,
      [is_active, id_device],
    );

    // Jika device menjadi offline
    if (!is_active) {
      await alertService.checkDeviceOfflineAlert(id_device);
    }

    res.json({
      success: true,
      message: `Device ${is_active ? "diaktifkan" : "dinonaktifkan"}.`,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAlerts,
  getUnreadCount,
  getDeviceAlerts,
  markAsRead,
  markAllAsRead,
  recordMonitoring,
  updateDeviceStatus,
};
