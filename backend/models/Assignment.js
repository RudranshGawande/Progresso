const mongoose = require('mongoose');

const AssignmentSchema = new mongoose.Schema({
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace', required: true },
  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },

  title: { type: String, required: true },
  description: { type: String, default: '' },

  assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  assignedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  assigneeName: { type: String },
  assigneeAvatar: { type: String },

  deadline: Date,

  status: {
    type: String,
    enum: ['pending', 'in_progress', 'completed', 'overdue'],
    default: 'pending'
  },

  completedAt: Date,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

AssignmentSchema.index({ workspaceId: 1, status: 1 });
AssignmentSchema.index({ assignedTo: 1, status: 1 });

module.exports = mongoose.model('Assignment', AssignmentSchema);
