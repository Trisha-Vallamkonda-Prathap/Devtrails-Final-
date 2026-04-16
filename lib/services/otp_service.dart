import 'package:firebase_auth/firebase_auth.dart';

class OtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? verificationId;

  static Future<void> sendOtp({
    required String phone,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'OTP failed');
      },
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
        onSuccess();
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  static Future<bool> verifyOtp(String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }
}