const functions = require("firebase-functions");
const Razorpay = require("razorpay");
const cors = require("cors")({ origin: true });
const crypto = require("crypto");

/**
 * Helper to get Razorpay client with safe error handling
 */
function getClient() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) throw new Error("API keys not set on server");
  return new Razorpay({ key_id: keyId.trim(), key_secret: keySecret.trim() });
}

/**
 * Step 1: Create Order (Perfectly synced with Razorpay Docs)
 */
exports.api = functions.runWith({
  secrets: ["RAZORPAY_KEY_ID", "RAZORPAY_KEY_SECRET"]
}).https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.path === "/create-order" && req.method === "POST") {
      try {
        const { amount, receipt, userId, planName } = req.body;

        // Exact structure from your screenshot
        const options = {
          amount: Math.round(amount * 100), // convert to paise
          currency: "INR",
          receipt: receipt || `receipt_${Date.now()}`,
          notes: {
            "userId": userId || "unknown",
            "plan": planName || "standard_boost"
          }
        };

        console.log("Creating Razorpay Order:", options);

        const order = await getClient().orders.create(options);

        console.log("Order Created Successfully:", order.id);
        return res.status(200).json(order);
      } catch (err) {
        console.error("Razorpay Order Failure:", err);
        return res.status(500).json({
          error: "CreateOrderError",
          message: "Failed to initialize payment request. Please try again."
        });
      }
    }

    if (req.path === "/verify-payment" && req.method === "POST") {
      try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
        const secret = process.env.RAZORPAY_KEY_SECRET;
        const signature = crypto.createHmac("sha256", secret.trim())
          .update(razorpay_order_id + "|" + razorpay_payment_id)
          .digest("hex");

        if (signature === razorpay_signature) return res.status(200).json({ status: "success" });
        return res.status(400).json({ status: "failure" });
      } catch (err) {
        return res.status(500).json({ error: "VerifyError", message: "Payment verification failed." });
      }
    }

    return res.status(404).send("Not Found");
  });
});

exports.hello = functions.https.onRequest((req, res) => {
  res.status(200).send("Server is Online and Synced with Razorpay API v1");
});
