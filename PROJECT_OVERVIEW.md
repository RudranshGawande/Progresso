# 📄 PROJECT OVERVIEW: PROGRESSO

This documentation provides a comprehensive high-level and deep-dive view of the **Progresso** application, covering its architecture, features, database structure, and core logic flows.

---

# 1. Project Overview
- **Project Name:** Progresso
- **Purpose of the application:** A premium productivity command center designed for "Deep Work." It allows users to track focus sessions, manage complex goals, visualize productivity trends, and engage with a community of high-performers.
- **Platform:** Desktop (Flutter Windows / macOS / Linux)
- **Tech Stack:**
    - **Frontend:** Flutter (Dart)
    - **Database:** MongoDB Atlas (NoSQL)
    - **Authentication:** Custom Email/Password + Google OAuth
    - **State Management:** Provider with `ChangeNotifier`
    - **PDF/Exports:** `pdf` package (for reports)

---

# 2. Application Architecture
- **High-level Architecture:**
    - **Client-Side Heavy:** The application logic resides primarily on the client, connecting directly to the **MongoDB Atlas** cluster using the `mongo_dart` driver.
    - **Service Layer:** Decouples UI from data operations. Services handle authentication, database indexing, security, and goal management.
    - **Real-time Persistence:** Local session storage (Shared Preferences) is used for quick retrieval of user states, while Atlas remains the primary source of truth.
- **Data Flow:**
    - `UI` → `Service` → `MongoDB Atlas`
    - `MongoDB Atlas` → `Service` → `ChangeNotifier` → `Reactive UI Rebuild`
- **State Management Approach:**
    - **Global State:** Handled by `AuthService` (User identity/session) and `GoalService` (Goals/Tasks/Sessions).
    - **Local State:** Handled by `StatefulWidget` for immediate UI interactions (e.g., timer animations).

---

# 3. Screens & Features

## Login & Signup Screen
### 📸 Screenshot
[Insert Screenshot: auth_screen.png]

### 🧩 UI Components
- **Input Fields:** Email Address, Password, Full Name (Signup only).
- **Buttons:** "Sign In", "Sign Up", "Sign in with Google", "Forgot Password".
- **Visuals:** Split-panel layout on Desktop with a "Branding Panel" (Glow effects, branding message) and an "Auth Form Panel".

### ⚙️ Functionality
- **Auth Mode Toggle:** Smooth transition between Login and Signup modes.
- **Input Validation:** Real-time email format and password strength checks.
- **Google OAuth:** One-tap login using the system's browser.
- **OTP Verification:** Interstitial state for 2FA-enabled accounts.

### 🔗 Backend Integration
- API calls: Direct MongoDB connection via `AuthService.login()`.
- Authentication flow: Email/Password matching + 2FA check.

### 🗄️ Database Mapping
- **Collection:** `users`, `user_profiles`
- **Fields Involved:** `auth.email`, `auth.passwordHash`, `profile.avatarUrl`

---

## Home / Dashboard Screen
### 📸 Screenshot
[Insert Screenshot: dashboard_screen.png]

### 🧩 UI Components
- **Stat Cards:** Visual tiles for Total Hours, Focus Score, Daily Goal, and Current Streak.
- **Interactive Chart:** Weekly progress line chart (Activity vs. Goals).
- **Recent Sessions:** Interactive list showing the latest work blocks.
- **Active Goals:** Progress bars for currently tracked objectives.
- **Focus Button:** Floating action or banner button to launch the focus timer.

### ⚙️ Functionality
- **Dynamic Stats:** Auto-calculates hours and trends comparing "This Week" vs "Last Week".
- **Navigation Shortcuts:** Clickable cards that jump to specific goal details or analysis.

### 🔗 Backend Integration
- `GoalService.init()`: Fetches all user goals and sessions from MongoDB.

### 🗄️ Database Mapping
- **Collection:** `personal_goals`
- **Fields Involved:** `title`, `description`, `tasks`, `totalTimeSpent`.

---

## Profile & Settings Page
### 📸 Screenshot
[Insert Screenshot: profile_screen_security.png]

### 🧩 UI Components
- **Sidebar:** Navigation for Personal Information, Account Settings, and Security.
- **Avatar Editor:** Support for local file upload, drag-and-drop, and rotation.
- **Setting Toggles:** Theme Mode (Light/Dark), Language (English/Spanish), Week Start.

### ⚙️ Functionality
- **Real-time Updates:** Updating bio or name syncs instantly across the persistent identity record.
- **Multi-device Management:** View and revoke active sessions on other devices.
- **2FA Management:** Enable/Disable TOTP security via Authenticator app.

### 🔗 Backend Integration
- `AuthService.updateProfile()`: Updates nested profile data in `users` and `user_profiles`.

### 🗄️ Database Mapping
- **Collection:** `users`, `user_profiles`, `device_sessions`.

---

## 2FA Setup Screen (Security Dialog)
### 📸 Screenshot
[Insert Screenshot: profile_screen_security_2fa.png]

### 🧩 UI Components
- **QR Code View:** Scan code for Authenticator apps.
- **Manual Key:** fallback text for code entry.
- **OTP Field:** 6-digit verification input.

### ⚙️ Functionality
- **Verification:** Users must scan the code and enter the generated OTP to enable/disable.

### 🔗 Backend Integration
- `SecurityService.verifySetupStep()`: Validates TOTP against secret.

### 🗄️ Database Mapping
- **Collection:** `user_profiles`
- **Fields Involved:** `security.twoFactorEnabled`, `security.twoFactorSecret`.

---

# 4. Feature Breakdown

## Feature: Focus Timer
- **Description:** A dedicated environment for deep work sessions.
- **Trigger:** Clicking "Start Focus" on Dashboard or Goal Detail.
- **Logic Flow:**
    1. User selects a Task within a Goal.
    2. Optional: User sets a "Timed" (Pomodoro) or "Free" session.
    3. Timer starts; `ActiveSession` is tracked in memory.
    4. On completion, `FocusSession` data is persisted to MongoDB.
- **Edge Cases:** Internet disconnection during session (Syncs on reconnection).
- **Error Handling:** Graceful recovery from database write timeouts.

## Feature: 2FA Setup Management
- **Description:** Adds an extra layer of security using TOTP.
- **Trigger:** Security Tab → Setup 2FA.
- **Logic Flow:**
    1. Generate TOTP secret in app.
    2. Display QR Code.
    3. User verifies with 6-digit code.
    4. Database flag `twoFactorEnabled` set to true.
- **Edge Cases:** Incorrect code entered (Error banner shown).
- **Rule:** When 2FA = true → Setup button switches to **"Disable"**; When 2FA = false → Setup button is **"Setup"**.

---

# 5. Database Documentation (MongoDB Atlas)

## Collections:

### `users`
- **Fields:**
    - `auth`: { `userId`: String, `name`: String, `email`: String, `passwordHash`: String }
    - `profile`: { `bio`: String, `avatarUrl`: String, `theme`: String, `notifications`: Boolean }
    - `createdAt`: Date
    - `updatedAt`: Date
- **Example Document:**
```json
{
  "auth": {
    "userId": "USR-1710864000000-PROG",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "passwordHash": "sha256_hash_here"
  },
  "profile": {
    "bio": "Building the future of focus.",
    "avatarUrl": "https://gravatar.com/..."
  }
}
```

### `user_profiles`
- **Fields:** `userId` (FK), `name`, `username`, `imageUrl`, `bio`, `security`: { `twoFactorEnabled`, `twoFactorSecret` }.

### `device_sessions`
- **Fields:** `userId`, `deviceName`, `deviceType`, `osInfo`, `ipAddress`, `lastActive`.

### `personal_goals`
- **Fields:** `id`, `title`, `description`, `status`, `tasks`: Array of `GoalTask`.

---

# 6. Authentication Flow
- **Login logic:** Email/Password check → 2FA check → Create session record → Store in `SharedPreferences`.
- **Signup logic:** Password hashing → Create both `users` and `user_profiles` records → Automatic Login.
- **Password handling:** SHA-256 Hashing before transmission/storage.
- **2FA logic:** 
    - When `twoFactorEnabled` = true → Login requires 6-digit OTP verification.
    - Setup enabled status determines button label/action in Profile Security.

---

# 7. UI/UX Logic Rules
- **Button states:** "Save Changes" in Profile only enables after detecting modifications in Controllers.
- **Input validations:** Regex for Email; Min 8 chars for Password.
- **Error messages:** SnackBar popups for API failures; Inline red text for validation errors.
- **Navigation flow:** `AuthScreen` → `MainShell` (Sidebar + Content Area).

---

# 8. Known Bugs & Fixes
- **Known Issue:** Backspace/Delete key not working in some text inputs on Desktop.
- **Root Cause:** Focus traversal or unhandled keyboard events in specific Flutter Desktop contexts.
- **Solution:** Implemented global `Shortcuts` in `main.dart` mapping `LogicalKeyboardKey.backspace` to `DeleteCharacterIntent`.

---

# 9. Folder Structure
- **Frontend structure:**
    - `lib/screens`: All page-level widgets.
    - `lib/services`: Database and Logic layers.
    - `lib/models`: PODO (Plain Old Dart Objects) for JSON serialization.
    - `lib/widgets`: Reusable small components.
    - `lib/theme`: Global styles and tokens.

---

# 10. Summary
- **Key strengths:** Premium aesthetics, direct DB connection for performance, robust security features (2FA, session management).
- **Weaknesses:** Client-direct-to-DB architecture may face security risks if connection strings aren't well protected (resolved via `Secrets` logic).
- **Suggestions:** Implement a real-time Community feed using MongoDB Watch Streams for better interactivity.
