require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const speakeasy = require('speakeasy');
const crypto = require('crypto');

// Models
const User = require('./models/User');
const UserProfile = require('./models/UserProfile');
const Workspace = require('./models/Workspace');
const Goal = require('./models/Goal');
const Session = require('./models/Session');
const Task = require('./models/Task');
const AuthSession = require('./models/AuthSession');

const app = express();
app.use(cors());
app.use(express.json());

// ── CONNECT TO MONGODB ───────────────────────────────────────────
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB Atlas'))
  .catch(err => console.error('❌ Connection failed:', err));


// ── AUTH MIDDLEWARE ──────────────────────────────────────────────
const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) throw new Error('No token provided');
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) throw new Error('User not found');
    
    req.user = user;
    req.token = token;

    // Optional: Update last active time for the current session
    // This could also be done in a separate middleware to avoid overhead on every request
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    await AuthSession.updateOne(
      { userId: user._id, tokenHash, isActive: true },
      { $set: { lastActive: new Date() } }
    );

    next();
  } catch (e) {
    res.status(401).json({ error: 'Please authenticate.' });
  }
};


// ── ROUTES ──────────────────────────────────────────────────────

// 1. Auth: Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 8);
    const user = new User({ 
      name,
      email,
      password: hashedPassword
    });

    // STEP 1: Save User initially to get _id
    await user.save();
    
    // STEP 2: Create a new workspace
    const personalWorkspace = new Workspace({
      name: "Personal Workspace",
      type: "personal",
      ownerId: user._id,
      ownerSnapshot: { email: user.email },
      members: [
        { userId: user._id, email: user.email, role: "admin" }
      ]
    });

    // STEP 3: Save the workspace
    await personalWorkspace.save();

    // STEP 4: Update the user with default workspace ID
    user.defaultPersonalWorkspaceId = personalWorkspace._id;
    user.personalWorkspaceId = personalWorkspace._id; // Also keep for legacy compatibility if needed
    
    // STEP 5: Save the user again
    await user.save();

    // STEP 6: Create or update a user_profiles document.
    const profile = await UserProfile.findOneAndUpdate(
      { userId: user.email.toLowerCase() },
      { 
        $set: {
          userObjectId: user._id,
          'profile.name': user.name,
          'profile.bio': '',
          'profile.avatarUrl': '',
          'profile.avatarBase64': '',
        },
        $setOnInsert: {
          'security.twoFactorEnabled': false,
          'security.twoFactorSecret': '',
        }
      },
      { upsert: true, new: true }
    );

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET);
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // Create a login session
    await AuthSession.create({
      userId: user._id,
      tokenHash,
      deviceName: req.header('X-Device-Name') || 'Unknown Device',
      deviceType: req.header('X-Device-Type') || 'Desktop',
      osInfo: req.header('X-OS-Info') || 'Unknown OS',
      ipAddress: req.ip || req.header('x-forwarded-for') || req.socket.remoteAddress,
      userAgent: req.header('user-agent'),
    });

    // Include security in response
    const userObj = user.toObject();
    userObj.security = profile.security;

    res.status(201).json({ 
      token, 
      user: userObj,
      userId: user._id,
      email: user.email,
      defaultPersonalWorkspaceId: user.defaultPersonalWorkspaceId 
    });
  } catch (e) {
    console.error('❌ Registration Exception:', e);
    res.status(400).json({ error: e.message });
  }
});

// 2. Auth: Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) throw new Error('Invalid login');

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) throw new Error('Invalid login');

    // VALIDATION Fallback: If defaultPersonalWorkspaceId is missing, try to find or create one
    if (!user.defaultPersonalWorkspaceId) {
      const personalWS = await Workspace.findOne({ ownerId: user._id, type: 'personal' });
      if (personalWS) {
        user.defaultPersonalWorkspaceId = personalWS._id;
        await user.save();
      } else {
        const newWS = new Workspace({
          name: "Personal Workspace",
          type: "personal",
          ownerId: user._id,
          ownerSnapshot: { email: user.email },
          members: [{ userId: user._id, email: user.email, role: "admin" }]
        });
        await newWS.save();
        user.defaultPersonalWorkspaceId = newWS._id;
        await user.save();
      }
    }
 
    // BACKFILL: Ensure a user_profiles document exists for all users.
    let profile = await UserProfile.findOne({ userId: user.email.toLowerCase() });
    if (!profile) {
      profile = await UserProfile.create({
        userId: user.email,
        userObjectId: user._id,
        profile: {
          name: user.name,
          bio: user.bio || '',
          avatarUrl: user.imageUrl || '',
        },
        security: {
          twoFactorEnabled: false,
          twoFactorSecret: '',
        },
      });
    }

    if (profile.security.twoFactorEnabled) {
      return res.status(202).json({
        message: 'MFA_REQUIRED',
        email: user.email,
        secret: 'HIDDEN' // Don't send real secret
      });
    }

    const userObj = user.toObject();
    // Ensure security details are attached to the login response
    userObj.security = profile ? profile.security : { twoFactorEnabled: false };

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET);
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // Create a login session
    await AuthSession.create({
      userId: user._id,
      tokenHash,
      deviceName: req.header('X-Device-Name') || 'Unknown Device',
      deviceType: req.header('X-Device-Type') || 'Desktop',
      osInfo: req.header('X-OS-Info') || 'Unknown OS',
      ipAddress: req.ip || req.header('x-forwarded-for') || req.socket.remoteAddress,
      userAgent: req.header('user-agent'),
    });

    res.json({ 
      token, 
      user: userObj,
      userId: user._id, 
      email: user.email,
      defaultPersonalWorkspaceId: user.defaultPersonalWorkspaceId
    });
  } catch (e) {
    res.status(400).json({ error: 'Login failed' });
  }
});

// 2.5 Auth: 2FA Login Verify
app.post('/api/auth/2fa/login', async (req, res) => {
  try {
    const { email, token } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const profile = await UserProfile.findOne({ userId: email.toLowerCase() });
    if (!profile || !profile.security.twoFactorEnabled) {
      return res.status(400).json({ error: '2FA not enabled' });
    }

    const verified = speakeasy.totp.verify({
      secret: profile.security.twoFactorSecret,
      encoding: 'base32',
      token
    });

    if (verified) {
      const jwtToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET);
      const tokenHash = crypto.createHash('sha256').update(jwtToken).digest('hex');

      await AuthSession.create({
        userId: user._id,
        tokenHash,
        deviceName: req.header('X-Device-Name') || 'Unknown Device',
        deviceType: req.header('X-Device-Type') || 'Desktop',
        osInfo: req.header('X-OS-Info') || 'Unknown OS',
        ipAddress: req.ip || req.header('x-forwarded-for') || req.socket.remoteAddress,
        userAgent: req.header('user-agent'),
      });

      res.json({
        token: jwtToken,
        user,
        userId: user._id,
        email: user.email,
        defaultPersonalWorkspaceId: user.defaultPersonalWorkspaceId
      });
    } else {
      res.status(401).json({ error: 'Invalid 2FA code' });
    }
  } catch (e) {
    res.status(500).json({ error: '2FA login failed' });
  }
});

// 3. Auth: Update Profile
app.put('/api/auth/profile', auth, async (req, res) => {
  try {
    const { name, email, bio, imageUrl, rotation, localImagePath, avatarBase64 } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    if (name !== undefined) user.name = name;
    if (email !== undefined) {
      const existing = await User.findOne({ email });
      if (existing && existing._id.toString() !== user._id.toString()) {
        return res.status(400).json({ error: 'Email already in use' });
      }
      user.email = email;
    }
    
    if (bio !== undefined) user.bio = bio;
    if (imageUrl !== undefined) user.imageUrl = imageUrl;
    if (rotation !== undefined) user.rotation = rotation;
    if (localImagePath !== undefined) user.localImagePath = localImagePath;
    if (avatarBase64 !== undefined) user.avatarBase64 = avatarBase64;

    await user.save();

    // Keep user_profiles in sync with the authoritative users document.
    const profileUpdate = {};
    if (name      !== undefined) profileUpdate['profile.name']        = user.name;
    if (bio       !== undefined) profileUpdate['profile.bio']         = user.bio;
    if (imageUrl  !== undefined) profileUpdate['profile.avatarUrl']   = user.imageUrl || '';
    if (avatarBase64 !== undefined) profileUpdate['profile.avatarBase64'] = user.avatarBase64 || '';

    if (Object.keys(profileUpdate).length > 0) {
      await UserProfile.updateOne(
        { userId: req.user.email.toLowerCase() },
        { $set: profileUpdate },
        { upsert: true }
      );
    }

    const updatedProfile = await UserProfile.findOne({ userId: user.email.toLowerCase() });
    const userObj = user.toObject();
    userObj.security = updatedProfile ? updatedProfile.security : { twoFactorEnabled: false };

    res.json({ message: 'Profile updated successfully', user: userObj });
  } catch (e) {
    res.status(400).json({ error: 'Failed to update profile' });
  }
});

// 4. Auth: 2FA Setup
app.post('/api/auth/2fa/setup', auth, async (req, res) => {
  try {
    const user = req.user;
    const emailSafe = user.email.toLowerCase();
    
    // Fetch profile to check if 2FA is already enabled
    const profile = await UserProfile.findOne({ userId: emailSafe });
    if (profile && profile.security.twoFactorEnabled) {
      return res.status(400).json({ error: '2FA is already enabled' });
    }

    const secret = speakeasy.generateSecret({
      name: `Progresso (${user.email})`,
      issuer: 'Progresso'
    });

    // Store the temporary secret until verified
    await UserProfile.updateOne(
      { userId: emailSafe },
      { $set: { 'security.tempSecret': secret.base32 } },
      { upsert: true }
    );

    res.json({
      secret: secret.base32,
      otpauthUrl: secret.otpauth_url
    });
  } catch (e) {
    console.error('2FA Setup Error:', e);
    res.status(500).json({ error: 'Failed to initialize 2FA setup' });
  }
});

// 5. Auth: 2FA Verify (Enable)
app.post('/api/auth/2fa/verify', auth, async (req, res) => {
  try {
    const { token } = req.body;
    const profile = await UserProfile.findOne({ userId: req.user.email.toLowerCase() });
    
    if (!profile || !profile.security.tempSecret) {
      return res.status(400).json({ error: '2FA setup not initialized' });
    }

    const verified = speakeasy.totp.verify({
      secret: profile.security.tempSecret,
      encoding: 'base32',
      token
    });

    if (verified) {
      profile.security.twoFactorEnabled = true;
      profile.security.twoFactorSecret = profile.security.tempSecret;
      profile.security.tempSecret = undefined;
      await profile.save();
      
      res.json({ message: '2FA enabled successfully' });
    } else {
      res.status(400).json({ error: 'Invalid verification code' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Verification failed' });
  }
});

// 6. Auth: 2FA Disable
app.post('/api/auth/2fa/disable', auth, async (req, res) => {
  try {
    const { token } = req.body;
    const profile = await UserProfile.findOne({ userId: req.user.email.toLowerCase() });

    if (!profile || !profile.security.twoFactorEnabled) {
      return res.status(400).json({ error: '2FA is not enabled' });
    }

    const verified = speakeasy.totp.verify({
      secret: profile.security.twoFactorSecret,
      encoding: 'base32',
      token
    });

    if (verified) {
      profile.security.twoFactorEnabled = false;
      profile.security.twoFactorSecret = '';
      await profile.save();
      res.json({ message: '2FA disabled successfully' });
    } else {
      res.status(400).json({ error: 'Invalid verification code' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Failed to disable 2FA' });
  }
});

// 7. Auth: Get Profile
app.get('/api/auth/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    // Fetch security settings from UserProfile
    const profile = await UserProfile.findOne({ userId: user.email.toLowerCase() });
    const userObj = user.toObject();
    userObj.security = profile ? profile.security : { twoFactorEnabled: false };
    
    res.json({ user: userObj });
  } catch (e) {
    res.status(400).json({ error: 'Failed to fetch profile' });
  }
});

// 5. Auth: Delete Account
app.delete('/api/auth/profile', auth, async (req, res) => {
  try {
    const userId = req.user._id;
    await Workspace.deleteMany({ userId });
    await Goal.deleteMany({ workspaceId: { $in: [req.user.personalWorkspaceId, req.user.communityWorkspaceId] } });
    await Session.deleteMany({ userId });
    await Task.deleteMany({ userId });
    
    await User.findByIdAndDelete(userId);
    res.json({ message: 'Account and all associated data deleted successfully' });
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete account' });
  }
});

// ── WORKSPACE ROUTES ────────────────────────────────────────────────
app.get('/api/workspaces', auth, async (req, res) => {
  try {
    // Find workspaces where user is owner OR a member
    const workspaces = await Workspace.find({
      $or: [
        { ownerId: req.user._id },
        { 'members.userId': req.user._id }
      ]
    });
    res.json(workspaces);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/workspaces', auth, async (req, res) => {
  try {
    const { name, type } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const workspace = new Workspace({
      name,
      type,
      ownerId: user._id,
      ownerSnapshot: { email: user.email },
      members: [
        { userId: user._id, email: user.email, role: 'admin' }
      ]
    });

    await workspace.save();
    res.status(201).json(workspace);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Additional Route: Add Member to Community Workspace
app.post('/api/workspaces/:id/members', auth, async (req, res) => {
  try {
    const { email } = req.body;
    const workspace = await Workspace.findById(req.params.id);
    
    if (!workspace) return res.status(404).json({ error: 'Workspace not found' });
    if (workspace.type !== 'community') return res.status(400).json({ error: 'Can only add members to community workspaces' });
    
    // Authorization: User must be an admin of the workspace to add members
    const isAdmin = workspace.members.some(m => m.userId.toString() === req.user._id.toString() && m.role === 'admin');
    if (!isAdmin) return res.status(403).json({ error: 'Only admins can add members' });

    // Check if user exists
    const newUser = await User.findOne({ email });
    if (!newUser) return res.status(404).json({ error: 'User not found with this email' });

    // Check for duplicate
    const isDuplicate = workspace.members.some(m => m.email === email);
    if (isDuplicate) return res.status(400).json({ error: 'User already in workspace' });

    workspace.members.push({
      userId: newUser._id,
      email: newUser.email,
      role: 'member'
    });

    await workspace.save();
    res.json(workspace);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── GOAL ROUTES ─────────────────────────────────────────────────────
app.get('/api/goals', auth, async (req, res) => {
  try {
    const { workspaceId } = req.query;
    if (!workspaceId) return res.status(400).json({ error: 'workspaceId required' });
    
    const goals = await Goal.find({ workspaceId });
    res.json(goals);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/goals', auth, async (req, res) => {
  try {
    const goal = new Goal({
      ...req.body
    });
    await goal.save();
    res.status(201).json(goal);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.put('/api/goals/:id', auth, async (req, res) => {
  try {
    const goal = await Goal.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!goal) return res.status(404).json({ error: 'Goal not found' });
    res.json(goal);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.delete('/api/goals/:id', auth, async (req, res) => {
  try {
    const goal = await Goal.findByIdAndDelete(req.params.id);
    if (!goal) return res.status(404).json({ error: 'Goal not found' });
    res.json({ message: 'Goal deleted' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── SESSION ROUTES ──────────────────────────────────────────────────
app.get('/api/sessions', auth, async (req, res) => {
  try {
    const { workspaceId } = req.query;
    if (!workspaceId) return res.status(400).json({ error: 'workspaceId required' });
    
    const sessions = await Session.find({ workspaceId, userId: req.user._id });
    res.json(sessions);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/sessions', auth, async (req, res) => {
  try {
    const session = new Session({
      ...req.body,
      userId: req.user._id
    });
    await session.save();

    // Push this session's ObjectId into the Goal's sessionIds array (no duplicates)
    if (req.body.goalId) {
      await Goal.findByIdAndUpdate(
        req.body.goalId,
        { $addToSet: { sessionIds: session._id } }
      );
    }

    res.status(201).json(session);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── TASK ROUTES ─────────────────────────────────────────────────────
app.get('/api/tasks', auth, async (req, res) => {
  try {
    const { sessionId, goalId, workspaceId } = req.query;
    const filter = {};
    if (sessionId) filter.sessionId = sessionId;
    if (goalId) filter.goalId = goalId;
    if (workspaceId) filter.workspaceId = workspaceId;
    
    const tasks = await Task.find(filter);
    res.json(tasks);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/tasks', auth, async (req, res) => {
  try {
    const task = new Task({ ...req.body });
    await task.save();

    // If task is created as part of a session, back-link it
    if (req.body.sessionId) {
      await Session.findByIdAndUpdate(
        req.body.sessionId,
        { $push: { taskIds: task._id } }
      );
    }

    res.status(201).json(task);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.put('/api/tasks/:id', auth, async (req, res) => {
  try {
    const task = await Task.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json(task);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.delete('/api/tasks/:id', auth, async (req, res) => {
  try {
    const task = await Task.findByIdAndDelete(req.params.id);
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json({ message: 'Task deleted' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 8. Security: Get Active Sessions
app.get('/api/auth/sessions', auth, async (req, res) => {
  try {
    const sessions = await AuthSession.find({ userId: req.user._id, isActive: true }).sort({ lastActive: -1 });
    const currentTokenHash = crypto.createHash('sha256').update(req.token).digest('hex');
    
    let sessionList = sessions.map(s => {
      const sessionObj = s.toObject();
      sessionObj.isCurrent = (sessionObj.tokenHash === currentTokenHash);
      return sessionObj;
    });

    const hasCurrent = sessionList.some(s => s.isCurrent);
    if (!hasCurrent) {
      sessionList.unshift({
        _id: 'current',
        deviceName: req.header('X-Device-Name') || 'Current Device',
        deviceType: req.header('X-Device-Type') || 'Desktop',
        osInfo: req.header('X-OS-Info') || 'Unknown OS',
        ipAddress: req.ip || req.header('x-forwarded-for') || req.socket.remoteAddress,
        loginTime: new Date(),
        lastActive: new Date(),
        isCurrent: true
      });
    }

    res.json(sessionList);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch sessions' });
  }
});

// 9. Security: Revoke Session
app.delete('/api/auth/sessions/:id', auth, async (req, res) => {
  try {
    const session = await AuthSession.findOne({ _id: req.params.id, userId: req.user._id });
    if (!session) return res.status(404).json({ error: 'Session not found' });
    
    session.isActive = false;
    await session.save();
    res.json({ message: 'Session revoked successfully' });
  } catch (e) {
    res.status(500).json({ error: 'Failed to revoke session' });
  }
});

// 10. Security: Revoke All Other Sessions
app.delete('/api/auth/sessions', auth, async (req, res) => {
  try {
    const currentTokenHash = crypto.createHash('sha256').update(req.token).digest('hex');
    await AuthSession.updateMany(
      { userId: req.user._id, tokenHash: { $ne: currentTokenHash }, isActive: true },
      { $set: { isActive: false } }
    );
    res.json({ message: 'All other sessions revoked successfully' });
  } catch (e) {
    res.status(500).json({ error: 'Failed to revoke sessions' });
  }
});

// 11. Security: Logout (Revoke current session)
app.post('/api/auth/logout', auth, async (req, res) => {
  try {
    const currentTokenHash = crypto.createHash('sha256').update(req.token).digest('hex');
    await AuthSession.updateOne(
      { userId: req.user._id, tokenHash: currentTokenHash, isActive: true },
      { $set: { isActive: false } }
    );
    res.json({ message: 'Logged out successfully' });
  } catch (e) {
    res.status(500).json({ error: 'Logout failed' });
  }
});

// ── START SERVER ───────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
