const mongoose = require('mongoose');

const FocusSessionSchema = new mongoose.Schema({
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Session', required: true },
  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
  goalId: { type: mongoose.Schema.Types.ObjectId, ref: 'Goal' },
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace', required: true },

  duration: { type: Number, required: true },
  intensity: { type: Number, min: 0, max: 1 },
  focusScore: { type: Number, min: 0, max: 100 },

  trendData: [{ type: Number }],

  startedAt: { type: Date, required: true },
  endedAt: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now }
});

FocusSessionSchema.index({ taskId: 1, startedAt: -1 });
FocusSessionSchema.index({ goalId: 1, startedAt: -1 });
FocusSessionSchema.index({ workspaceId: 1, startedAt: -1 });

module.exports = mongoose.model('FocusSession', FocusSessionSchema);
