import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:hiddify/features/auth/model/auth_state.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/auth/widget/gradient_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final siteConfigAsync = ref.watch(siteConfigProvider);
    final t = ref.watch(translationsProvider).requireValue;
    final tr = t.pages.auth.register;

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final inviteCodeController = useTextEditingController();
    final emailCodeController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);
    final tosAccepted = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final countdown = useState(0);
    final isSendingCode = useState(false);
    final isLoading = authState is AuthLoading;

    useEffect(() {
      if (countdown.value <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (countdown.value > 0) countdown.value--;
      });
      return timer.cancel;
    }, [countdown.value > 0]);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is Authenticated) {
        context.goNamed('home');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: theme.colorScheme.error),
        );
      }
    });

    final isEmailVerify = siteConfigAsync.whenOrNull(data: (c) => c['is_email_verify'] == 1) ?? false;
    final isInviteForce = siteConfigAsync.whenOrNull(data: (c) => c['is_invite_force'] == 1) ?? false;

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
                Text(tr.title, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Gap(6),
                Text(tr.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const Gap(32),

                // Email
                _buildTextField(theme: theme, controller: emailController, label: tr.emailLabel, hint: tr.emailHint, icon: Icons.email_outlined, enabled: !isLoading, keyboardType: TextInputType.emailAddress, validator: (v) {
                  if (v == null || v.trim().isEmpty) return tr.emailRequired;
                  if (!v.contains('@')) return tr.emailInvalid;
                  return null;
                }),
                const Gap(16),

                // Password
                _buildTextField(theme: theme, controller: passwordController, label: tr.setPassword, icon: Icons.lock_outlined, enabled: !isLoading, obscureText: obscurePassword.value, suffixIcon: IconButton(icon: Icon(obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => obscurePassword.value = !obscurePassword.value), validator: (v) {
                  if (v == null || v.isEmpty) return tr.passwordRequired;
                  if (v.length < 8) return tr.passwordTooShort;
                  return null;
                }),
                const Gap(16),

                // Confirm password
                _buildTextField(theme: theme, controller: confirmPasswordController, label: tr.confirmPassword, icon: Icons.verified_user_outlined, enabled: !isLoading, obscureText: obscureConfirm.value, suffixIcon: IconButton(icon: Icon(obscureConfirm.value ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => obscureConfirm.value = !obscureConfirm.value), validator: (v) {
                  if (v != passwordController.text) return tr.passwordMismatch;
                  return null;
                }),
                const Gap(16),

                // Email verification code (conditional)
                if (isEmailVerify) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 7, child: _buildTextField(theme: theme, controller: emailCodeController, label: tr.emailCode, icon: Icons.pin_outlined, enabled: !isLoading, keyboardType: TextInputType.number, validator: (v) {
                      if (v == null || v.isEmpty) return tr.codeRequired;
                      return null;
                    })),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: SizedBox(height: 56, child: FilledButton.tonal(
                      onPressed: (countdown.value > 0 || isSendingCode.value || isLoading) ? null : () async {
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
                ],

                // Invite code
                _buildTextField(theme: theme, controller: inviteCodeController, label: isInviteForce ? tr.inviteCode : tr.inviteCodeOptional, icon: Icons.card_giftcard_outlined, enabled: !isLoading, validator: isInviteForce ? (v) {
                  if (v == null || v.trim().isEmpty) return tr.inviteCodeRequired;
                  return null;
                } : null),
                const Gap(20),

                // ToS checkbox
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 24, height: 24, child: Checkbox(value: tosAccepted.value, onChanged: (v) => tosAccepted.value = v ?? false, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(width: 8),
                  Expanded(child: GestureDetector(onTap: () => tosAccepted.value = !tosAccepted.value, child: Text.rich(TextSpan(text: tr.tosPrefix, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), children: [
                    TextSpan(text: tr.tosTerms, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
                    TextSpan(text: tr.tosAnd),
                    TextSpan(text: tr.tosPrivacy, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
                  ])))),
                ]),
                const Gap(24),

                // Register button
                GradientButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      ref.read(authNotifierProvider.notifier).register(emailController.text.trim(), passwordController.text, inviteCode: inviteCodeController.text.trim(), emailCode: isEmailVerify ? emailCodeController.text.trim() : null);
                    }
                  },
                  label: tr.registerButton,
                  icon: Icons.arrow_forward,
                  isLoading: isLoading,
                  enabled: tosAccepted.value,
                ),
                const Gap(16),

                // Back to login
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(tr.hasAccount, style: theme.textTheme.bodyMedium),
                  TextButton(onPressed: isLoading ? null : () => Navigator.of(context).pop(), child: Text(tr.backToLogin)),
                ]),
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
