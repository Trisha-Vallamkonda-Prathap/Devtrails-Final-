import 'package:firebase_auth/firebase_auth.dart';

class OtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? verificationId;

  static Future<void> sendOtp({
  required String phone,
  required Function() onSuccess,
  required Function(String) onError,
}) async {
  print("🔥 Sending OTP to +91$phone");

  await _auth.verifyPhoneNumber(
    phoneNumber: '+91$phone',

    verificationCompleted: (PhoneAuthCredential credential) async {
      print("✅ Auto verification completed");
      await _auth.signInWithCredential(credential);
      onSuccess();
    },

    verificationFailed: (FirebaseAuthException e) {
      print("❌ Verification failed: ${e.code} | ${e.message}");
      onError(e.message ?? 'OTP failed');
    },

    codeSent: (String verId, int? resendToken) {
      print("📩 OTP SENT!");
      verificationId = verId;
      onSuccess();
    },

    codeAutoRetrievalTimeout: (String verId) {
      print("⏱ Timeout reached");
      verificationId = verId;
    },

    timeout: const Duration(seconds: 60),
  );
}

static Future<bool> verifyOtp(String otp) async {
  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: otp,
    );

    await _auth.signInWithCredential(credential);

    print("✅ OTP VERIFIED SUCCESSFULLY");
    return true;
  } catch (e) {
    print("❌ OTP VERIFY FAILED: $e");
    return false;
  }
}
}