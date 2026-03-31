import 'dart:io';

void main() {
  final files = [
    "lib/widgets/dashboard_header.dart",
    "lib/widgets/create_community_dialog.dart",
    "lib/screens/goal_detail_screen.dart",
    "lib/screens/goal_archive_screen.dart",
    "lib/screens/goals_overview_screen.dart",
    "lib/screens/community_dashboard.dart",
    "lib/screens/auth_screen.dart",
    "lib/main.dart",
  ];
  for (var f in files) {
    if (File(f).existsSync()) {
      var content = File(f).readAsLinesSync();
      for (int i = 0; i < content.length; i++) {
        if (content[i].contains(RegExp(r"Color\(0x[A-Fa-f0-9]{8}\)"))) {
          print("$f:${i+1} : ${content[i].trim()}");
        }
      }
    }
  }
}
