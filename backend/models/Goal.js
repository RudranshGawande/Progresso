const mongoose = require('mongoose');

const GoalSchema = new mongoose.Schema({
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  name: String,
  sessionIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Session' }]
});

module.exports = mongoose.model('Goal', GoalSchema);
