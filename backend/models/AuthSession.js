const mongoose = require('mongoose');

const AuthSessionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  deviceName: { type: String, default: 'Unknown Device' },
  deviceType: { type: String, enum: ['Mobile', 'Desktop', 'Tablet'], default: 'Desktop' },
  osInfo: { type: String, default: 'Unknown OS' },
  ipAddress: { type: String },
  loginTime: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now },
  userAgent: { type: String },
  tokenHash: { type: String, required: true }, // To match with current request token if needed
  isActive: { type: Boolean, default: true }
});

module.exports = mongoose.model('AuthSession', AuthSessionSchema, 'auth_sessions');
