const service = require("../services/statsService");

exports.get = async (req, res) => {
  try {
    const data = await service.get(req.user.uid);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, message: err.message });
  }
};
