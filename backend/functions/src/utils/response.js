exports.success = (res, data) => {
  return res.status(200).json({
    success: true,
    data,
  });
};

exports.error = (res, message) => {
  return res.status(500).json({
    success: false,
    message,
  });
};