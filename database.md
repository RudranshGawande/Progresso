    # Progresso Database Documentation

## Overview

Progresso uses **MongoDB Atlas** as its primary database with a **fire-and-forget sync architecture**. The Flutter app uses `SharedPreferences` as the local source of truth, and all data is continuously synced to MongoDB in the background. Every user action that modifies data triggers an immediate API call to persist the change.

**Architecture Pattern:** Local-first with cloud sync
- **Local:** SharedPreferences (immediate, offline-capable)
- **Cloud:** MongoDB Atlas (persistent, multi-device)
- **Sync:** Bidirectional, triggered on every mutation

---

## Database Structure

### Collections (10 total)

#### 1. `users` — User accounts
```
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  password: String (bcrypt hashed),
  defaultPersonalWorkspaceId: ObjectId → workspaces,
  personalWorkspaceId: ObjectId → workspaces,
  communityWorkspaceId: ObjectId → workspaces,
  bio: String,
  imageUrl: String,
  rotation: Number,
  localImagePath: String,
  avatarBase64: String
}
```

#### 2. `user_profiles` — Extended profile & security
```
{
  _id: ObjectId,
  userId: String (email, unique),
  userObjectId: ObjectId → users,
  profile: {
    name: String,
    bio: String,
    avatarUrl: String,
    avatarBase64: String
  },
  security: {
    twoFactorEnabled: Boolean,
    twoFactorSecret: String,
    tempSecret: String
  }
}
```

#### 3. `auth_sessions` — Login session tracking
```
{
  _id: ObjectId,
  userId: ObjectId → users,
  tokenHash: String (SHA-256),
  deviceName: String,
  deviceType: "Mobile" | "Desktop" | "Tablet",
  osInfo: String,
  ipAddress: String,
  loginTime: Date,
  lastActive: Date,
  userAgent: String,
  isActive: Boolean
}
```

#### 4. `workspaces` — Workspace containers
```
{
  _id: ObjectId,
  name: String,
  type: "personal" | "community",
  description: String,
  iconCode: String,
  ownerId: ObjectId → users,
  ownerSnapshot: { email: String, name: String },
  members: [{
    userId: ObjectId → users,
    email: String,
    name: String,
    avatarUrl: String,
    role: "admin" | "member",
    joinedAt: Date
  }],
  createdAt: Date,
  updatedAt: Date
}
```

#### 5. `goals` — Goal definitions
```
{
  _id: ObjectId,
  workspaceId: ObjectId → workspaces,
  name: String,
  description: String,
  dueDate: Date,
  iconCode: String,
  imageUrl: String,
  status: "active" | "completed" | "paused" | "archived",
  totalTimeSpent: Number (seconds),
  currentStreak: Number,
  dailyEffort: [Number × 7],
  sessionIds: [ObjectId → sessions],
  taskIds: [ObjectId → tasks],
  activityIds: [ObjectId → goalactivities],
  createdAt: Date,
  updatedAt: Date
}
```

#### 6. `tasks` — Individual tasks within goals
```
{
  _id: ObjectId,
  sessionId: ObjectId → sessions,
  goalId: ObjectId → goals,
  workspaceId: ObjectId → workspaces,
  name: String,
  priority: "low" | "medium" | "high",
  deadline: Date,
  sessionType: "free" | "timed",
  isCompleted: Boolean,
  status: "not_started" | "in_progress" | "completed",
  timer: {
    totalAllocatedTime: Number,
    timeSpent: Number
  },
  completedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

#### 7. `sessions` — Focus session containers
```
{
  _id: ObjectId,
  userId: ObjectId → users,
  workspaceId: ObjectId → workspaces,
  goalId: ObjectId → goals,
  goalSnapshot: { _id: ObjectId, name: String },
  name: String,
  taskIds: [ObjectId → tasks],
  status: "active" | "paused" | "completed" | "abandoned",
  startedAt: Date,
  endedAt: Date,
  totalDuration: Number (milliseconds),
  createdAt: Date,
  updatedAt: Date
}
```

#### 8. `focussessions` — Individual focus metrics
```
{
  _id: ObjectId,
  sessionId: ObjectId → sessions,
  taskId: ObjectId → tasks,
  goalId: ObjectId → goals,
  userId: ObjectId → users,
  workspaceId: ObjectId → workspaces,
  duration: Number (seconds),
  intensity: Number (0-1),
  focusScore: Number (0-100),
  trendData: [Number],
  startedAt: Date,
  endedAt: Date,
  createdAt: Date
}
Indexes: taskId+startedAt, goalId+startedAt, userId+startedAt
```

#### 9. `goalactivities` — Activity feed entries
```
{
  _id: ObjectId,
  goalId: ObjectId → goals,
  userId: ObjectId → users,
  title: String,
  type: "goal_created" | "goal_updated" | "goal_completed" | "goal_archived" |
        "task_added" | "task_completed" | "task_deleted" |
        "session_started" | "session_completed" | "session_abandoned",
  taskId: ObjectId → tasks,
  sessionId: ObjectId → sessions,
  metadata: Mixed,
  createdAt: Date
}
Index: goalId+createdAt
```

#### 10. `assignments` — Community workspace tasks
```
{
  _id: ObjectId,
  workspaceId: ObjectId → workspaces,
  sessionId: ObjectId → sessions,
  title: String,
  description: String,
  assigneeId: ObjectId → users,
  assigneeName: String,
  assigneeAvatar: String,
  deadline: Date,
  status: "pending" | "in_progress" | "completed" | "overdue",
  completedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
Indexes: workspaceId+status, assigneeId+status
```

---

## Data Flow Architecture

### 1. Authentication Flow
```
User Login → POST /api/auth/login → JWT + User Object → SharedPreferences
                                    ↓
                            AuthSession created in DB
                                    ↓
                            POST /api/sync → All user data fetched
                                    ↓
                            Local state populated from DB
```

### 2. Goal Lifecycle
```
Create Goal → Local save (SharedPreferences) → POST /api/goals → Goal._id returned
    ↓
Local goal updated with DB ID → saveGoals()
    ↓
GoalActivity created in DB (type: "goal_created")
    ↓
Update Goal → PUT /api/goals/:id → DB updated
    ↓
Delete Goal → DELETE /api/goals/:id → DB deleted
```

### 3. Task Lifecycle
```
Create Task → Local save → POST /api/tasks → Task._id returned
    ↓
Local task updated with DB ID → saveGoals()
    ↓
Goal.taskIds updated in DB ($push)
Session.taskIds updated in DB ($push)
    ↓
Toggle Completion → PUT /api/tasks/:id → status + completedAt updated
    ↓
Delete Task → DELETE /api/tasks/:id → DB deleted + back-links cleaned
```

### 4. Focus Session Lifecycle
```
Start Focus → Local ActiveSession → POST /api/sessions → Session._id
    ↓
Complete Focus → Local save → POST /api/focus-sessions → FocusSession._id
    ↓
Task.timer.timeSpent incremented ($inc)
Goal.totalTimeSpent incremented ($inc)
Session.totalDuration incremented ($inc)
    ↓
GoalActivity created (type: "session_completed")
```

### 5. Activity Feed Flow
```
Any Goal/Task/Session mutation → POST /api/goal-activities → Activity._id
    ↓
Goal.activityIds updated ($push)
    ↓
GET /api/goal-activities → Feed populated
```

### 6. Real-Time Sync Strategy

| Trigger | Action | API Call |
|---|---|---|
| App launch | Fetch all data | `GET /api/sync` |
| Goal created | Save to DB | `POST /api/goals` |
| Goal updated | Sync changes | `PUT /api/goals/:id` |
| Goal deleted | Remove from DB | `DELETE /api/goals/:id` |
| Task created | Save to DB | `POST /api/tasks` |
| Task toggled | Sync status | `PUT /api/tasks/:id` |
| Task deleted | Remove from DB | `DELETE /api/tasks/:id` |
| Focus session | Save metrics | `POST /api/focus-sessions` |
| Session start | Create session | `POST /api/sessions` |
| Session end | Update session | `PUT /api/sessions/:id` |
| Goal status change | Sync status | `PUT /api/goals/:id` |
| Goal stats change | Sync stats | `PUT /api/goals/:id` |
| Assignment created | Save to DB | `POST /api/assignments` |
| Assignment updated | Sync changes | `PUT /api/assignments/:id` |

---

## API Endpoints

### Authentication
| Method | Path | Purpose |
|---|---|---|
| POST | `/api/auth/register` | Register user + create personal workspace |
| POST | `/api/auth/login` | Login + validate workspace + create AuthSession |
| POST | `/api/auth/2fa/login` | Verify 2FA code |
| POST | `/api/auth/logout` | Revoke current AuthSession |
| PUT | `/api/auth/profile` | Update user profile |
| GET | `/api/auth/profile` | Get user profile |
| DELETE | `/api/auth/profile` | Delete account + cascade delete |
| GET | `/api/auth/sessions` | List active AuthSessions |
| DELETE | `/api/auth/sessions/:id` | Revoke AuthSession |
| DELETE | `/api/auth/sessions` | Revoke all other AuthSessions |

### Sync
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/sync` | Fetch ALL user data in one call |

### Workspaces
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/workspaces` | List user's workspaces |
| POST | `/api/workspaces` | Create workspace |
| POST | `/api/workspaces/:id/members` | Add member |

### Goals
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/goals` | List goals by workspace |
| GET | `/api/goals/:id` | Get goal with tasks, activities, focus sessions |
| GET | `/api/goals/:id/stats` | Get goal statistics |
| POST | `/api/goals` | Create goal |
| PUT | `/api/goals/:id` | Update goal |
| DELETE | `/api/goals/:id` | Delete goal |

### Tasks
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/tasks` | List tasks (filterable) |
| POST | `/api/tasks` | Create task |
| PUT | `/api/tasks/:id` | Update task |
| DELETE | `/api/tasks/:id` | Delete task |

### Sessions
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/sessions` | List sessions |
| GET | `/api/sessions/:id` | Get session with tasks, focus sessions |
| POST | `/api/sessions` | Create session |
| PUT | `/api/sessions/:id` | Update session |

### Focus Sessions
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/focus-sessions` | List focus sessions (filterable) |
| POST | `/api/focus-sessions` | Create focus session |
| PUT | `/api/focus-sessions/:id` | Update focus session |
| DELETE | `/api/focus-sessions/:id` | Delete focus session |

### Activities
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/goal-activities` | List activities |
| POST | `/api/goal-activities` | Create activity |

### Assignments
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/assignments` | List assignments |
| POST | `/api/assignments` | Create assignment |
| PUT | `/api/assignments/:id` | Update assignment |
| DELETE | `/api/assignments/:id` | Delete assignment |

---

## Logging Convention

All database operations log with the following format:

**Success:**
```
✅ [ENTITY] CREATED: <id> | <details>
✅ [ENTITY] UPDATED: <id> | <details>
✅ [ENTITY] DELETED: <id>
```

**Failure:**
```
⚠️ [ENTITY] CREATE FAILED: <status> <body>
⚠️ [ENTITY] UPDATE FAILED: <status> <body>
⚠️ [ENTITY] DELETE FAILED: <status> <body>
```

**Error:**
```
❌ [ENTITY] API ERROR: <exception>
```
