/// Central registry for all MongoDB collection names.
/// Import this instead of hardcoding strings — ensures consistency.
class DB {
  DB._();

  // ── Auth & Identity ──────────────────────────────────────────────────────
  static const String users          = 'users';
  static const String userProfiles   = 'user_profiles';
  static const String deviceSessions = 'device_sessions';

  // ── Personal Workspace ────────────────────────────────────────────────────
  static const String personalGoals  = 'personal_goals';

  // ── Community Workspace ───────────────────────────────────────────────────
  static const String communities    = 'communities';
  static const String communityGoals = 'community_goals';

  // ── Analytics ─────────────────────────────────────────────────────────────
  static const String activityLog    = 'activity_log';
}
