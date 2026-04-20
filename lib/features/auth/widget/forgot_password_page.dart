import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:hiddify/features/auth/widget/gradient_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ForgotPasswordPage extends HookConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final tr = t.pages.auth.forgotPassword;

    final emailController = useTextEditingController();
    final codeController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final obscureNew = useState(true);
    final obscureConfirm = useState(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final countdown = useState(0);
    final isSendingCode = useState(false);
    final resetSuccess = useState(false);

    useEffect(() {
      if (countdown.value <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (countdown.value > 0) countdown.value--;
      });
      return timer.cancel;
    }, [countdown.value > 0]);

    // Success view
    if (resetSuccess.value) {
      return Scaffold(
        appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())
              : null,
          title: const SizedBox.shrink(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                child: Icon(Icons.check_circle_outline, size: 48, color: theme.colorScheme.primary),
              ),
              const Gap(24),
              Text(tr.successTitle, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(8),
              Text(tr.successSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(tr.successButton),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())
            : null,
        title: const SizedBox.shrink(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary)),
                    const SizedBox(width: 8),
                    Text(tr.badge, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Gap(16),

                // Icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: theme.colorScheme.surfaceContainerLow,
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.lock_reset_rounded, size: 32, color: theme.colorScheme.primary),
                ),
                const Gap(20),

                Text(tr.title, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Gap(6),
                Text(tr.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const Gap(32),

                // Email
                _buildTextField(theme: theme, controller: emailController, label: tr.emailLabel, hint: tr.emailHint, icon: Icons.email_outlined, enabled: !isLoading.value, keyboardType: TextInputType.emailAddress, validator: (v) {
                  if (v == null || !v.contains('@')) return tr.emailInvalid;
                  return null;
                }),
                const Gap(16),

                // Code + Send
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 7, child: _buildTextField(theme: theme, controller: codeController, label: tr.codeLabel, icon: Icons.pin_outlined, enabled: !isLoading.value, keyboardType: TextInputType.number, validator: (v) {
                    if (v == null || v.isEmpty) return tr.codeRequired;
                    return null;
                  })),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: SizedBox(height: 56, child: FilledButton.tonal(
                    onPressed: (countdown.value > 0 || isSendingCode.value || isLoading.value) ? null : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.enterValidEmail)));
                        return;
                      }
                      isSendingCode.value = true;
                      try {
                        await ref.read(authRepositoryProvider).sendResetEmail(email);
                        countdown.value = 60;
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.codeSent)));
                      } on AuthException catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: theme.colorScheme.error));
                      } finally {
                        isSendingCode.value = false;
                      }
                    },
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(countdown.value > 0 ? '${countdown.value}s' : tr.sendCode, style: const TextStyle(fontSize: 13)),
                  ))),
                ]),
                const Gap(16),

                // New password
                _buildTextField(theme: theme, controller: newPasswordController, label: tr.newPassword, icon: Icons.lock_outlined, enabled: !isLoading.value, obscureText: obscureNew.value, suffixIcon: IconButton(icon: Icon(obscureNew.value ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => obscureNew.value = !obscureNew.value), validator: (v) {
                  if (v == null || v.length < 8) return tr.passwordTooShort;
                  return null;
                }),
                const Gap(16),

                // Confirm new password
                _buildTextField(theme: theme, controller: confirmPasswordController, label: tr.confirmNewPassword, icon: Icons.lock_reset_outlined, enabled: !isLoading.value, obscureText: obscureConfirm.value, suffixIcon: IconButton(icon: Icon(obscureConfirm.value ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => obscureConfirm.value = !obscureConfirm.value), validator: (v) {
                  if (v != newPasswordController.text) return tr.passwordMismatch;
                  return null;
                }),
                const Gap(28),

                // Reset button
                GradientButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      isLoading.value = true;
                      try {
                        await ref.read(authRepositoryProvider).resetPassword(email: emailController.text.trim(), emailCode: codeController.text.trim(), newPassword: newPasswordController.text);
                        resetSuccess.value = true;
                      } on AuthException catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: theme.colorScheme.error));
                      } finally {
                        isLoading.value = false;
                      }
                    }
                  },
                  label: tr.resetButton,
                  icon: Icons.arrow_forward,
                  isLoading: isLoading.value,
                ),
                const Gap(16),

                // Back to login
                TextButton.icon(
                  onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(tr.backToLogin),
                ),
                const Gap(24),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required ThemeData theme, required TextEditingController controller, required String label, required IconData icon, bool enabled = true, bool obscureText = false, String? hint, Widget? suffixIcon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, obscureText: obscureText, enabled: enabled, keyboardType: keyboardType, textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixIcon: Icon(icon), suffixIcon: suffixIcon, filled: true, fillColor: theme.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary)),
      ),
      validator: validator,
    );
  }
}
