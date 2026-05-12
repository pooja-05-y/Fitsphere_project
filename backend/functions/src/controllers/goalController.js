const service = require("../services/goalService");

exports.add = async (req, res) => {
  try {
    await service.add(req.user.uid, req.body);
    res.json({ success: true });
  } catch (err) {
    res.json({ success: false, message: err.message });
  }
};
