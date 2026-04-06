require('dotenv').config();
const mongoose = require('mongoose');

async function clearDatabase() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas\n');

    const db = mongoose.connection.db;
    const collections = await db.collections();

    if (collections.length === 0) {
      console.log('📋 Database is already empty.');
      await mongoose.disconnect();
      process.exit(0);
    }

    console.log(`🗑️  Found ${collections.length} collections. Dropping all...\n`);

    for (const collection of collections) {
      const name = collection.collectionName;
      await collection.drop();
      console.log(`   Dropped: ${name}`);
    }

    console.log('\n✅ Database cleared successfully. All collections removed.');
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed to clear database:', err);
    process.exit(1);
  }
}

clearDatabase();
