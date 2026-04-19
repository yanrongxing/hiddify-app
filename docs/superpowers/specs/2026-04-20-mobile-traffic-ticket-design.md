# Mobile Traffic and Ticket Center Design Spec

## 1. Overview
This specification outlines the implementation details for adding the "Traffic Records" (流量记录) and "Ticket Center" (工单中心) features to the **Hiddify App (Flutter)**. These features are adapted from the Web Xboard design and tailored for a native mobile experience, using Riverpod for state management and Dio for network requests.

## 2. Architecture & Data Flow

### 2.1 API & Network Layer
- **Repositories**: We will create `TrafficRepository` and `TicketRepository` in `lib/features/settings/data/`, extending the existing HTTP client approach used by `AuthRepository`.
- **State Management**: Using Riverpod's `@riverpod` to generate `FutureProvider`s for fetching lists (Traffic Logs and Tickets). This will seamlessly handle `AsyncLoading`, `AsyncData`, and `AsyncError` states.
- **Endpoints Used**:
  - `GET /api/v1/user/stat/getTrafficLog`
  - `GET /api/v1/user/ticket/fetch`
  - `POST /api/v1/user/ticket/save`
  - `POST /api/v1/user/ticket/reply`
  - `POST /api/v1/user/ticket/close`

## 3. UI/UX Design

### 3.1 Traffic Records (流量记录)
- **Entry Point**: Added to the `AdvancedSettingsPage` (高级设置) under a new `ACCOUNT` / `USAGE` section.
- **Page Layout (`TrafficRecordsPage`)**:
  - **Hero Card**: Displays current usage over total quota (`user.u + user.d` / `user.transferEnable`) with a progress bar.
  - **History List**: A `ListView` mapping the history logs fetched from the API. Each item represents a daily record (Upload, Download, Total).
  - **Empty State**: Friendly icon and message if no traffic records exist.

### 3.2 Customer Service Page (客服页面)
- **Entry Point**: Clicking "在线客服" in the main `SettingsPage`.
- **Page Layout (`SupportPage`)**:
  - A simple Scaffold containing two large actionable cards:
    1. **💬 人工客服** (Live Support - navigates to an external link or placeholder).
    2. **🎫 工单支持中心** (Ticket Center - navigates to `TicketCenterPage`).

### 3.3 Ticket Center (工单中心)
- **Ticket List (`TicketCenterPage`)**:
  - Displays a list of all tickets via Riverpod `AsyncValue`.
  - Each ticket card shows the Subject, Level, Status (color-coded), and Last Reply Date.
  - **Floating Action Button (FAB)**: Placed at the bottom right to create a new ticket.

- **Create Ticket (`TicketCreateSheet`)**:
  - A `showModalBottomSheet` containing a form (Subject, Level Dropdown, Message Textfield).
  - Discarding the web modal approach for better mobile ergonomics.
  - Submitting refreshes the Ticket List provider.

- **Ticket Detail / Chat (`TicketDetailPage`)**:
  - Navigated to by tapping a ticket in the list.
  - **Chat Bubble Layout**: Renders messages sequentially to mimic a chat app (user messages on right, admin messages on left).
  - **Reply Bar**: Fixed at the bottom. Only visible if the ticket is not closed.
  - **Close Ticket**: Available via a top-right Appbar action menu (`...`).

## 4. Internationalization (i18n)
- Text strings will be added to the existing `translations.dart` or Slang `i18n` locale JSON files inside Hiddify (depending on the localization system currently used in the app, usually `strings_en.i18n.json`, `strings_zh.i18n.json`).

## 5. Ambiguity Resolution
- **Bottom Sheet vs Modal**: Chose Bottom Sheet for Ticket Creation as it provides better thumb reachability on mobile.
- **Support Page Layout**: Adopted the 2-card layout (Option B) to keep the Ticket Center and Live Support clearly separated without cluttering a single view.
