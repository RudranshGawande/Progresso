require('dotenv').config();
const mongoose = require('mongoose');
const Workspace = require('./models/Workspace');

async function check() {
  await mongoose.connect(process.env.MONGODB_URI);
  const ws = await Workspace.findById('69c52ba3b7aab43daeac70eb');
  console.log("Workspace:", ws);
  const allWs = await Workspace.find({});
  console.log("All Workspaces count:", allWs.length);
  if (allWs.length > 0) {
     console.log("Example workspace id:", allWs[0]._id);
  }
  process.exit(0);
}
check();
