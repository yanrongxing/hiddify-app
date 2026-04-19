# Mobile Traffic & Ticket Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Traffic Records and Ticket Center features to the Hiddify Flutter app.

**Architecture:** Create `TrafficRepository` and `TicketRepository` following the existing `SubscriptionRepository` pattern (Dio + Riverpod). Add 5 new page widgets. Wire into existing routing and settings menu.

**Tech Stack:** Flutter, Riverpod, Dio, Freezed, GoRouter.

**Codebase Patterns to Follow:**
- Repository: `lib/features/subscription/data/subscription_repository.dart` — Dio-based, `with InfraLogger`, custom Exception class
- Provider: `lib/features/subscription/data/subscription_data_providers.dart` — `@Riverpod(keepAlive: true)`, gets `authRepo.dio`
- Routing: `lib/core/router/go_router/routing_config_notifier.dart` — GoRoute with `customTransition`
- Settings menu: `lib/features/settings/overview/settings_page.dart` — `_MenuItem` + `_MenuGroup` widgets
- Models: `lib/features/auth/model/user_model.dart` — Freezed + JsonSerializable

---

### Task 1: Create Traffic Data Layer

**Files:**
- Create: `lib/features/traffic/data/traffic_repository.dart`
- Create: `lib/features/traffic/data/traffic_data_providers.dart`
- Create: `lib/features/traffic/model/traffic_log_model.dart`

- [ ] **Step 1: Create `traffic_log_model.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'traffic_log_model.freezed.dart';
part 'traffic_log_model.g.dart';

@freezed
class TrafficLogModel with _$TrafficLogModel {
  const factory TrafficLogModel({
    @JsonKey(name: 'record_at') required int recordAt,
    @Default(0) int u,
    @Default(0) int d,
    @JsonKey(name: 'server_rate') @Default(1.0) double serverRate,
  }) = _TrafficLogModel;

  factory TrafficLogModel.fromJson(Map<String, Object?> json) =>
      _$TrafficLogModelFromJson(json);
}
```

- [ ] **Step 2: Create `traffic_repository.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:hiddify/features/traffic/model/traffic_log_model.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class TrafficRepository with InfraLogger {
  TrafficRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<TrafficLogModel>> getTrafficLog() async {
    try {
      final response = await _dio.get('/api/v1/user/stat/getTrafficLog');
      final dataList = response.data['data'] as List? ?? [];
      return dataList
          .map((e) => TrafficLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      loggy.error('Get traffic log failed', e);
      throw TrafficException(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return '请求失败: ${e.message}';
  }
}

class TrafficException implements Exception {
  TrafficException(this.message);
  final String message;
  @override
  String toString() => 'TrafficException: $message';
}
```

- [ ] **Step 3: Create `traffic_data_providers.dart`**

```dart
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/traffic/data/traffic_repository.dart';
import 'package:hiddify/features/traffic/model/traffic_log_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'traffic_data_providers.g.dart';

@Riverpod(keepAlive: true)
TrafficRepository trafficRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return TrafficRepository(dio: authRepo.dio);
}

@riverpod
Future<List<TrafficLogModel>> trafficLogs(Ref ref) async {
  final repo = ref.watch(trafficRepositoryProvider);
  return repo.getTrafficLog();
}
```

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `.freezed.dart` and `.g.dart` files.

- [ ] **Step 5: Commit**

```
git add lib/features/traffic/
git commit -m "feat: add traffic data layer (repository, model, providers)"
```

---

### Task 2: Create Ticket Data Layer

**Files:**
- Create: `lib/features/ticket/data/ticket_repository.dart`
- Create: `lib/features/ticket/data/ticket_data_providers.dart`
- Create: `lib/features/ticket/model/ticket_model.dart`
- Create: `lib/features/ticket/model/ticket_message_model.dart`

- [ ] **Step 1: Create `ticket_model.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

@freezed
class TicketModel with _$TicketModel {
  const TicketModel._();
  const factory TicketModel({
    required int id,
    required String subject,
    required int level,
    required int status,
    @JsonKey(name: 'created_at') required int createdAt,
    @JsonKey(name: 'updated_at') required int updatedAt,
    @JsonKey(name: 'reply_status') @Default(0) int replyStatus,
  }) = _TicketModel;

  factory TicketModel.fromJson(Map<String, Object?> json) =>
      _$TicketModelFromJson(json);

  /// status: 0=Pending, 1=Closed, 2=Replied
  bool get isClosed => status == 1;
}
```

- [ ] **Step 2: Create `ticket_message_model.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'ticket_message_model.freezed.dart';
part 'ticket_message_model.g.dart';

@freezed
class TicketMessageModel with _$TicketMessageModel {
  const factory TicketMessageModel({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required String message,
    @JsonKey(name: 'created_at') required int createdAt,
    @JsonKey(name: 'is_me') @Default(false) bool isMe,
  }) = _TicketMessageModel;

  factory TicketMessageModel.fromJson(Map<String, Object?> json) =>
      _$TicketMessageModelFromJson(json);
}
```

- [ ] **Step 3: Create `ticket_repository.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:hiddify/features/ticket/model/ticket_model.dart';
import 'package:hiddify/features/ticket/model/ticket_message_model.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class TicketRepository with InfraLogger {
  TicketRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<TicketModel>> fetchTickets() async {
    try {
      final response = await _dio.get('/api/v1/user/ticket/fetch');
      final dataList = response.data['data'] as List? ?? [];
      return dataList.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Fetch tickets failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<List<TicketMessageModel>> fetchTicketMessages(int ticketId) async {
    try {
      final response = await _dio.get('/api/v1/user/ticket/fetch', queryParameters: {'id': ticketId});
      final dataList = response.data['data'] as List? ?? [];
      return dataList.map((e) => TicketMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      loggy.error('Fetch ticket messages failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<void> createTicket({required String subject, required int level, required String message}) async {
    try {
      await _dio.post('/api/v1/user/ticket/save', data: {'subject': subject, 'level': level, 'message': message});
    } on DioException catch (e) {
      loggy.error('Create ticket failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<void> replyTicket(int id, String message) async {
    try {
      await _dio.post('/api/v1/user/ticket/reply', data: {'id': id, 'message': message});
    } on DioException catch (e) {
      loggy.error('Reply ticket failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  Future<void> closeTicket(int id) async {
    try {
      await _dio.post('/api/v1/user/ticket/close', data: {'id': id});
    } on DioException catch (e) {
      loggy.error('Close ticket failed', e);
      throw TicketException(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return '请求失败: ${e.message}';
  }
}

class TicketException implements Exception {
  TicketException(this.message);
  final String message;
  @override
  String toString() => 'TicketException: $message';
}
```

- [ ] **Step 4: Create `ticket_data_providers.dart`**

```dart
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/ticket/data/ticket_repository.dart';
import 'package:hiddify/features/ticket/model/ticket_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'ticket_data_providers.g.dart';

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return TicketRepository(dio: authRepo.dio);
}

@riverpod
Future<List<TicketModel>> ticketList(Ref ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.fetchTickets();
}
```

- [ ] **Step 5: Run code generation and commit**

```
dart run build_runner build --delete-conflicting-outputs
git add lib/features/ticket/
git commit -m "feat: add ticket data layer (repository, models, providers)"
```

---

### Task 3: Create Traffic Records Page

**Files:**
- Create: `lib/features/traffic/widget/traffic_records_page.dart`

- [ ] **Step 1: Create `traffic_records_page.dart`**

Build a `HookConsumerWidget` page with:
- AppBar title: '流量记录'
- Hero card at top showing usage progress bar (reuse pattern from `settings_page.dart` lines 156-216)
- `ref.watch(trafficLogsProvider)` with `.when()` for loading/error/data states
- Data state: `ListView.builder` of Cards, each showing date, upload, download, total
- Empty state: centered Column with icon + text
- Helper function `String formatBytes(int bytes)` converting to MB/GB/TB

- [ ] **Step 2: Commit**

```
git add lib/features/traffic/widget/
git commit -m "feat: add Traffic Records page widget"
```

---

### Task 4: Create Support Hub Page

**Files:**
- Create: `lib/features/ticket/widget/support_page.dart`

- [ ] **Step 1: Create `support_page.dart`**

Build a `StatelessWidget` page with:
- AppBar title: '在线客服'
- Body: Column with two large tappable Cards:
  1. Card 1: Icon `Icons.chat_bubble_outline_rounded`, title '人工客服', subtitle '联系在线客服获取即时帮助', onTap opens external URL or shows placeholder
  2. Card 2: Icon `Icons.confirmation_number_outlined`, title '工单中心', subtitle '提交工单，跟踪问题处理进度', onTap navigates to ticket center page
- Cards styled with `theme.colorScheme.surfaceContainer`, rounded corners, chevron icon

- [ ] **Step 2: Commit**

```
git add lib/features/ticket/widget/support_page.dart
git commit -m "feat: add Support hub page with two card entries"
```

---

### Task 5: Create Ticket Center Page

**Files:**
- Create: `lib/features/ticket/widget/ticket_center_page.dart`
- Create: `lib/features/ticket/widget/ticket_create_sheet.dart`

- [ ] **Step 1: Create `ticket_center_page.dart`**

Build a `HookConsumerWidget` page with:
- AppBar title: '工单中心'
- `ref.watch(ticketListProvider)` with `.when()` for states
- Data: `ListView.builder` of ticket cards (subject, status chip, date)
- Status chips: Pending=amber, Replied=green, Closed=grey
- Empty state: icon + text + '暂无工单'
- FAB: `FloatingActionButton.extended` with '创建工单', opens bottom sheet

- [ ] **Step 2: Create `ticket_create_sheet.dart`**

Build a stateful widget shown via `showModalBottomSheet`:
- Form with: subject TextField, level DropdownButton (一般/重要/紧急 mapped to 0/1/2), message TextField (multiline)
- Submit button calls `ticketRepository.createTicket()`, then `ref.invalidate(ticketListProvider)` and pops

- [ ] **Step 3: Commit**

```
git add lib/features/ticket/widget/ticket_center_page.dart lib/features/ticket/widget/ticket_create_sheet.dart
git commit -m "feat: add Ticket Center page and create ticket bottom sheet"
```

---

### Task 6: Create Ticket Detail Page

**Files:**
- Create: `lib/features/ticket/widget/ticket_detail_page.dart`

- [ ] **Step 1: Create `ticket_detail_page.dart`**

Build a `HookConsumerWidget` page with:
- AppBar title: ticket subject, actions: PopupMenuButton with '关闭工单' option
- Body: Column with Expanded ListView of chat bubbles + bottom reply bar
- Chat bubbles: `isMe` → right-aligned primary color, else left-aligned surfaceContainer
- Each bubble: message text + timestamp
- Reply bar: Row with Expanded TextField + IconButton send (only if !ticket.isClosed)
- Close ticket: confirm dialog → `ticketRepository.closeTicket(id)` → pop back

- [ ] **Step 2: Commit**

```
git add lib/features/ticket/widget/ticket_detail_page.dart
git commit -m "feat: add Ticket Detail page with chat UI"
```

---

### Task 7: Wire Routing and Menu Entries

**Files:**
- Modify: `lib/features/settings/overview/settings_page.dart`
- Modify: `lib/core/router/go_router/routing_config_notifier.dart`

- [ ] **Step 1: Add routes in `routing_config_notifier.dart`**

Import the 4 new page widgets. Add these GoRoutes inside the settings branch `routes` array (after the existing shop/order routes, around line 216):

```dart
GoRoute(
  name: 'trafficRecords',
  path: '/traffic-records',
  pageBuilder: (_, state) => customTransition(TransitionType.slide, state.pageKey, const TrafficRecordsPage()),
),
GoRoute(
  name: 'support',
  path: '/support',
  pageBuilder: (_, state) => customTransition(TransitionType.slide, state.pageKey, const SupportPage()),
),
GoRoute(
  name: 'ticketCenter',
  path: '/ticket-center',
  pageBuilder: (_, state) => customTransition(TransitionType.slide, state.pageKey, const TicketCenterPage()),
),
GoRoute(
  name: 'ticketDetail',
  path: '/ticket-detail/:ticketId',
  pageBuilder: (_, state) => customTransition(
    TransitionType.slide,
    state.pageKey,
    TicketDetailPage(ticketId: int.parse(state.pathParameters['ticketId']!)),
  ),
),
```

- [ ] **Step 2: Add Traffic Records entry in `AdvancedSettingsPage`**

In `settings_page.dart`, inside `AdvancedSettingsPage.build()`, add a new `ACCOUNT` section before the existing `SYSTEM` section (before line 496):

```dart
// Account Header
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  child: Text('ACCOUNT', style: theme.textTheme.labelSmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant, letterSpacing: 2.0, fontWeight: FontWeight.bold,
  )),
),
_MenuGroup(
  children: [
    _MenuItem(
      icon: Icons.data_usage_rounded,
      title: '流量记录',
      onTap: () => context.go(context.namedLocation('trafficRecords')),
      showBorder: false,
    ),
  ],
),
const Gap(24),
```

- [ ] **Step 3: Update '在線客服' menu item in `SettingsPage`**

Change the existing `_MenuItem(icon: Icons.support_agent_rounded, title: '在線客服', onTap: () {})` to navigate to the support page:

```dart
_MenuItem(
  icon: Icons.support_agent_rounded,
  title: '在線客服',
  onTap: () => context.go(context.namedLocation('support')),
),
```

- [ ] **Step 4: Run code generation, build, and commit**

```
dart run build_runner build --delete-conflicting-outputs
git add lib/features/settings/overview/settings_page.dart lib/core/router/go_router/routing_config_notifier.dart
git commit -m "feat: wire traffic/ticket routes and menu entries"
```
