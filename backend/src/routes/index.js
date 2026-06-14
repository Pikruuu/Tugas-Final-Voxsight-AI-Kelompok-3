const router = require('express').Router();
const { body, param, query } = require('express-validator');
const { validate } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');

const dashCtrl = require('../controllers/dashboardController');
const deviceCtrl = require('../controllers/deviceController');
const locationCtrl = require('../controllers/locationController');
const cameraCtrl = require('../controllers/cameraController');
const alertCtrl = require('../controllers/alertController');

// ─── DASHBOARD ───────────────────────────────────────────────────────────────
router.get('/dashboard', authenticate, dashCtrl.getDashboard);
router.get('/dashboard/device/:id_device', authenticate, dashCtrl.getDeviceDetail);

// ─── DEVICES ─────────────────────────────────────────────────────────────────
router.get('/devices', authenticate, deviceCtrl.getDevices);
router.post('/devices', authenticate, deviceCtrl.registerDevice);
router.delete('/devices/:id_device', authenticate, deviceCtrl.deleteDevice);

// Update status device (bisa dipanggil dari device IoT maupun dashboard)
router.patch('/devices/:id_device/status',
  authenticate,
  [body('is_active').isBoolean().withMessage('is_active harus boolean.')],
  validate,
  alertCtrl.updateDeviceStatus
);

// ─── MONITORING (dipanggil dari IoT device, tidak perlu JWT) ─────────────────
router.post('/monitoring/:id_device',
  [
    param('id_device').isUUID().withMessage('id_device tidak valid.'),
    body('battery').optional().isFloat({ min: 0, max: 100 }).withMessage('Battery 0-100.'),
    body('paket_data').optional().isFloat({ min: 0 }).withMessage('Paket data harus angka positif.'),
  ],
  validate,
  alertCtrl.recordMonitoring
);

// ─── LOCATION ────────────────────────────────────────────────────────────────
router.get('/location/:id_device', authenticate, locationCtrl.getLatestLocation);
router.get('/location/:id_device/history', authenticate, locationCtrl.getLocationHistory);
router.get('/location/:id_device/last-seen', authenticate, locationCtrl.getLastSeenLocation);

// Endpoint dari IoT device (tanpa JWT)
router.post('/location/:id_device',
  [
    param('id_device').isUUID(),
    body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Latitude tidak valid.'),
    body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Longitude tidak valid.'),
  ],
  validate,
  locationCtrl.recordLocation
);

// ─── CAMERA ──────────────────────────────────────────────────────────────────
router.get('/camera/:id_device', authenticate, cameraCtrl.getCameraStatus);
router.get('/camera/:id_device/history', authenticate, cameraCtrl.getCameraHistory);

// Endpoint dari IoT device (tanpa JWT)
router.post('/camera/:id_device',
  [
    param('id_device').isUUID(),
    body('fps').optional().isFloat({ min: 0 }),
    body('values_focus').optional().isFloat({ min: 0, max: 100 }),
    body('value_clarity').optional().isFloat({ min: 0, max: 100 }),
    body('latency').optional().isFloat({ min: 0 }),
  ],
  validate,
  cameraCtrl.recordCameraData
);

// ─── ALERTS ──────────────────────────────────────────────────────────────────
router.get('/alerts', authenticate, alertCtrl.getAlerts);
router.get('/alerts/unread-count', authenticate, alertCtrl.getUnreadCount);
router.get('/alerts/device/:id_device', authenticate, alertCtrl.getDeviceAlerts);
router.patch('/alerts/:id/read', authenticate, alertCtrl.markAsRead);
router.patch('/alerts/read-all', authenticate, alertCtrl.markAllAsRead);

module.exports = router;