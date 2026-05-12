const { db } = require("../config/firebase");

exports.add = async (userId, data) => {
  return await db.collection("workouts").add({
    userId,
    type: data.type,
    duration: data.duration,
    caloriesBurned: data.caloriesBurned,
    date: data.date || new Date().toISOString().split("T")[0],
  });
};
