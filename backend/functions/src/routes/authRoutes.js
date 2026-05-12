const express = require("express");
const router = express.Router();
const c = require("../controllers/authController");

router.post("/signup", c.signup);

module.exports = router;
