import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailOtpService {
  static const String baseUrl = "http://192.168.1.105:8000"; // your laptop IP

  static Future<bool> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/otp/send-email-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/otp/verify-email-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    return response.statusCode == 200;
  }
}