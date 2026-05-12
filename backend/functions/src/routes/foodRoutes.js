const router = require("express").Router();
const c = require("../controllers/foodController");
const auth = require("../middleware/auth");

router.post("/add", auth, c.add);

module.exports = router;
