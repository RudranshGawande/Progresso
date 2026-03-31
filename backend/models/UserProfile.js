const mongoose = require('mongoose');

/**
 * user_profiles collection
 * Stores extended profile and security data per user.
 * The `userId` field stores the user's email (for backwards compatibility
 * with the Dart client that queries by email).
 */
const UserProfileSchema = new mongoose.Schema({
  // Store email as userId so Dart client's `where.eq('userId', user['email'])` works
  userId: { type: String, required: true, unique: true },

  // Reference to the users collection _id
  userObjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  // Profile details (mirrors users collection for easy reads)
  profile: {
    name:       { type: String, default: '' },
    bio:        { type: String, default: '' },
    avatarUrl:  { type: String, default: '' },
    avatarBase64: { type: String, default: '' },
  },

  // Security settings
  security: {
    twoFactorEnabled: { type: Boolean, default: false },
    twoFactorSecret:  { type: String,  default: '' },
    tempSecret:       { type: String,  default: '' },
  },
});

module.exports = mongoose.model('UserProfile', UserProfileSchema, 'user_profiles');
