const { admin, db } = require("../config/firebase");

exports.signup = async (data) => {
  const user = await admin.auth().createUser({
    email: data.email,
    password: data.password,
    displayName: data.name,
  });

  await db.collection("users").doc(user.uid).set({
    name: data.name,
    email: data.email,
    streak: 0,
    createdAt: new Date(),
  });

  return user;
};
