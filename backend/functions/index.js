const { onRequest } = require("firebase-functions/v2/https");
const express = require("express");
const cors = require("cors");

// Import routes
const authRoutes = require("./src/routes/authRoutes");
const workoutRoutes = require("./src/routes/workoutRoutes");
const foodRoutes = require("./src/routes/foodRoutes");
const moodRoutes = require("./src/routes/moodRoutes");
const goalRoutes = require("./src/routes/goalRoutes");
const statsRoutes = require("./src/routes/statsRoutes");

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use("/auth", authRoutes);
app.use("/workouts", workoutRoutes);
app.use("/food", foodRoutes);
app.use("/mood", moodRoutes);
app.use("/goals", goalRoutes);
app.use("/stats", statsRoutes);

// Export Firebase Function (v2 style)
exports.api = onRequest(
  {
    region: "asia-south1",
    maxInstances: 10,
  },
  app
);
