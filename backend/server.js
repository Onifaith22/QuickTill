const express = require("express");
const cors = require("cors");
const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(cors());

// Health check
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "QuickTill API",
  });
});

// Application version
app.get("/version", (req, res) => {
  res.status(200).json({
    app: "QuickTill",
    version: process.env.APP_VERSION || "1.0.0",
  });
});

// Simulated checkout
app.post("/api/checkout", (req, res) => {
  const { items } = req.body;

  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({
      message: "Your basket is empty or invalid.",
    });
  }

  const products = {
    Coffee: 1500,
    Sandwich: 3500,
    "Orange Juice": 2000,
    Donut: 1200,
    "Meat Pie": 1800,
    "Bottled Water": 700,
  };

  let total = 0;

  for (const item of items) {
    if (
      !products[item.name] ||
      !Number.isInteger(item.quantity) ||
      item.quantity < 1
    ) {
      return res.status(400).json({
        message: "Invalid product or quantity.",
      });
    }

    total += products[item.name] * item.quantity;
  }

  res.status(200).json({
    message: "Checkout successful!",
    orderId: `QT-${Date.now()}`,
    total,
    currency: "NGN",
  });
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`QuickTill API running on port ${PORT}`);
});
