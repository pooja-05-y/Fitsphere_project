const service = require("../services/authService");
const { success, error } = require("../utils/response");

exports.signup = async (req, res) => {
  try {
    const user = await service.signup(req.body);
    return success(res, user);
  } catch (err) {
    return error(res, err.message);
  }
};
