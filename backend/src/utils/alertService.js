const { query } = require("../config/database");

const BATTERY_THRESHOLD = 30;
const DATA_THRESHOLD = 200;
const TOTAL_DATA_PACKAGE = 2000;

const createAlert = async (id_device, alert_type, severity, message) => {
  try {
    const result = await query(
      `INSERT INTO alerts (id_device, alert_type, severity, message)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [id_device, alert_type, severity, message],
    );

    return result.rows[0];
  } catch (error) {
    console.error("Failed to create alert:", error);
    return null;
  }
};

const checkMonitoringAlerts = async (id_device, monitoringData) => {
  const alerts = [];

  const { battery, paket_data } = monitoringData;

  // LOW BATTERY
  if (
    battery !== null &&
    battery !== undefined &&
    battery < BATTERY_THRESHOLD
  ) {
    const severity = battery < 15 ? "critical" : "high";

    const alert = await createAlert(
      id_device,
      "LOW_BATTERY",
      severity,
      `Baterai rendah (${battery}%). Segera charge device.`,
    );

    if (alert) alerts.push(alert);
  }

  // LOW DATA PACKAGE
  // paket_data = data terpakai
  if (paket_data !== null && paket_data !== undefined) {
    const remaining = TOTAL_DATA_PACKAGE - paket_data;

    if (remaining < DATA_THRESHOLD) {
      const severity = remaining < 100 ? "critical" : "high";

      const alert = await createAlert(
        id_device,
        "LOW_DATA_PACKAGE",
        severity,
        `Sisa kuota internet tinggal ${remaining} MB.`,
      );

      if (alert) alerts.push(alert);
    }
  }

  return alerts;
};

const checkDeviceOfflineAlert = async (id_device) => {
  const deviceResult = await query(
    `SELECT d.is_active,
            d.last_seen,
            dl.latitude,
            dl.longitude,
            dl.recorded_at AS location_at
     FROM devices d
     LEFT JOIN LATERAL (
       SELECT *
       FROM device_locations
       WHERE id_device = d.id_device
       ORDER BY recorded_at DESC
       LIMIT 1
     ) dl ON TRUE
     WHERE d.id_device = $1`,
    [id_device],
  );

  const device = deviceResult.rows[0];

  if (!device || device.is_active) {
    return null;
  }

  const recent = await query(
    `SELECT id
     FROM alerts
     WHERE id_device = $1
       AND alert_type = 'DEVICE_OFFLINE'
       AND triggered_at >= NOW() - INTERVAL '1 hour'
     LIMIT 1`,
    [id_device],
  );

  if (recent.rows.length > 0) {
    return null;
  }

  const locationMsg = device.latitude
    ? `Lokasi terakhir: ${device.latitude}, ${device.longitude}`
    : "Lokasi terakhir tidak tersedia";

  return createAlert(
    id_device,
    "DEVICE_OFFLINE",
    "critical",
    `Device offline. ${locationMsg}`,
  );
};

module.exports = {
  createAlert,
  checkMonitoringAlerts,
  checkDeviceOfflineAlert,
};
