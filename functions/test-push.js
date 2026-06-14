const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "nearo-f6b25"
});

async function testPush() {
  const db = admin.firestore();
  
  // Find a user
  const usersSnap = await db.collection("users").limit(1).get();
  if (usersSnap.empty) {
    console.log("No users found");
    return;
  }
  
  const userId = usersSnap.docs[0].id;
  console.log("Testing with user:", userId);
  
  // Add notification
  const docRef = await db.collection("notifications").add({
    userId: userId,
    title: "Test Push",
    body: "Background notification working!",
    type: "System",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  console.log("Added notification doc:", docRef.id);
}

testPush().catch(console.error);
