# Progresso — Complete Project Documentation

> **Focus. Track. Achieve.** — Your personal productivity command center.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Motto](#motto)
3. [Tech Stack](#tech-stack)
4. [Architecture](#architecture)
5. [Screens & Their Purposes](#screens--their-purposes)
6. [Widgets](#widgets)
7. [Services](#services)
8. [Models](#models)
9. [Database Schema (MongoDB)](#database-schema-mongodb)
10. [API Endpoints](#api-endpoints)
11. [Authentication](#authentication)
12. [Data Flow](#data-flow)
13. [Backend Models](#backend-models)
14. [Theme & Localization](#theme--localization)
15. [Complete Source Code](#complete-source-code)

---

## Project Overview

**Progresso** is a cross-platform productivity application built with **Flutter** (Dart) for the frontend and **Node.js/Express** for the backend. It helps users track focus sessions, manage goals with tasks, analyze productivity patterns, and collaborate in community workspaces.

The app uses a **local-first architecture** where `SharedPreferences` serves as the immediate local data store, with all data continuously synced to **MongoDB Atlas** in the background. Every user action that modifies data triggers an API call to persist the change.

**Key Features:**
- Goal and task management with priorities and deadlines
- Focus session tracking with intensity metrics and focus scores
- Productivity analytics with charts, heatmaps, and trend analysis
- Community/team workspaces with member management
- Two-factor authentication (2FA/TOTP)
- Profile management with avatar upload
- Multi-language support (English, Spanish)
- Light and dark theme support
- Responsive design (mobile, tablet, desktop)

---

## Motto

> **Focus. Track. Achieve.**

---

## Tech Stack

### Frontend
- **Framework:** Flutter (Dart SDK ^3.11.3)
- **State Management:** Provider + ChangeNotifier
- **Local Storage:** SharedPreferences
- **HTTP Client:** http package
- **Charts:** Custom painters (no external chart library)
- **Fonts:** Google Fonts (Inter)
- **Authentication:** JWT (jwt_decoder)
- **Encryption:** encrypt, crypto packages
- **Image Handling:** image, file_picker, desktop_drop, path_provider
- **QR Codes:** qr_flutter
- **Device Info:** device_info_plus
- **Localization:** flutter_localizations (en, es)
- **Internationalization:** intl package

### Backend
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB Atlas (via Mongoose ODM)
- **Authentication:** JWT (jsonwebtoken), bcryptjs
- **2FA:** speakeasy (TOTP)
- **Security:** crypto (SHA-256 hashing)
- **CORS:** cors middleware
- **Environment:** dotenv

### Database
- **MongoDB Atlas** — Cloud-hosted MongoDB
- **10 Collections:** users, user_profiles, auth_sessions, workspaces, goals, tasks, sessions, focussessions, goalactivities, assignments

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Frontend)                    │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌──────────┐ │
│  │ Screens   │  │ Widgets   │  │ Services  │  │ Models   │ │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └────┬─────┘ │
│        │              │              │              │       │
│        └──────────────┴──────────────┼──────────────┘       │
│                                     │                       │
│                    ┌────────────────┼────────────────┐      │
│                    │  SharedPreferences (Local)      │      │
│                    └────────────────┼────────────────┘      │
│                                     │                       │
│                    ┌────────────────▼────────────────┐      │
│                    │  ApiService (HTTP Client)       │      │
│                    └────────────────┬────────────────┘      │
└─────────────────────────────────────┼───────────────────────┘
                                      │ HTTP (JSON)
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Node.js Backend (Port 5000)               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Express.js Routes + Auth Middleware (JWT)            │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Mongoose Models (User, Workspace, Goal, etc.)       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────┬───────────────────────┘
                                      │ Mongoose Driver
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    MongoDB Atlas (Cloud)                     │
│  users | user_profiles | auth_sessions | workspaces         │
│  goals | tasks | sessions | focussessions                   │
│  goalactivities | assignments                               │
└─────────────────────────────────────────────────────────────┘
```

**Architecture Pattern:** Local-first with cloud sync
- **Local:** SharedPreferences (immediate, offline-capable)
- **Cloud:** MongoDB Atlas (persistent, multi-device)
- **Sync:** Bidirectional, triggered on every mutation

---

## Screens & Their Purposes

### Personal Workspace Screens

| Screen | File | Purpose |
|--------|------|---------|
| **Auth Screen** | `lib/screens/auth_screen.dart` | Login/Registration with email+password, Google SSO (placeholder), 2FA verification. Responsive split-panel layout on desktop, stacked on mobile. |
| **Main Shell** | `lib/screens/main_shell.dart` | Primary navigation container. Holds the sidebar/drawer and routes between Dashboard, Goals, Analysis, and Profile tabs. Manages goal detail/archive sub-navigation. |
| **Dashboard** | `lib/screens/dashboard_screen.dart` | Home screen showing stat cards (Total Hours, Focus Score, Daily Goal, Current Streak), weekly progress chart, recent sessions, active goals, focus intensity panel, and CTA to start a focus session. |
| **Goals Overview** | `lib/screens/goals_overview_screen.dart` | Lists all goals with search, summary stats (Tasks in Progress, Total Completed, Overall Efficiency), goal cards with progress bars, upcoming milestones timeline, and daily focus tags. |
| **Goal Detail** | `lib/screens/goal_detail_screen.dart` | Detailed view of a single goal. Shows task list with add/search/filter/sort, task priority (high/medium/low/milestone), deadline picker, focus session start (free/timed), recent activity feed, analytics card, and milestone tracking. |
| **Goal Archive** | `lib/screens/goal_archive_screen.dart` | Shows completed/archived tasks for a goal. Grouped by date (TODAY, YESTERDAY, etc.), sortable by newest/oldest/priority/completion duration. Supports un-completing tasks and permanent deletion. |
| **Focus Session** | `lib/screens/focus_session_screen.dart` | Active focus timer screen. Large circular progress ring, real-time elapsed/remaining time display, deep work intensity indicator with pulsing dot, pause/resume/stop controls, and trend data collection every 5 seconds. |
| **Focus Summary** | `lib/screens/focus_summary_screen.dart` | Post-session summary card. Shows total duration, intensity (circular gauge), focus score, animated focus trend bar chart, and options to keep task active or archive it. |
| **Analysis** | `lib/screens/analysis_screen.dart` | Deep productivity analytics. Period selector (Today/Week/Month/Year/Custom), stat cards with period-over-period trends, productivity trend line charts, time allocation donut charts, consistency heatmap (GitHub-style), weekly bar charts, and focus vs break timeline. |
| **Profile** | `lib/screens/profile_screen.dart` | User profile management with three sections: Personal Information (name, email, bio, avatar with drag-drop editor), Account Settings (language, timezone, week start, delete account), and Security (change password, 2FA setup/disable with QR code, active device management). |

### Community Workspace Screens

| Screen | File | Purpose |
|--------|------|---------|
| **Community Dashboard** | `lib/screens/community_dashboard.dart` | Team productivity overview with stat cards (Team Focus Hours, Active Members, Total Sessions, Productivity Score), team focus intensity chart, workload distribution bars, member activity table, active sessions, and community goals. |
| **Community Dashboard Screen** | `lib/screens/community_dashboard_screen.dart` | Alternative community view with team efficiency stats, member activity summary, and session progress tracking bars. |
| **Community Goals** | `lib/screens/community_goals_screen.dart` | Shared team goals with collaborative progress cards showing contributors, deadlines, and progress bars. |
| **Community Analysis** | `lib/screens/community_analysis_screen.dart` | Team productivity analysis with contribution heatmaps, member leaderboards, and session progress metrics. Admin vs member views. |
| **Sessions Overview** | `lib/screens/sessions_overview_screen.dart` | Community session cards showing active/archived status, assignment counts, and member avatar stacks. |
| **Session Detail** | `lib/screens/session_detail_screen.dart` | Individual community session view with task/assignment list, checkboxes, assignee avatars, and live activity sidebar. |

---

## Widgets

| Widget | File | Purpose |
|--------|------|---------|
| **Sidebar** | `lib/widgets/sidebar.dart` | Navigation sidebar with tabs: Dashboard, Goals, Analysis, Profile. Workspace switcher for personal/community. |
| **Responsive** | `lib/widgets/responsive.dart` | Breakpoint utilities: `isMobile`, `isTablet`, `isDesktop` based on screen width. |
| **Dashboard Header** | `lib/widgets/dashboard_header.dart` | Top bar with greeting, date, and quick actions. |
| **Stat Card** | `lib/widgets/stat_card.dart` | Reusable metric card with icon, value, label, and trend indicator. |
| **Weekly Chart** | `lib/widgets/weekly_chart.dart` | Bar chart showing weekly focus hours. |
| **Recent Sessions** | `lib/widgets/recent_sessions.dart` | List of recent focus sessions with goal/task context. |
| **Active Goals** | `lib/widgets/active_goals.dart` | Grid of active goal cards with progress. |
| **Focus Intensity** | `lib/widgets/focus_intensity.dart` | Line chart showing focus intensity trends. |
| **Focus Session Dialog** | `lib/widgets/focus_session_dialog.dart` | Modal dialog to start a focus session, select goal and task. |
| **Quick Focus Dialog** | `lib/widgets/quick_focus_dialog.dart` | Quick-start focus session without full navigation. |
| **Session Type Selection** | `lib/widgets/session_type_selection_dialog.dart` | Choose between free (untimed) or timed focus sessions with duration picker. |
| **Create Goal Dialog** | `lib/widgets/create_goal_dialog.dart` | Form to create or edit a goal with title, description, icon, image, and due date. |
| **Create Community Dialog** | `lib/widgets/create_community_dialog.dart` | Form to create a new community workspace. |
| **Assign Task Dialog** | `lib/widgets/assign_task_dialog.dart` | Assign tasks to community members. |
| **Custom Date Range Picker** | `lib/widgets/custom_date_range_picker.dart` | Custom calendar for selecting date ranges in analysis. |
| **CTA Banner** | `lib/widgets/cta_banner.dart` | Call-to-action banner to start focus sessions. |
| **Workspace Switcher** | `lib/widgets/workspace_switcher.dart` | Dropdown to switch between personal and community workspaces. |

---

## Services

### AuthService (`lib/services/auth_service.dart`)
- **Singleton** ChangeNotifier managing user authentication state
- **Login:** POST `/api/auth/login` with device headers, supports demo bypass for `demo@progressor.com` / `pass123`
- **2FA Login:** POST `/api/auth/2fa/login` for TOTP verification
- **Register:** POST `/api/auth/register` creates user + personal workspace
- **Profile Update:** PUT `/api/auth/profile` with avatar base64 support
- **Delete Account:** DELETE `/api/auth/profile` cascades all data
- **Session Management:** JWT stored in SharedPreferences, auto-expiry check
- **Key Methods:** `login()`, `register()`, `logout()`, `isLoggedIn()`, `updateProfile()`, `deleteAccount()`, `refreshUser()`, `verifyLogin2fa()`

### GoalService (`lib/services/goal_service.dart`)
- **Singleton** ChangeNotifier managing goals, tasks, sessions, and activities
- **Storage:** User-specific SharedPreferences key (`progresso_goals_$userId`)
- **Demo Data:** Generates realistic demo goals for demo users with 36+ tasks across 3 goals
- **CRUD:** `addGoal()`, `updateGoal()`, `deleteGoal()`, `addTask()`, `toggleTaskCompletion()`, `deleteTask()`, `addSessionToTask()`
- **DB Sync:** Persists focus sessions to MongoDB via ApiService
- **Workspace Filtering:** Filters goals by active workspace (personal/community)

### SessionManager (`lib/services/session_manager.dart`)
- **Singleton** ChangeNotifier managing active focus sessions
- **Storage:** User-specific SharedPreferences key (`progresso_sessions_$userId`)
- **Session Lifecycle:** `startSession()`, `pauseSession()`, `resumeSession()`, `completeSession()`, `deleteSession()`
- **Elapsed Time:** Calculates real-time elapsed time accounting for pauses
- **Update Timer:** Notifies listeners every minute for active sessions

### ApiService (`lib/services/api_service.dart`)
- **Singleton** thin REST client for MongoDB persistence
- **Base URL:** `http://127.0.0.1:5000/api`
- **Auth:** Automatically attaches JWT Bearer token to all requests
- **Fire-and-forget:** All methods log errors but don't throw — local state is always source of truth
- **Endpoints:** `createGoal()`, `updateGoal()`, `createSession()`, `createTask()`, `updateTask()`

### SecurityService (`lib/services/security_service.dart`)
- **Singleton** handling 2FA and session management
- **2FA Setup:** POST `/api/auth/2fa/setup` generates TOTP secret + QR data
- **2FA Verify:** POST `/api/auth/2fa/verify` enables 2FA after OTP confirmation
- **2FA Disable:** POST `/api/auth/2fa/disable` requires OTP to disable
- **Session Management:** `getActiveSessions()`, `revokeSession()`, `revokeAllOtherSessions()`

### WorkspaceService (`lib/services/workspace_service.dart`)
- **Singleton** ChangeNotifier managing workspace context
- **Workspace Types:** `personal` or `community`
- **Storage:** User-specific SharedPreferences key (`progresso_communities_$userId`)
- **Methods:** `switchWorkspace()`, `addCommunity()`, `deleteCommunity()`
- **Demo:** Creates default "IETK" community for demo users

### CommunityService (`lib/services/community_service.dart`)
- **Singleton** ChangeNotifier managing community data
- **Features:** Invite members, create/assign/claim tasks, update task status, remove members, update roles
- **Activity Feed:** Tracks team activities (joined, assigned, claimed, created)
- **Storage:** SharedPreferences with JSON serialization

### MongoDBService (`lib/services/mongodb_service.dart`)
- **Singleton** direct MongoDB connection (currently disabled — connection string is empty)
- **Purpose:** Was intended for direct client-side DB access; all DB operations now go through the Node.js backend API
- **Connection String:** Stored but not actively used for security reasons

---

## Models

### Goal Models (`lib/models/goal_models.dart`)

**Enums:**
- `TaskPriority`: high, medium, low, milestone
- `GoalStatus`: active, completed, paused
- `SessionStatus`: active, paused, completed
- `FocusSessionType`: free, timed
- `ActivityType`: taskCompleted, sessionCompleted, taskAdded, goalCreated

**Classes:**
- `FocusSession`: id, duration, intensity (0.0-1.0), focusScore (0-100), trendData (list of doubles), timestamp
- `GoalTask`: id, name, priority, deadline, isCompleted, createdAt, completedAt, timeSpent, sessions (list), sessionType, defaultDuration
- `ActiveSession`: sessionId, taskId, goalId, status, totalElapsedTime (ms), totalDuration (ms), lastResumeTime, pausedAt, endedAt
- `GoalActivity`: id, title, timestamp, type, taskId
- `Goal`: id, workspaceId, title, description, dueDate, status, icon (IconData), imageUrl, tasks, activities, totalTimeSpent, currentStreak, dailyEffort (7 values Mon-Sun)
  - Computed: `progress` (completed/total), `completedTasksCount`, `nextMilestoneTask`

### Workspace Models (`lib/models/workspace_models.dart`)

**Enums:**
- `WorkspaceType`: personal, community
- `CommunityRole`: owner, admin, member
- `AssignmentStatus`: todo, inProgress, completed

**Classes:**
- `Community`: id, name, description, icon, members, communitySessions
- `CommunityMember`: id, name, email, avatarUrl, role
- `Session`: id, title, description, assignments, memberAvatars, isArchived
- `Assignment`: id, title, assigneeId, assigneeName, assigneeAvatar, deadline, status

### Security Models (`lib/models/security_models.dart`)

**Classes:**
- `UserSession`: id, userId, deviceName, deviceType, osInfo, ipAddress, loginTime, lastActive, isCurrent
- `SecuritySettings`: is2faEnabled, twoFactorSecret, lastPasswordChange

---

## Database Schema (MongoDB)

### 1. `users` — User accounts
```javascript
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

### 2. `user_profiles` — Extended profile & security
```javascript
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

### 3. `auth_sessions` — Login session tracking
```javascript
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

### 4. `workspaces` — Workspace containers
```javascript
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

### 5. `goals` — Goal definitions
```javascript
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

### 6. `tasks` — Individual tasks within goals
```javascript
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

### 7. `sessions` — Focus session containers
```javascript
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

### 8. `focussessions` — Individual focus metrics
```javascript
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
```

### 9. `goalactivities` — Activity feed entries
```javascript
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
```

### 10. `assignments` — Community workspace tasks
```javascript
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
```

---

## API Endpoints

### Authentication
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/auth/register` | Register user + create personal workspace |
| POST | `/api/auth/login` | Login + validate workspace + create AuthSession |
| POST | `/api/auth/2fa/login` | Verify 2FA code after MFA-required response |
| POST | `/api/auth/2fa/setup` | Generate TOTP secret + QR code (auth required) |
| POST | `/api/auth/2fa/verify` | Verify TOTP to enable 2FA (auth required) |
| POST | `/api/auth/2fa/disable` | Disable 2FA with TOTP verification (auth required) |
| POST | `/api/auth/logout` | Revoke current AuthSession (auth required) |
| PUT | `/api/auth/profile` | Update user profile (auth required) |
| GET | `/api/auth/profile` | Get user profile (auth required) |
| DELETE | `/api/auth/profile` | Delete account + cascade delete (auth required) |
| GET | `/api/auth/sessions` | List active AuthSessions (auth required) |
| DELETE | `/api/auth/sessions/:id` | Revoke specific AuthSession (auth required) |
| DELETE | `/api/auth/sessions` | Revoke all other AuthSessions (auth required) |

### Workspaces
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/workspaces` | List user's workspaces (auth required) |
| POST | `/api/workspaces` | Create workspace (auth required) |
| POST | `/api/workspaces/:id/members` | Add member to community (auth required, admin only) |

### Goals
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/goals` | List goals by workspaceId query param (auth required) |
| POST | `/api/goals` | Create goal (auth required) |
| PUT | `/api/goals/:id` | Update goal (auth required) |
| DELETE | `/api/goals/:id` | Delete goal (auth required) |

### Tasks
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/tasks` | List tasks (filterable by sessionId, goalId, workspaceId) |
| POST | `/api/tasks` | Create task (auth required) |
| PUT | `/api/tasks/:id` | Update task (auth required) |
| DELETE | `/api/tasks/:id` | Delete task (auth required) |

### Sessions
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/sessions` | List sessions by workspaceId (auth required) |
| POST | `/api/sessions` | Create session (auto-links to Goal.sessionIds) |

---

## Authentication

### Authentication Flow

**Registration:**
1. User submits name, email, password via `AuthScreen`
2. `AuthService.register()` → POST `/api/auth/register`
3. Backend: bcrypt hashes password, creates User document
4. Backend: creates personal Workspace, links to user
5. Backend: creates UserProfile with empty security settings
6. Backend: generates JWT, creates AuthSession with SHA-256 token hash
7. Frontend: stores JWT + user data in SharedPreferences
8. Frontend: navigates to MainShell

**Login:**
1. User submits email, password
2. `AuthService.login()` → POST `/api/auth/login`
3. Backend: finds user, bcrypt compares password
4. Backend: fallback creates workspace if missing
5. Backend: backfills UserProfile if missing
6. If 2FA enabled → returns 202 with `mfaRequired: true`
7. If no 2FA → generates JWT, creates AuthSession, returns user + token
8. Frontend: stores in SharedPreferences, initializes services, navigates to MainShell

**2FA Login:**
1. After MFA-required response, shows OTP input
2. `AuthService.verifyLogin2fa()` → POST `/api/auth/2fa/login`
3. Backend: verifies TOTP token against stored secret using speakeasy
4. On success: generates JWT, creates AuthSession, returns user + token

**Token Validation:**
- JWT verified on every API request via `auth` middleware
- Auth middleware also checks `AuthSession.isActive === true`
- Expired JWTs trigger automatic logout
- Demo users use mock JWT token (not real JWT)

**Logout:**
1. `AuthService.logout()` → POST `/api/auth/logout`
2. Backend: sets current AuthSession `isActive: false`
3. Frontend: clears SharedPreferences, resets all services
4. Frontend: navigates back to AuthScreen

### 2FA (Two-Factor Authentication)
- **Algorithm:** TOTP (Time-based One-Time Password) via `speakeasy`
- **Setup:** Generates Base32 secret + QR code URL, stores as `tempSecret`
- **Verification:** User enters 6-digit code from authenticator app
- **Enable:** On successful verification, moves `tempSecret` to `twoFactorSecret` and sets `twoFactorEnabled: true`
- **Disable:** Requires current TOTP code to disable

### Password Security
- Passwords hashed with **bcrypt** (salt rounds: 8)
- Token hashes stored as **SHA-256** (never store raw JWTs)

---

## Data Flow

### 1. Authentication Flow
```
User Login → POST /api/auth/login → JWT + User Object → SharedPreferences
                                    ↓
                            AuthSession created in DB
                                    ↓
                            Services initialized (GoalService, SessionManager, WorkspaceService)
                                    ↓
                            Local state populated
```

### 2. Goal Lifecycle
```
Create Goal → Local save (SharedPreferences) → ApiService.createGoal() → Goal._id returned
    ↓
Local goal updated with DB ID → saveGoals()
    ↓
Update Goal → PUT /api/goals/:id → DB updated
    ↓
Delete Goal → DELETE /api/goals/:id → DB deleted
```

### 3. Task Lifecycle
```
Create Task → Local save → ApiService.createTask() → Task._id returned
    ↓
Local task updated with DB ID → saveGoals()
    ↓
Toggle Completion → Local update → saveGoals()
    ↓
Delete Task → Local removal → saveGoals()
```

### 4. Focus Session Lifecycle
```
Start Focus → SessionManager.startSession() → Local ActiveSession
    ↓
Timer ticks every second → calculates intensity
    ↓
Stop Session → GoalService.addSessionToTask() → Local save
    ↓
_persistFocusSessionToDb() → ApiService.createSession() → Session._id
    ↓
ApiService.updateTask() → Updates timer.timeSpent
```

### 5. Intensity Calculation
```
Every second during active session:
  timeRatio = focusedSeconds / (focusedSeconds + totalPausedSeconds)
  interruptionPenalty = pauseCount × 0.03
  intensity = clamp(timeRatio - interruptionPenalty, 0.4, 1.0)

Every 5 seconds:
  trendData.add(intensity)

On session complete:
  focusScore = clamp((intensity × 100) - (pauseCount × 2), 0, 100)
```

### 6. Real-Time Sync Strategy

| Trigger | Action | API Call |
|---------|--------|----------|
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

### 7. Data Isolation
Each user's data is isolated using user-specific SharedPreferences keys:
- `progresso_goals_$userId`
- `progresso_sessions_$userId`
- `progresso_communities_$userId`
- `progresso_community_data_$userId`

### 8. Demo User Flow
- Demo user: `demo@progressor.com` / `pass123`
- Bypasses backend authentication with mock JWT
- Generates 3 demo goals with 36+ tasks each
- All data stored locally in SharedPreferences
- Demo data is regenerated on each login (forceReset)

---

## Backend Models

### User (`backend/models/User.js`)
```javascript
{
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  defaultPersonalWorkspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  personalWorkspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  communityWorkspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  bio: { type: String, default: '' },
  imageUrl: { type: String },
  rotation: { type: Number, default: 0 },
  localImagePath: { type: String },
  avatarBase64: { type: String }
}
```

### UserProfile (`backend/models/UserProfile.js`)
```javascript
{
  userId: { type: String, required: true, unique: true },
  userObjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  profile: {
    name: String,
    bio: String,
    avatarUrl: String,
    avatarBase64: String
  },
  security: {
    twoFactorEnabled: { type: Boolean, default: false },
    twoFactorSecret: { type: String, default: '' },
    tempSecret: { type: String }
  }
}
```

### Workspace (`backend/models/Workspace.js`)
```javascript
{
  name: { type: String, required: true },
  type: { type: String, enum: ['personal', 'community'], default: 'personal' },
  description: String,
  iconCode: String,
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  ownerSnapshot: { email: String, name: String },
  members: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    email: String,
    name: String,
    avatarUrl: String,
    role: { type: String, enum: ['admin', 'member'], default: 'member' },
    joinedAt: { type: Date, default: Date.now }
  }]
}
```

### Goal (`backend/models/Goal.js`)
```javascript
{
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace', required: true },
  name: { type: String, required: true },
  description: String,
  dueDate: Date,
  iconCode: String,
  imageUrl: String,
  status: { type: String, enum: ['active', 'completed', 'paused', 'archived'], default: 'active' },
  totalTimeSpent: { type: Number, default: 0 },
  currentStreak: { type: Number, default: 0 },
  dailyEffort: [{ type: Number, default: 0 }],
  sessionIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Session' }],
  taskIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
  activityIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'GoalActivity' }]
}
```

### Task (`backend/models/Task.js`)
```javascript
{
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Session' },
  goalId: { type: mongoose.Schema.Types.Mixed },
  workspaceId: { type: mongoose.Schema.Types.Mixed },
  name: { type: String, required: true },
  priority: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
  deadline: Date,
  sessionType: { type: String, enum: ['free', 'timed'], default: 'timed' },
  isCompleted: { type: Boolean, default: false },
  status: { type: String, enum: ['not_started', 'in_progress', 'completed'], default: 'not_started' },
  timer: {
    totalAllocatedTime: { type: Number, default: 0 },
    timeSpent: { type: Number, default: 0 }
  },
  completedAt: Date
}
```

### Session (`backend/models/Session.js`)
```javascript
{
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  goalId: { type: mongoose.Schema.Types.ObjectId, ref: 'Goal' },
  goalSnapshot: { _id: mongoose.Schema.Types.ObjectId, name: String },
  name: String,
  taskIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
  status: { type: String, enum: ['active', 'paused', 'completed', 'abandoned'], default: 'active' },
  startedAt: { type: Date, default: Date.now },
  endedAt: Date,
  totalDuration: { type: Number, default: 0 }
}
```

### AuthSession (`backend/models/AuthSession.js`)
```javascript
{
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  tokenHash: { type: String, required: true },
  deviceName: { type: String, default: 'Unknown Device' },
  deviceType: { type: String, default: 'Desktop' },
  osInfo: { type: String, default: 'Unknown OS' },
  ipAddress: String,
  loginTime: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now },
  userAgent: String,
  isActive: { type: Boolean, default: true }
}
```

---

## Theme & Localization

### Theme
- **Light Theme:** Background `#F6F6F8`, seed color `#5048E5` (indigo)
- **Dark Theme:** Background `#0F172A` (slate-900), same seed color
- **Font:** Google Fonts Inter
- **Managed by:** `SettingsNotifier` (Provider)

### Localization
- **Supported Languages:** English (en), Spanish (es)
- **Files:** `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_es.dart`
- **Managed by:** `SettingsNotifier.setLocale()`

---

## Complete Source Code

### Project Structure
```
Progresso/
├── lib/
│   ├── main.dart                          # App entry point, providers, theme
│   ├── config/
│   │   └── db_collections.dart            # Database collection constants
│   ├── l10n/
│   │   ├── app_localizations.dart         # Localization delegate
│   │   ├── app_localizations_en.dart      # English translations
│   │   └── app_localizations_es.dart      # Spanish translations
│   ├── models/
│   │   ├── goal_models.dart               # Goal, GoalTask, FocusSession, etc.
│   │   ├── security_models.dart           # UserSession, SecuritySettings
│   │   └── workspace_models.dart          # Community, Session, Assignment
│   ├── screens/
│   │   ├── auth_screen.dart               # Login/Registration
│   │   ├── main_shell.dart                # Main navigation shell
│   │   ├── dashboard_screen.dart          # Home dashboard
│   │   ├── goals_overview_screen.dart     # Goals list
│   │   ├── goal_detail_screen.dart        # Single goal detail
│   │   ├── goal_archive_screen.dart       # Completed tasks archive
│   │   ├── focus_session_screen.dart      # Active focus timer
│   │   ├── focus_summary_screen.dart      # Post-session summary
│   │   ├── analysis_screen.dart           # Productivity analytics
│   │   ├── profile_screen.dart            # User profile & settings
│   │   ├── community_dashboard.dart       # Team dashboard
│   │   ├── community_dashboard_screen.dart # Team overview
│   │   ├── community_goals_screen.dart    # Shared team goals
│   │   ├── community_analysis_screen.dart # Team analytics
│   │   ├── sessions_overview_screen.dart  # Community sessions
│   │   └── session_detail_screen.dart     # Session detail
│   ├── services/
│   │   ├── api_service.dart               # REST API client
│   │   ├── auth_service.dart              # Authentication
│   │   ├── community_service.dart         # Community management
│   │   ├── goal_service.dart              # Goals/tasks management
│   │   ├── mongodb_service.dart           # Direct MongoDB (disabled)
│   │   ├── security_service.dart          # 2FA & session management
│   │   ├── session_manager.dart           # Focus session lifecycle
│   │   └── workspace_service.dart         # Workspace switching
│   ├── theme/
│   │   ├── app_colors.dart                # Color constants
│   │   ├── settings_notifier.dart         # Theme/locale settings
│   │   └── theme_notifier.dart            # Theme mode management
│   └── widgets/
│       ├── active_goals.dart              # Active goals grid
│       ├── assign_task_dialog.dart        # Task assignment dialog
│       ├── cta_banner.dart                # Call-to-action banner
│       ├── create_community_dialog.dart   # Create community dialog
│       ├── create_goal_dialog.dart        # Create/edit goal dialog
│       ├── custom_date_range_picker.dart  # Date range picker
│       ├── dashboard_header.dart          # Dashboard header
│       ├── focus_intensity.dart           # Focus intensity chart
│       ├── focus_session_dialog.dart      # Start session dialog
│       ├── quick_focus_dialog.dart        # Quick focus dialog
│       ├── recent_sessions.dart           # Recent sessions list
│       ├── responsive.dart                # Responsive breakpoints
│       ├── session_type_selection_dialog.dart # Free/timed picker
│       ├── sidebar.dart                   # Navigation sidebar
│       ├── stat_card.dart                 # Stat metric card
│       ├── weekly_chart.dart              # Weekly bar chart
│       └── workspace_switcher.dart        # Workspace switcher
├── backend/
│   ├── server.js                          # Express.js server + all routes
│   ├── seed.js                            # Demo data seeder
│   ├── package.json                       # Node.js dependencies
│   ├── .env                               # Environment variables
│   ├── models/
│   │   ├── User.js                        # User Mongoose model
│   │   ├── UserProfile.js                 # UserProfile Mongoose model
│   │   ├── Workspace.js                   # Workspace Mongoose model
│   │   ├── Goal.js                        # Goal Mongoose model
│   │   ├── Task.js                        # Task Mongoose model
│   │   ├── Session.js                     # Session Mongoose model
│   │   └── AuthSession.js                 # AuthSession Mongoose model
│   └── node_modules/                      # Dependencies
├── assets/
│   └── images/                            # App assets (avatars, icons)
├── pubspec.yaml                           # Flutter dependencies
├── analysis_options.yaml                  # Dart lint rules
├── database.md                            # Database documentation
├── BUG_REPORT.md                          # Bug tracking (all 36 fixed)
└── test/                                  # Widget tests
    ├── widget_test.dart
    └── session_flow_test.dart
```

### Key Dependencies

**Frontend (pubspec.yaml):**
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  intl: ^0.20.2
  mongo_dart: ^0.10.4
  shared_preferences: ^2.3.5
  provider: ^6.1.2
  crypto: ^3.0.6
  desktop_drop: ^0.5.0
  encrypt: ^5.0.3
  file_picker: ^8.1.7
  http: ^1.3.0
  image: ^4.5.3
  jwt_decoder: ^2.0.1
  path_provider: ^2.1.5
  qr_flutter: ^4.1.0
  flutter_localizations:
    sdk: flutter
  device_info_plus: ^12.3.0
```

**Backend (package.json):**
```json
{
  "dependencies": {
    "express": "^4.x",
    "mongoose": "^8.x",
    "cors": "^2.x",
    "jsonwebtoken": "^9.x",
    "bcryptjs": "^2.x",
    "speakeasy": "^2.x",
    "dotenv": "^16.x"
  },
  "devDependencies": {
    "nodemon": "^3.x"
  }
}
```

### Demo User Credentials
- **Email:** `demo@progressor.com`
- **Password:** `pass123`
- **Alternative:** `demo@gmail.com` / `pass123`

### Running the Project

**Frontend:**
```bash
flutter pub get
flutter run
```

**Backend:**
```bash
cd backend
npm install
node server.js
# Server runs on http://localhost:5000
```

**Seed Demo Data:**
```bash
node backend/seed.js
```

---

## Summary

Progresso is a comprehensive productivity application that combines personal goal management with team collaboration. It uses a local-first architecture with SharedPreferences as the immediate data store and MongoDB Atlas for persistent cloud sync. The app features a polished UI with responsive design, deep analytics with custom chart painters, robust authentication with JWT and 2FA, and a well-structured codebase following Flutter best practices with singleton services, ChangeNotifier state management, and clean separation of concerns.
