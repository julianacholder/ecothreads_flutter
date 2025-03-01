import * as functions from "firebase-functions";
import * as nodemailer from "nodemailer";
import * as dotenv from "dotenv";

dotenv.config(); // Load environment variables from .env file

// Define the expected data structure
interface OTPEmailData {
  email: string;
  otp: string;
}

// Function to create the nodemailer transporter
const createTransporter = () => {
  console.log("Initializing transporter...");
  try {
    console.log("Environment Variables:", {
      EMAIL_USER: process.env.EMAIL_USER,
      EMAIL_PASS: process.env.EMAIL_PASS ? "Present" : "Not Present",
    });
    return nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER || "",
        pass: process.env.EMAIL_PASS || "",
      },
    });
  } catch (error) {
    console.error("Transporter creation error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to initialize email service"
    );
  }
};

// Cloud function to send OTP email
export const sendOTPEmail = functions.https.onCall(
  async (request: functions.https.CallableRequest<OTPEmailData>) => {
    const data = request.data;

    console.log("Environment check:", {
      hasUser: !!process.env.EMAIL_USER,
      hasPass: !!process.env.EMAIL_PASS,
    });

    if (!data.email || !data.otp) {
      console.error("Invalid request data:", data);
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and OTP are required"
      );
    }

    try {
      const transporter = createTransporter();
      console.log("Attempting to verify transporter...");
      await transporter.verify();
      console.log("Transporter verified successfully.");

      const mailOptions = {
        from: `"EcoThreads" <${process.env.EMAIL_USER}>`,
        to: data.email,
        subject: "Your EcoThreads Verification Code",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; 
            margin: 0 auto;">
            <h2>Verify Your Email</h2>
            <p>Thank you for registering with EcoThreads. 
              Your verification code is:</p>
            <div style="background-color: #f5f5f5; padding: 20px; 
              text-align: center; margin: 20px 0;">
              <h1 style="font-size: 32px; letter-spacing: 5px; 
                margin: 0;">${data.otp}</h1>
            </div>
            <p>This code will expire in 5 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
            <hr style="margin: 20px 0;">
            <p style="color: #666; font-size: 12px;">
              This is an automated message, please do not reply.
            </p>
          </div>
        `,
      };

      const info = await transporter.sendMail(mailOptions);
      console.log("Email sent successfully:", info.messageId);
      return {success: true, messageId: info.messageId};
    } catch (error) {
      console.error("Function error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Email service error: " + (error as Error).message
      );
    }
  }
);

