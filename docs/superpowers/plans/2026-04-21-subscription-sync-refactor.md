# Subscription Sync Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor subscription status sync to use a single unified entry point with diff-based node updates, 30s deduplication, and force VPN disconnect.

**Architecture:** Replace scattered `refreshUserInfo()` / `refreshSubscribeInfo()` / `syncSubscription()` calls with a unified `checkSubscriptionStatus()` method that calls one API (`getSubscribeInfo`), diffs the result against cached state, and conditionally triggers node sync / VPN disconnect / profile clearing. All UI pages watch `authNotifierProvider` reactively — no per-page API calls needed.

**Tech Stack:** Flutter/Dart, Riverpod, Freezed, Dio

**Spec:** `docs/superpowers/specs/2026-04-21-subscription-sync-refactor-design.md`

---

See full plan in artifact: `2026-04-21-subscription-sync-refactor-plan.md`
