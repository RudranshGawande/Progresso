const mongoose = require('mongoose');

const GoalActivitySchema = new mongoose.Schema({
  goalId: { type: mongoose.Schema.Types.ObjectId, ref: 'Goal', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  title: { type: String, required: true },
  type: {
    type: String,
    enum: ['goal_created', 'goal_updated', 'goal_completed', 'goal_archived',
           'task_added', 'task_completed', 'task_deleted',
           'session_started', 'session_completed', 'session_abandoned'],
    required: true
  },

  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task' },
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Session' },

  metadata: { type: mongoose.Schema.Types.Mixed },

  createdAt: { type: Date, default: Date.now }
});

GoalActivitySchema.index({ goalId: 1, createdAt: -1 });

module.exports = mongoose.model('GoalActivity', GoalActivitySchema);
