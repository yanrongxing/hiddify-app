# Auth Pages Refactor — Hiddify Flutter App

> **Date**: 2026-04-20
> **Project**: hiddify-app (Flutter/Dart)
> **Reference**: Stitch project `10673507694413708140` (Login + Register screens)
> **Backend API**: Xboard OpenAPI (`openapi.yaml`)

## Goal

Refactor LoginPage, RegisterPage, ForgotPasswordPage in the Hiddify Flutter app to match the Stitch "Kinetic Ether" design language. Add site config API to conditionally show email verification / invite code fields.

## Decisions

| Decision | Choice |
|----------|--------|
| Back button target | Login→Home(pop), Register→Login(pop), Reset→Login(pop) |
| Terms of Service | Add checkbox to Register, disable submit when unchecked |
| Site config API | Add `getConfig()` to AuthRepository, conditionally show fields |

## Current State

All three pages live in a single file: `lib/features/auth/widget/login_page.dart` (698 lines).
- `LoginPage` — basic email/password form with logo
- `RegisterPage` — email/password/confirm/invite code form
- `ForgotPasswordPage` — two-step: send code → enter code + new password

All use `HookConsumerWidget`, `TextFormField`, and `FilledButton`. No email verification code field on register. No config-based conditional rendering.

## What Changes

### 1. Data Layer: Add Site Config

**File**: `lib/features/auth/data/auth_repository.dart`

Add method:
```dart
Future<Map<String, dynamic>> getSiteConfig() async {
  final response = await _dio.get('/api/v1/guest/comm/config');
  return response.data['data'] as Map<String, dynamic>;
}
```

**File**: `lib/features/auth/data/auth_data_providers.dart`

Add provider:
```dart
@riverpod
Future<Map<String, dynamic>> siteConfig(Ref ref) async {
  return ref.read(authRepositoryProvider).getSiteConfig();
}
```

### 2. Split Single File into Three Files

Split `login_page.dart` (698 lines) into:
- `lib/features/auth/widget/login_page.dart` — LoginPage only
- `lib/features/auth/widget/register_page.dart` — RegisterPage only
- `lib/features/auth/widget/forgot_password_page.dart` — ForgotPasswordPage only

### 3. Visual Restyling (All Three Pages)

Match Stitch design language using Flutter's Material 3 theme:

**Back button**: Each page already uses `AppBar` or `Scaffold`. Add explicit back icon for pages that need it. LoginPage gets an AppBar with back button to pop to previous screen.

**Header area**:
- Decorative icon (shield for login, rocket for register, lock_reset for forgot)
- Large title: `theme.textTheme.headlineLarge` with bold weight
- Subtle subtitle

**Input fields**: Keep `TextFormField` with `OutlineInputBorder`, radius 16 (up from 12). Use filled variant with `fillColor: theme.colorScheme.surfaceContainerLow`.

**Primary button**: Gradient-style using `Container` + `InkWell` with `LinearGradient` from `primary` to `primaryContainer`, rounded 24, with arrow icon.

**Bottom links**: Keep current `TextButton` style, it works well with Material theme.

### 4. LoginPage Changes

- AppBar with back button (pops to previous screen)
- Shield icon at top
- Title: "欢迎回来" / "Welcome Back"
- Email field (icon: `Icons.email_outlined`)
- Password field (icon: `Icons.key_outlined`, was `lock_outlined`)
- Remember me row removed (not applicable in mobile app)
- Forgot password link
- Gradient submit button with arrow
- Register link at bottom

### 5. RegisterPage Changes

- AppBar with back button → pops to LoginPage
- Title: "创建账户"
- Watch `siteConfigProvider` to get `is_email_verify` and `is_invite_force`
- Fields:
  1. Email
  2. Password (with toggle)
  3. Confirm Password (with toggle)
  4. Email Verification Code (conditional: `is_email_verify == 1`) with "Send Code" button + countdown
  5. Invite Code (label changes: required vs optional based on `is_invite_force`)
  6. **NEW**: Terms of Service checkbox
- Submit button disabled when ToS unchecked
- Gradient submit button
- "Already have account? Login" link

### 6. ForgotPasswordPage Changes

- AppBar with back button → pops to LoginPage
- Lock reset icon
- Title: "重置密码"
- Show all fields at once (remove two-step flow for simplicity):
  1. Email
  2. Verification Code + Send Code button with countdown
  3. New Password (with toggle)
  4. Confirm Password (with toggle, NEW)
- Gradient submit button

## Files Modified

| File | Change |
|------|--------|
| `lib/features/auth/data/auth_repository.dart` | Add `getSiteConfig()` |
| `lib/features/auth/data/auth_data_providers.dart` | Add `siteConfigProvider` |
| `lib/features/auth/widget/login_page.dart` | Rewrite (keep only LoginPage) |
| `lib/features/auth/widget/register_page.dart` | NEW file |
| `lib/features/auth/widget/forgot_password_page.dart` | NEW file |

## What Does NOT Change

- `auth_notifier.dart` — state management unchanged
- `auth_state.dart` / `auth_state.freezed.dart` — unchanged
- `user_model.dart` — unchanged
- Theme (`app_theme.dart`) — uses existing Material 3 theme tokens
- Navigation — pages still use `Navigator.push`/`pop`
