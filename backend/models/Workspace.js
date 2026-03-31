const mongoose = require('mongoose');

const WorkspaceSchema = new mongoose.Schema({
  name: { type: String, required: true },
  type: { type: String, enum: ['personal', 'community'], required: true },
  
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // creator

  ownerSnapshot: {
    email: { type: String, required: true }
  },

  members: [
    {
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
      email: { type: String, required: true },
      role: { type: String, enum: ['admin', 'member'], required: true }
    }
  ]
});

module.exports = mongoose.model('Workspace', WorkspaceSchema);
