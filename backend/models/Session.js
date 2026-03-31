const mongoose = require('mongoose');

const SessionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  goalId: { type: mongoose.Schema.Types.ObjectId, ref: 'Goal' },

  goalSnapshot: {
    _id: mongoose.Schema.Types.ObjectId,
    name: String
  },

  name: String,
  taskIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }]
});

module.exports = mongoose.model('Session', SessionSchema);