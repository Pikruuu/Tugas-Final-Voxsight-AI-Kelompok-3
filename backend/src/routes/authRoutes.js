const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/authController');

// POST /api/auth/register
router.post('/register',
  [
    body('username').trim().isLength({ min: 3, max: 50 }).withMessage('Username 3-50 karakter.'),
    body('email').isEmail().normalizeEmail().withMessage('Format email tidak valid.'),
    body('password').isLength({ min: 6 }).withMessage('Password minimal 6 karakter.'),
    body('nama_lengkap').trim().notEmpty().withMessage('Nama lengkap wajib diisi.'),
    body('nomor_handphone').optional().matches(/^[0-9+\-\s]{8,20}$/).withMessage('Nomor HP tidak valid.'),
  ],
  validate,
  ctrl.register
);

// POST /api/auth/login
router.post('/login',
  [
    body('identifier').trim().notEmpty().withMessage('Username atau email wajib diisi.'),
    body('password').notEmpty().withMessage('Password wajib diisi.'),
  ],
  validate,
  ctrl.login
);

// POST /api/auth/refresh-token
router.post('/refresh-token',
  [body('refresh_token').notEmpty().withMessage('Refresh token diperlukan.')],
  validate,
  ctrl.refreshToken
);

// POST /api/auth/forgot-password  ← Step 1: kirim OTP ke email
router.post('/forgot-password',
  [
    body('email').isEmail().normalizeEmail().withMessage('Format email tidak valid.'),
  ],
  validate,
  ctrl.forgotPassword
);

// POST /api/auth/reset-password  ← Step 2: verifikasi OTP + set password baru
router.post('/reset-password',
  [
    body('email').isEmail().normalizeEmail().withMessage('Format email tidak valid.'),
    body('otp').isLength({ min: 6, max: 6 }).isNumeric().withMessage('OTP harus 6 digit angka.'),
    body('new_password').isLength({ min: 6 }).withMessage('Password baru minimal 6 karakter.'),
  ],
  validate,
  ctrl.resetPassword
);

// PUT /api/auth/change-password  (perlu login)
router.put('/change-password',
  authenticate,
  [
    body('old_password').notEmpty().withMessage('Password lama wajib diisi.'),
    body('new_password').isLength({ min: 6 }).withMessage('Password baru minimal 6 karakter.')
      .custom((val, { req }) => {
        if (val === req.body.old_password) throw new Error('Password baru tidak boleh sama dengan password lama.');
        return true;
      }),
  ],
  validate,
  ctrl.changePassword
);

// GET /api/auth/profile
router.get('/profile', authenticate, ctrl.getProfile);

// PUT /api/auth/profile
router.put('/profile',
  authenticate,
  [body('nama_lengkap').trim().notEmpty().withMessage('Nama lengkap wajib diisi.')],
  validate,
  ctrl.updateProfile
);

module.exports = router;