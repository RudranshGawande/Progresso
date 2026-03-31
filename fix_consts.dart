import "dart:io";

void main() async {
  while (true) {
    print("Running dart analyze...");
    final result = await Process.run("dart", ["analyze"]);
    final output = result.stdout.toString() + "\n" + result.stderr.toString();
    
    final errorRegex = RegExp(r"error - (.+?):(\d+):(\d+) - Invalid constant value");
    
    Map<String, List<int>> removals = {};
    for (var line in output.split('\n')) {
      var match = errorRegex.firstMatch(line);
      if (match != null) {
        final path = match.group(1)!.trim();
        final lineNum = int.parse(match.group(2)!) - 1;
        removals.putIfAbsent(path, () => []).add(lineNum);
      }
    }
    
    print("Found ${removals.length} files with invalid consts.");
    if (removals.isEmpty) {
      break;
    }
    
    for (final entry in removals.entries) {
      final f = File(entry.key);
      if (!f.existsSync()) continue;
      
      var contentLines = f.readAsLinesSync();
      var linesToFix = entry.value.toSet(); // Remove duplicates
      
      // We must sort by line numbers descending if we were changing line counts,
      // but we only modify lines in-place, so array size is constant.
      for (int ln in linesToFix) {
        // Walk backwards up to 30 lines
        for (int i = ln; i >= 0 && i >= ln - 30; i--) {
          if (contentLines[i].contains("const ")) {
            contentLines[i] = contentLines[i].replaceFirst("const ", "");
            break; // only first one encountered
          }
        }
      }
      f.writeAsStringSync(contentLines.join('\n'));
      print("Fixed ${entry.key}");
    }
  }
}
