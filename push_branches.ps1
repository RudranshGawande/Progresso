$ErrorActionPreference = "Continue"
$base = "main"

function Push-Branch {
    param(
        [string]$branchName,
        [string[]]$files,
        [string]$commitMsg
    )

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Branch: $branchName" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Go back to main first
    git checkout $base 2>&1 | Out-Null

    # Delete local branch if it exists
    $localExists = git branch --list $branchName
    if ($localExists) {
        git branch -D $branchName 2>&1 | Out-Null
        Write-Host "Deleted local branch: $branchName" -ForegroundColor DarkGray
    }

    # Delete remote branch if it exists
    $remoteExists = git ls-remote --heads origin $branchName
    if ($remoteExists) {
        git push origin --delete $branchName 2>&1 | Out-Null
        Write-Host "Deleted remote branch: $branchName" -ForegroundColor DarkGray
    }

    # Create fresh branch from main
    git checkout -b $branchName 2>&1 | Out-Null
    Write-Host "Created branch from $base" -ForegroundColor Green

    $validFiles = @()
    foreach ($f in $files) {
        if (Test-Path $f) {
            $validFiles += $f
        } else {
            Write-Host "SKIP (not found): $f" -ForegroundColor DarkGray
        }
    }

    if ($validFiles.Count -eq 0) {
        Write-Host "No valid files found! Skipping..." -ForegroundColor Red
        git checkout $base 2>&1 | Out-Null
        return
    }

    foreach ($f in $validFiles) {
        git add $f 2>&1 | Out-Null
    }

    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Host "Nothing to commit (all files may already exist in main). Skipping..." -ForegroundColor DarkYellow
        git checkout $base 2>&1 | Out-Null
        return
    }

    git commit -m $commitMsg 2>&1
    git push -u origin $branchName 2>&1
    Write-Host "PUSHED: $branchName" -ForegroundColor Green
    git checkout $base 2>&1 | Out-Null
}

# ── 1. feature/app-shell ─────────────────────────────
Push-Branch `
    -branchName "feature/app-shell" `
    -files @(
        "lib/main.dart",
        "lib/screens/main_shell.dart",
        "lib/widgets/sidebar.dart",
        "lib/widgets/responsive.dart",
        "lib/theme/app_colors.dart",
        "lib/theme/settings_notifier.dart",
        "lib/theme/theme_notifier.dart",
        "lib/config/db_collections.dart",
        "lib/config/secrets.dart",
        "pubspec.yaml",
        "pubspec.lock",
        "analysis_options.yaml",
        "assets/images/avatar.png",
        "assets/images/google_logo.png"
    ) `
    -commitMsg "feat(app-shell): main entry, navigation shell, sidebar, theme & config"

# ── 2. feature/auth-login ─────────────────────────────
Push-Branch `
    -branchName "feature/auth-login" `
    -files @(
        "lib/screens/auth_screen.dart",
        "lib/services/auth_service.dart",
        "lib/services/security_service.dart",
        "lib/services/session_manager.dart",
        "lib/models/security_models.dart",
        "backend/models/AuthSession.js",
        "backend/models/User.js",
        "backend/models/UserProfile.js"
    ) `
    -commitMsg "feat(auth): sign-up/login screen, auth service, security service, session manager and backend user models"

# ── 3. feature/dashboard ─────────────────────────────
Push-Branch `
    -branchName "feature/dashboard" `
    -files @(
        "lib/screens/dashboard_screen.dart",
        "lib/widgets/dashboard_header.dart",
        "lib/widgets/stat_card.dart",
        "lib/widgets/active_goals.dart",
        "lib/widgets/recent_sessions.dart",
        "lib/widgets/weekly_chart.dart",
        "lib/services/api_service.dart"
    ) `
    -commitMsg "feat(dashboard): dashboard screen, header, stat cards, active goals, recent sessions, weekly chart and API service"

# ── 4. feature/goals ─────────────────────────────────
Push-Branch `
    -branchName "feature/goals" `
    -files @(
        "lib/screens/goals_overview_screen.dart",
        "lib/screens/goal_detail_screen.dart",
        "lib/screens/goal_archive_screen.dart",
        "lib/widgets/create_goal_dialog.dart",
        "lib/widgets/custom_date_range_picker.dart",
        "lib/services/goal_service.dart",
        "lib/models/goal_models.dart",
        "backend/models/Goal.js",
        "backend/models/Task.js",
        "assets/images/coding.png",
        "assets/images/design.png",
        "assets/images/development.png",
        "assets/images/productivity.png",
        "assets/images/research.png",
        "assets/images/study.png"
    ) `
    -commitMsg "feat(goals): goals overview, detail, archive, create-goal dialog, goal service, goal and task backend models"

# ── 5. feature/focus-session ─────────────────────────
Push-Branch `
    -branchName "feature/focus-session" `
    -files @(
        "lib/screens/focus_session_screen.dart",
        "lib/screens/focus_summary_screen.dart",
        "lib/screens/session_detail_screen.dart",
        "lib/screens/sessions_overview_screen.dart",
        "lib/widgets/focus_session_dialog.dart",
        "lib/widgets/quick_focus_dialog.dart",
        "lib/widgets/session_type_selection_dialog.dart",
        "lib/widgets/focus_intensity.dart",
        "backend/models/Session.js",
        "test/session_flow_test.dart",
        "test/widget_test.dart"
    ) `
    -commitMsg "feat(focus-session): focus session screen, summary, session overview, dialogs, intensity widget, Session model and tests"

# ── 6. feature/community ─────────────────────────────
Push-Branch `
    -branchName "feature/community" `
    -files @(
        "lib/screens/community_dashboard.dart",
        "lib/screens/community_dashboard_screen.dart",
        "lib/screens/community_analysis_screen.dart",
        "lib/screens/community_goals_screen.dart",
        "lib/widgets/create_community_dialog.dart",
        "lib/widgets/cta_banner.dart"
    ) `
    -commitMsg "feat(community): community dashboard, analysis, goals screens, create-community dialog and CTA banner"

# ── 7. feature/analysis ──────────────────────────────
Push-Branch `
    -branchName "feature/analysis" `
    -files @(
        "lib/screens/analysis_screen.dart"
    ) `
    -commitMsg "feat(analysis): analysis screen with charts and productivity insights"

# ── 8. feature/profile ───────────────────────────────
Push-Branch `
    -branchName "feature/profile" `
    -files @(
        "lib/screens/profile_screen.dart",
        "lib/widgets/workspace_switcher.dart",
        "lib/services/workspace_service.dart",
        "lib/services/mongodb_service.dart",
        "lib/models/workspace_models.dart",
        "backend/models/Workspace.js"
    ) `
    -commitMsg "feat(profile): profile screen, workspace switcher, workspace service and model"

# ── 9. feature/backend-core ──────────────────────────
Push-Branch `
    -branchName "feature/backend-core" `
    -files @(
        "backend/server.js",
        "backend/package.json",
        "backend/package-lock.json",
        "backend/seed.js",
        "backend/backfill_profiles.js"
    ) `
    -commitMsg "feat(backend-core): Express server with all API routes, seed data and profile backfill script"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " All branches pushed! Back on: main" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
git checkout $base 2>&1 | Out-Null
git branch -a
