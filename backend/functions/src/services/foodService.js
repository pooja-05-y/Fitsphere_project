const { db } = require("../config/firebase");

exports.add = (userId, data) => {
  return db.collection("food_logs").add({
    userId,
    foodName: data.foodName,
    calories: data.calories,
    protein: data.protein,
    carbs: data.carbs,
    fats: data.fats,
    date: data.date || new Date().toISOString().split("T")[0],
  });
};
