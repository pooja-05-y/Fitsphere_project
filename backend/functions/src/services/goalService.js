const { db } = require("../config/firebase");

exports.add = (userId, data) => {
  return db.collection("goals").add({
    userId,
    goalType: data.goalType,
    targetValue: data.targetValue,
    currentValue: 0,
    status: "active",
  });
};
