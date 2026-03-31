require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('./models/User');
const Workspace = require('./models/Workspace');
const Goal = require('./models/Goal');
const Session = require('./models/Session');
const Task = require('./models/Task');

async function seed() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // 1. Delete existing demo user and related data
    const existingUser = await User.findOne({ email: 'demo@gmail.com' });
    if (existingUser) {
      await Workspace.deleteMany({ ownerId: existingUser._id });
      await Goal.deleteMany({ workspaceId: existingUser.defaultPersonalWorkspaceId });
      await Session.deleteMany({ userId: existingUser._id });
      // Delete tasks that belong to the user's workspace
      await Task.deleteMany({ workspaceId: existingUser.defaultPersonalWorkspaceId });
      await User.deleteOne({ _id: existingUser._id });
      console.log('Deleted existing demo user and data');
    }

    // 2. Create User
    const hashedPassword = await bcrypt.hash('pass123', 8);
    const user = new User({
      name: 'Demo Gmail User',
      email: 'demo@gmail.com',
      password: hashedPassword
    });
    await user.save();

    // 3. Create Workspace
    const workspace = new Workspace({
      name: "Personal Workspace",
      type: "personal",
      ownerId: user._id,
      ownerSnapshot: { email: user.email },
      members: [{ userId: user._id, email: user.email, role: "admin" }]
    });
    await workspace.save();

    user.defaultPersonalWorkspaceId = workspace._id;
    user.personalWorkspaceId = workspace._id;
    await user.save();
    console.log('Created User & Workspace');

    // 4. Create a Goal
    const goal = new Goal({
      workspaceId: workspace._id,
      name: "Master API Development",
      sessionIds: []
    });
    await goal.save();

    // 5. Create Sessions
    const sessionsData = [
      { 
        name: "Session 1: Application Design", 
        statusMode: "completed", 
        tasks: [
          'Define User Personas', 'Create Wireframes', 'Design Mockups', 'Collect Feedback',
          'Database Schema', 'API Endpoints Design', 'Auth Flow', 'Security Rules',
          'Project Structuring', 'Task Prioritization', 'Select Tech Stack', 'Approval'
        ]
      },
      { 
        name: "Session 2: Core Implementation", 
        statusMode: "in_progress", 
        tasks: [
          'Init Repository', 'Setup CI/CD', 'Implement Login', 'Implement Registration',
          'Create Models', 'Write Services', 'Setup Routing', 'Connect Database',
          'State Management', 'Testing Providers', 'Error Handling', 'Logging'
        ]
      },
      { 
        name: "Session 3: Quality Assurance", 
        statusMode: "not_started", 
        tasks: [
          'Write Unit Tests', 'Integration Testing', 'E2E Testing', 'Load Testing',
          'Fix UI Bugs', 'Optimize Performance', 'Review Codebase', 'Audit Security',
          'Write Documentation', 'Prepare Deployment', 'App Store Assets', 'Release'
        ]
      }
    ];

    const sessionIds = [];

    for (const sData of sessionsData) {
      const session = new Session({
        userId: user._id,
        workspaceId: workspace._id,
        goalId: goal._id,
        goalSnapshot: { _id: goal._id, name: goal.name },
        name: sData.name,
        taskIds: []
      });
      await session.save();

      const taskIds = [];
      const priorities = ['low', 'medium', 'high', 'milestone'];
      const now = new Date();

      for (let i = 0; i < sData.tasks.length; i++) {
        let status = 'not_started';
        let timeSpent = 0;

        if (sData.statusMode === 'completed') {
          status = 'completed';
          timeSpent = 3600; // 1 hour
        } else if (sData.statusMode === 'in_progress') {
          if (i < sData.tasks.length / 2) {
            status = 'completed';
            timeSpent = 3600;
          } else if (i === Math.floor(sData.tasks.length / 2)) {
            status = 'in_progress';
            timeSpent = 1800; // 30 mins
          }
        }

        const task = new Task({
          sessionId: session._id,
          goalId: goal._id,
          workspaceId: workspace._id,
          name: sData.tasks[i],
          priority: priorities[i % 4],
          deadline: new Date(now.getTime() + (i * 24 * 60 * 60 * 1000)), // spaced by 1 day
          sessionType: 'timed',
          status: status,
          selected: false,
          timer: {
            totalAllocatedTime: 3600,
            timeSpent: timeSpent
          }
        });
        await task.save();
        taskIds.push(task._id);
      }

      session.taskIds = taskIds;
      await session.save();
      sessionIds.push(session._id);
    }

    goal.sessionIds = sessionIds;
    await goal.save();

    console.log('Successfully seeded database!');
    process.exit(0);

  } catch (err) {
    console.error('Error seeding database:', err);
    process.exit(1);
  }
}

seed();
