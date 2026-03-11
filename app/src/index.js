const express = require("express");
const { createClient } = require("redis");

const app = express();
app.use(express.json());

const PORT = process.env.APP_PORT || 3000;


const REDIS_HOST = process.env.REDIS_HOST || "redis";
const REDIS_PORT = process.env.REDIS_PORT || 6379;
const REDIS_PASSWORD = process.env.REDIS_PASSWORD;

const REDIS_URL = REDIS_PASSWORD
  ? `redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}`
  : `redis://${REDIS_HOST}:${REDIS_PORT}`;


let redisClient;

async function initRedis() {
  redisClient = createClient({ url: REDIS_URL });

  redisClient.on("error", (err) => {
    console.error("Redis error:", err.message);
  });

  await redisClient.connect();
  console.log("Redis connected");
}

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", uptime: process.uptime() });
});

app.get("/status", async (req, res) => {
  try {
    const redisPing = await redisClient.ping();
    res.json({
      app: "running",
      redis: redisPing,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      app: "running",
      redis: "down",
      error: err.message
    });
  }
});

app.post("/process", async (req, res) => {
  try {
    const payload = req.body || {};
    await redisClient.set("last_process", JSON.stringify(payload), { EX: 300 });
    res.json({ message: "Processed successfully", payload });
  } catch (err) {
    res.status(500).json({ error: "Processing failed" });
  }
});

const server = app.listen(PORT, async () => {
  console.log(`App running on port ${PORT}`);
  await initRedis();
});

/* Graceful shutdown */
function shutdown(signal) {
  console.log(`Received ${signal}. Shutting down...`);
  server.close(async () => {
    if (redisClient) {
      await redisClient.quit();
    }
    process.exit(0);
  });
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
