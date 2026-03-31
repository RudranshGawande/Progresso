import "dart:io";

void main() {
  final dir = Directory("lib");
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith(".dart"));
  
  for (final file in files) {
    var content = file.readAsStringSync();
    
    bool changed = false;
    final lines = content.split("\n");
    for (int i=0; i<lines.length; i++) {
      if (lines[i].contains("const ") && lines[i].contains("AppColors")) {
        // Just remove ALL `const` on that line
        lines[i] = lines[i].replaceAll("const ", "");
        changed = true;
      }
    }
    
    if (changed) {
      file.writeAsStringSync(lines.join("\n"));
      print("Updated ${file.path}");
    }
  }
}
