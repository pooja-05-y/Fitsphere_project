const { db } = require("../config/firebase");

exports.add = (userId, data) => {
  return db.collection("mood_logs").add({
    userId,
    mood: data.mood,
    note: data.note,
    date: data.date || new Date().toISOString().split("T")[0],
  });
};
