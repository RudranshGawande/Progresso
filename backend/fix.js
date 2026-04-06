const fs = require('fs');
let content = fs.readFileSync('server.js', 'utf8');

// Fix 1: Remove invalid res.json in register route
content = content.replace(/      res\.json\({\r?\n        token: jwtToken,\r?\n        user,\r?\n        userId: user\._id,\r?\n        email: user\.email,\r?\n        defaultPersonalWorkspaceId: user\.defaultPersonalWorkspaceId\r?\n      }\);/, '');

// Fix 2: Remove duplicated change password route
const p1 = content.indexOf(`// 7. Auth: Change Password`);
const p2 = content.indexOf(`// 7. Auth: Change Password`, p1 + 50);
if (p2 !== -1) {
    content = content.substring(0, p1) + content.substring(p2);
}

// Fix 3: Remove trailing await task.save() duplicate block
const searchStr = `    await task.save();

    // If task is created as part of a session, back-link it
    if (sessionId) {
      await Session.findByIdAndUpdate(
        sessionId,
        { $push: { taskIds: task._id } }
      );
    }

    res.status(201).json(task);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});`;
// we will replace all instances except the first proper one.
// Wait, the proper one is inside the try block, formatted differently!
// Let's just find the exact sequence at the end of post(/api/tasks)
content = content.replace(/\s+await task\.save\(\);\r?\n\r?\n    \/\/ If task is created as part of a session, back-link it\r?\n    if \(sessionId\) {\r?\n      await Session\.findByIdAndUpdate\(\r?\n        sessionId,\r?\n        { \$push: { taskIds: task\._id } }\r?\n      \);\r?\n    }\r?\n\r?\n    res\.status\(201\)\.json\(task\);\r?\n  } catch \(e\) {\r?\n    res\.status\(400\)\.json\({ error: e\.message }\);\r?\n  }\r?\n}\);/, '');

fs.writeFileSync('server.js', content, 'utf8');
console.log("Fixed server.js");
