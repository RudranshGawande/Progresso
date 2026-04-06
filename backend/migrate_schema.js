/**
 * Migration Script: Fix database schema to match new structure
 * 
 * Changes:
 * 1. User: Remove communityWorkspaceId, keep personalWorkspaceId, add communityWorkspaceIds array
 * 2. Session: Remove userId, add taskId (required), derive workspace through task
 * 3. Task: Remove sessionId back-reference
 * 4. FocusSession: Remove userId
 * 5. Assignment: Change sessionId -> taskId, add assignedBy, move from personal to community workspaces
 * 6. Workspace: Ensure all personal workspaces have no extra members
 */

require('dotenv').config();
const mongoose = require('mongoose');

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB Atlas'))
  .catch(err => { console.error('❌ Connection failed:', err); process.exit(1); });

const User = require('./models/User');
const Workspace = require('./models/Workspace');
const Goal = require('./models/Goal');
const Session = require('./models/Session');
const Task = require('./models/Task');
const FocusSession = require('./models/FocusSession');
const Assignment = require('./models/Assignment');

async function migrate() {
  console.log('🚀 Starting migration...\n');

  // ── STEP 1: Fix User model ──────────────────────────────────────
  console.log('📋 STEP 1: Fixing User model...');

  // Remove defaultPersonalWorkspaceId and communityWorkspaceId fields
  const userUpdateResult = await User.updateMany(
    {},
    {
      $unset: { defaultPersonalWorkspaceId: '', communityWorkspaceId: '' },
    }
  );
  console.log(`   Removed legacy fields from ${userUpdateResult.modifiedCount} users`);

  // Ensure personalWorkspaceId is set for all users
  const usersWithoutPersonalWS = await User.find({ personalWorkspaceId: { $exists: false } });
  for (const user of usersWithoutPersonalWS) {
    let personalWS = await Workspace.findOne({ ownerId: user._id, type: 'personal' });
    if (!personalWS) {
      personalWS = new Workspace({
        name: "Personal Workspace",
        type: "personal",
        ownerId: user._id,
        ownerSnapshot: { email: user.email, name: user.name },
        members: [{ userId: user._id, email: user.email, name: user.name, role: "admin" }]
      });
      await personalWS.save();
      console.log(`   Created personal workspace for user ${user.email}`);
    }
    user.personalWorkspaceId = personalWS._id;
    await user.save();
  }
  console.log(`   Fixed personalWorkspaceId for ${usersWithoutPersonalWS.length} users`);

  // Build communityWorkspaceIds array from community workspaces user owns or is member of
  const allUsers = await User.find({});
  for (const user of allUsers) {
    const communityWorkspaces = await Workspace.find({
      $or: [
        { ownerId: user._id, type: 'community' },
        { 'members.userId': user._id, type: 'community' }
      ]
    });
    const communityIds = communityWorkspaces.map(ws => ws._id);
    user.communityWorkspaceIds = communityIds;
    await user.save();
  }
  console.log(`   Set communityWorkspaceIds for ${allUsers.length} users`);

  // ── STEP 2: Fix personal workspaces (remove extra members) ──────
  console.log('\n📋 STEP 2: Fixing personal workspaces...');
  const personalWorkspaces = await Workspace.find({ type: 'personal' });
  let fixedWorkspaces = 0;
  for (const ws of personalWorkspaces) {
    if (ws.members.length > 1) {
      ws.members = ws.members.filter(m => m.userId.toString() === ws.ownerId.toString());
      await ws.save();
      fixedWorkspaces++;
    }
  }
  console.log(`   Fixed ${fixedWorkspaces} personal workspaces with extra members`);

  // ── STEP 3: Fix Sessions - remove userId, add taskId ────────────
  console.log('\n📋 STEP 3: Fixing Sessions...');

  // Sessions that have taskIds[] array - link to first task
  const sessionsWithTasks = await Session.find({ taskIds: { $exists: true, $ne: [] } });
  for (const session of sessionsWithTasks) {
    const firstTaskId = session.taskIds[0];
    session.taskId = firstTaskId;
    session.userId = undefined;
    await session.save({ validateBeforeSave: false });
  }
  console.log(`   Linked ${sessionsWithTasks.length} sessions to tasks from taskIds array`);

  // Sessions without taskIds - find or create a task for them
  const sessionsWithoutTasks = await Session.find({ $or: [{ taskIds: { $exists: false } }, { taskIds: [] }, { taskId: { $exists: false } }] });
  for (const session of sessionsWithoutTasks) {
    if (session.goalId) {
      // Create a task for this session under the goal
      const task = new Task({
        workspaceId: session.workspaceId,
        goalId: session.goalId,
        name: session.name || 'Untitled Task',
        status: 'in_progress'
      });
      await task.save();
      session.taskId = task._id;
    } else {
      // Create a standalone task in the workspace
      const task = new Task({
        workspaceId: session.workspaceId,
        name: session.name || 'Untitled Task',
        status: 'in_progress'
      });
      await task.save();
      session.taskId = task._id;
    }
    session.userId = undefined;
    session.taskIds = undefined;
    await session.save({ validateBeforeSave: false });
  }
  console.log(`   Created tasks for ${sessionsWithoutTasks.length} orphaned sessions`);

  // Remove taskIds array and userId from all sessions
  await Session.updateMany({}, { $unset: { taskIds: '', userId: '' } });
  console.log('   Removed legacy taskIds[] and userId fields from all sessions');

  // ── STEP 4: Fix Tasks - remove sessionId ────────────────────────
  console.log('\n📋 STEP 4: Fixing Tasks...');
  const taskUpdateResult = await Task.updateMany({}, { $unset: { sessionId: '' } });
  console.log(`   Removed sessionId from ${taskUpdateResult.modifiedCount} tasks`);

  // ── STEP 5: Fix FocusSessions - remove userId ───────────────────
  console.log('\n📋 STEP 5: Fixing FocusSessions...');
  const focusUpdateResult = await FocusSession.updateMany({}, { $unset: { userId: '' } });
  console.log(`   Removed userId from ${focusUpdateResult.modifiedCount} focus sessions`);

  // ── STEP 6: Fix Assignments - sessionId -> taskId, add assignedBy
  console.log('\n📋 STEP 6: Fixing Assignments...');

  const assignments = await Assignment.find({});
  let movedAssignments = 0;
  let fixedAssignments = 0;

  for (const assignment of assignments) {
    const workspace = await Workspace.findById(assignment.workspaceId);

    // If assignment is in a personal workspace, move to community workspace
    if (workspace && workspace.type === 'personal') {
      const owner = await User.findById(workspace.ownerId);
      if (owner && owner.communityWorkspaceIds && owner.communityWorkspaceIds.length > 0) {
        // Move to first community workspace
        const communityWS = await Workspace.findById(owner.communityWorkspaceIds[0]);
        if (communityWS) {
          assignment.workspaceId = communityWS._id;
          movedAssignments++;
        }
      }
    }

    // If assignment has sessionId instead of taskId, migrate
    if (assignment.sessionId && !assignment.taskId) {
      // Find a task in the same workspace or create one
      const task = await Task.findOne({ workspaceId: assignment.workspaceId });
      if (task) {
        assignment.taskId = task._id;
      } else {
        const newTask = new Task({
          workspaceId: assignment.workspaceId,
          name: assignment.title || 'Assigned Task',
          status: 'not_started'
        });
        await newTask.save();
        assignment.taskId = newTask._id;
      }
    }

    // Set assignedBy if missing (use workspace owner as default)
    if (!assignment.assignedBy && workspace) {
      assignment.assignedBy = workspace.ownerId;
    }

    // Rename assigneeId -> assignedTo
    if (assignment.assigneeId && !assignment.assignedTo) {
      assignment.assignedTo = assignment.assigneeId;
    }

    await assignment.save({ validateBeforeSave: false });
    fixedAssignments++;
  }

  // Clean up legacy fields
  await Assignment.updateMany({}, { $unset: { sessionId: '', assigneeId: '' } });
  console.log(`   Fixed ${fixedAssignments} assignments, moved ${movedAssignments} from personal to community workspaces`);

  // ── STEP 7: Verify integrity ────────────────────────────────────
  console.log('\n📋 STEP 7: Verifying integrity...');

  // Check all sessions have taskId
  const sessionsWithoutTaskId = await Session.countDocuments({ taskId: { $exists: false } });
  console.log(`   Sessions without taskId: ${sessionsWithoutTaskId}`);

  // Check all tasks have workspaceId
  const tasksWithoutWorkspace = await Task.countDocuments({ workspaceId: { $exists: false } });
  console.log(`   Tasks without workspaceId: ${tasksWithoutWorkspace}`);

  // Check all assignments are in community workspaces
  const assignmentsInPersonal = await Assignment.countDocuments({}).then(async (count) => {
    const allAssignments = await Assignment.find({}).populate('workspaceId');
    return allAssignments.filter(a => a.workspaceId && a.workspaceId.type === 'personal').length;
  });
  console.log(`   Assignments still in personal workspaces: ${assignmentsInPersonal}`);

  // Check all users have personalWorkspaceId
  const usersWithoutPersonalWS = await User.countDocuments({ personalWorkspaceId: { $exists: false } });
  console.log(`   Users without personalWorkspaceId: ${usersWithoutPersonalWS}`);

  console.log('\n✅ Migration complete!');
  process.exit(0);
}

migrate().catch(err => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
