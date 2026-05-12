const service = require("../services/workoutService");

exports.add = async (req, res) => {
  try {
    await service.add(req.user.uid, req.body);
    res.json({ success: true, message: "Workout added" });
  } catch (err) {
    res.json({ success: false, message: err.message });
  }
};
