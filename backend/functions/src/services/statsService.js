const { db } = require("../config/firebase");

exports.get = async (userId) => {
  const snap = await db.collection("workouts")
    .where("userId", "==", userId)
    .get();

  let calories = 0;
  snap.forEach(d => calories += d.data().caloriesBurned || 0);

  return {
    totalWorkouts: snap.size,
    totalCalories: calories,
  };
};
