/**
 * backfill_profiles.js
 * 
 * One-time script: creates a user_profiles document for every user in the
 * `users` collection that doesn't already have one.
 * 
 * Run: node backfill_profiles.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const UserProfile = require('./models/UserProfile');

async function backfill() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB Atlas');

  const users = await User.find({}).select('-password');
  console.log(`Found ${users.length} user(s) to check.`);

  let created = 0;
  let skipped = 0;

  for (const user of users) {
    const existing = await UserProfile.findOne({ userId: user.email });
    if (existing) {
      console.log(`  ↳ SKIP  ${user.email} — profile already exists`);
      skipped++;
      continue;
    }

    await UserProfile.create({
      userId:       user.email,
      userObjectId: user._id,
      profile: {
        name:         user.name        || '',
        bio:          user.bio         || '',
        avatarUrl:    user.imageUrl    || '',
        avatarBase64: user.avatarBase64 || '',
      },
      security: {
        twoFactorEnabled: false,
        twoFactorSecret:  '',
      },
    });

    console.log(`  ✅ CREATED profile for ${user.email}`);
    created++;
  }

  console.log(`\nDone. Created: ${created}, Skipped: ${skipped}`);
  await mongoose.disconnect();
  process.exit(0);
}

backfill().catch(err => {
  console.error('❌ Backfill failed:', err);
  process.exit(1);
});
