const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Session', default: null },
  goalId: { type: mongoose.Schema.Types.ObjectId, ref: 'Goal' },
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },

  name: String,
  priority: String,
  deadline: Date,

  sessionType: { type: String, enum: ['free', 'timed'] },

  selected: { type: Boolean, default: null },

  status: { 
    type: String, 
    enum: ['not_started', 'in_progress', 'completed'],
    default: 'not_started'
  },

  timer: {
    totalAllocatedTime: { type: Number, default: null },
    timeSpent: { type: Number, default: 0 }
  }
});

module.exports = mongoose.model('Task', TaskSchema);
