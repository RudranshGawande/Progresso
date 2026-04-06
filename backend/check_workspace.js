require('dotenv').config();
const mongoose = require('mongoose');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log('Connected to MongoDB');

    const Workspace = require('./models/Workspace');
    const User = require('./models/User');

    const wsId = '69c52ba3b7aab43daeac70eb';

    // Check workspace
    const ws = await Workspace.findById(wsId);
    console.log('\nWorkspace:', ws ? JSON.stringify(ws.toObject(), null, 2) : 'NOT FOUND');

    // Check users with this as defaultPersonalWorkspaceId
    const users = await User.find({ defaultPersonalWorkspaceId: wsId });
    console.log('\nUsers pointing to this workspace:', users.length);
    for (const u of users) {
      console.log(`  - ${u.email} (${u._id})`);
      if (ws) {
        console.log(`    ownerId match: ${ws.ownerId.toString() === u._id.toString()}`);
      }
    }

    // Check all personal workspaces for these users
    for (const u of users) {
      const personalWS = await Workspace.find({ ownerId: u._id, type: 'personal' });
      console.log(`\nAll personal workspaces for ${u.email}:`, personalWS.length);
      for (const pws of personalWS) {
        console.log(`  - ${pws._id} (owner: ${pws.ownerId})`);
      }
    }

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
