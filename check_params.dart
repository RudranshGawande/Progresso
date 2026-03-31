import 'dart:io';

void main() {
  final files = [
    "lib/widgets/focus_session_dialog.dart",
    "lib/widgets/custom_date_range_picker.dart",
    "lib/screens/profile_screen.dart",
    "lib/screens/goal_detail_screen.dart",
    "lib/screens/goal_archive_screen.dart",
    "lib/screens/community_dashboard.dart",
    "lib/screens/analysis_screen.dart",
  ];
  for (var f in files) {
    if (File(f).existsSync()) {
      var content = File(f).readAsLinesSync();
      for (int i = 0; i < content.length; i++) {
        if (content[i].contains(RegExp(r"=\s*AppColors\."))) {
          print("$f:${i+1} : ${content[i].trim()}");
        }
      }
    }
  }
}
