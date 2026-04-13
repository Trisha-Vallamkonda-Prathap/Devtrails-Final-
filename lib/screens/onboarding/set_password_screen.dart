import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/insurer_colors.dart';
import '../../utils/auth_utils.dart';
import '../insurer/insurance_dashboard_screen.dart';
import 'terms_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({
    super.key,
    required this.role,
    required this.phone,
  });

  final AppRole role;
  final String phone;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _saving = false;

  bool get _hasLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passwordController.text);

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty && _passwordController.text == _confirmController.text;

  bool get _canSubmit => _hasLength && _hasUppercase && _hasNumber && _passwordsMatch;

  bool get _isInsurer => widget.role == AppRole.insurer;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    if (!_canSubmit || _saving) {
      return;
    }

    setState(() => _saving = true);

    final userId = AuthUtils.userIdFromPhone(phone: widget.phone, role: widget.role);
    await AuthUtils.persistPassword(userId: userId, password: _passwordController.text);
    await AuthUtils.markLoggedIn();

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (_isInsurer) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute<void>(builder: (_) => const InsuranceDashboardScreen()),
        (route) => false,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute<void>(builder: (_) => const TermsScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInsurer) {
      return _buildInsurerView();
    }
    return _buildWorkerView();
  }

  Widget _buildWorkerView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: bottomInset + 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    TealHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Text(
                            'Set your password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Create a secure password for +91 ${widget.phone}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppCard(
                          child: _passwordForm(
                            textColor: AppColors.textPrimary,
                            hintColor: AppColors.textSoft,
                            fieldFillColor: const Color(0xFFF5F5F5),
                            borderColor: AppColors.divider,
                            accentColor: AppColors.primary,
                            successColor: const Color(0xFF2E7D32),
                            button: GradientButton(
                              label: 'Set Password',
                              isLoading: _saving,
                              onPressed: _canSubmit ? _setPassword : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInsurerView() {
    return Scaffold(
      backgroundColor: InsurerColors.background,
      appBar: AppBar(
        backgroundColor: InsurerColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: InsurerColors.textPrimary),
        title: const Text(
          'Set Password',
          style: TextStyle(color: InsurerColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: InsurerColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: InsurerColors.border),
              ),
              child: _passwordForm(
                textColor: InsurerColors.textPrimary,
                hintColor: InsurerColors.textSecondary,
                fieldFillColor: const Color(0xFF141414),
                borderColor: InsurerColors.border,
                accentColor: InsurerColors.accent,
                successColor: const Color(0xFF43A047),
                button: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_saving ? _setPassword : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InsurerColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: InsurerColors.muted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Set Password', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordForm({
    required Color textColor,
    required Color hintColor,
    required Color fieldFillColor,
    required Color borderColor,
    required Color accentColor,
    required Color successColor,
    required Widget button,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create password',
          style: TextStyle(color: hintColor, fontSize: 12, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: hintColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RuleChip(
              label: 'At least 8 characters',
              met: _hasLength,
              successColor: successColor,
              idleTextColor: hintColor,
            ),
            _RuleChip(
              label: 'One uppercase letter',
              met: _hasUppercase,
              successColor: successColor,
              idleTextColor: hintColor,
            ),
            _RuleChip(
              label: 'One number',
              met: _hasNumber,
              successColor: successColor,
              idleTextColor: hintColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Confirm password',
          style: TextStyle(color: hintColor, fontSize: 12, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmController,
          obscureText: !_showConfirmPassword,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: hintColor,
              ),
            ),
          ),
        ),
        if (_confirmController.text.isNotEmpty && !_passwordsMatch)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Passwords do not match',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
        button,
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.label,
    required this.met,
    required this.successColor,
    required this.idleTextColor,
  });

  final String label;
  final bool met;
  final Color successColor;
  final Color idleTextColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: met ? successColor.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: met ? successColor : idleTextColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: met ? successColor : idleTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
