const router = require("express").Router();
const c = require("../controllers/statsController");
const auth = require("../middleware/auth");

router.get("/", auth, c.get);

module.exports = router;