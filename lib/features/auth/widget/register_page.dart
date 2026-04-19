import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
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

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final inviteCodeController = useTextEditingController();
    final emailCodeController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);
    final tosAccepted = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Countdown for email verification code
    final countdown = useState(0);
    final isSendingCode = useState(false);

    final isLoading = authState is AuthLoading;

    // Countdown timer effect
    useEffect(() {
      if (countdown.value <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (countdown.value > 0) {
          countdown.value--;
        }
      });
      return timer.cancel;
    }, [countdown.value > 0]);

    // Listen for auth state changes
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is Authenticated) {
        context.goNamed('home');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    // Extract config values
    final isEmailVerify = siteConfigAsync.whenOrNull(
          data: (config) => config['is_email_verify'] == 1,
        ) ??
        false;
    final isInviteForce = siteConfigAsync.whenOrNull(
          data: (config) => config['is_invite_force'] == 1,
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SECURE NODE INITIALIZATION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Title
                  Text(
                    '创建账户',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    '填写以下信息注册您的账户',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(32),

                  // Email
                  _buildTextField(
                    theme: theme,
                    controller: emailController,
                    label: '邮箱地址',
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邮箱地址';
                      }
                      if (!value.contains('@')) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),

                  // Password
                  _buildTextField(
                    theme: theme,
                    controller: passwordController,
                    label: '设置密码',
                    icon: Icons.lock_outlined,
                    enabled: !isLoading,
                    obscureText: obscurePassword.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          obscurePassword.value = !obscurePassword.value,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 8) {
                        return '密码至少8位';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),

                  // Confirm password
                  _buildTextField(
                    theme: theme,
                    controller: confirmPasswordController,
                    label: '确认密码',
                    icon: Icons.verified_user_outlined,
                    enabled: !isLoading,
                    obscureText: obscureConfirm.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          obscureConfirm.value = !obscureConfirm.value,
                    ),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),

                  // Email verification code (conditional)
                  if (isEmailVerify) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _buildTextField(
                            theme: theme,
                            controller: emailCodeController,
                            label: '邮箱验证码',
                            icon: Icons.pin_outlined,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入验证码';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 56,
                            child: FilledButton.tonal(
                              onPressed: (countdown.value > 0 ||
                                      isSendingCode.value ||
                                      isLoading)
                                  ? null
                                  : () async {
                                      final email =
                                          emailController.text.trim();
                                      if (email.isEmpty ||
                                          !email.contains('@')) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('请先输入有效的邮箱地址'),
                                          ),
                                        );
                                        return;
                                      }
                                      isSendingCode.value = true;
                                      try {
                                        await ref
                                            .read(authRepositoryProvider)
                                            .sendResetEmail(email);
                                        countdown.value = 60;
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('验证码已发送'),
                                            ),
                                          );
                                        }
                                      } on AuthException catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(e.message),
                                              backgroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                          );
                                        }
                                      } finally {
                                        isSendingCode.value = false;
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                countdown.value > 0
                                    ? '${countdown.value}s'
                                    : '发送',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                  ],

                  // Invite code
                  _buildTextField(
                    theme: theme,
                    controller: inviteCodeController,
                    label: isInviteForce ? '邀请码' : '邀请码（可选）',
                    icon: Icons.card_giftcard_outlined,
                    enabled: !isLoading,
                    validator: isInviteForce
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入邀请码';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const Gap(20),

                  // Terms of Service checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: tosAccepted.value,
                          onChanged: (v) => tosAccepted.value = v ?? false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              tosAccepted.value = !tosAccepted.value,
                          child: Text.rich(
                            TextSpan(
                              text: '我已阅读并同意 ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: '服务条款',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' 和 '),
                                TextSpan(
                                  text: '隐私政策',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),

                  // Register button
                  GradientButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        ref.read(authNotifierProvider.notifier).register(
                              emailController.text.trim(),
                              passwordController.text,
                              inviteCode: inviteCodeController.text.trim(),
                              emailCode: isEmailVerify
                                  ? emailCodeController.text.trim()
                                  : null,
                            );
                      }
                    },
                    label: '注册',
                    icon: Icons.arrow_forward,
                    isLoading: isLoading,
                    enabled: tosAccepted.value,
                  ),
                  const Gap(16),

                  // Back to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('已有账户？', style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('返回登录'),
                      ),
                    ],
                  ),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    String? hint,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      validator: validator,
    );
  }
}
