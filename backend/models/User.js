const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: { type: String, required: true },
  defaultPersonalWorkspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  personalWorkspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  communityWorkspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  // Profile fields
  bio: { type: String, default: '' },
  imageUrl: { type: String },
  rotation: { type: Number, default: 0 },
  localImagePath: { type: String },
  avatarBase64: { type: String }
});

module.exports = mongoose.model('User', UserSchema);
