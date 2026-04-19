# Hiddify App 构建失败 — 根因分析

## 🔴 核心问题

你遇到的所有报错，根本原因只有两个，而且都不需要改代码：

### 问题 1: Flutter SDK 版本不匹配

项目 `pubspec.yaml` 中指定的目标版本:
```yaml
environment:
  sdk: ^3.10.4
  flutter: ^3.38.5
```

而你的 `main` 分支代码对应的是旧版本。项目注释里写得很清楚：

> **This SDK version is strictly required and must not be removed.**
> It is parsed/grep-ed by Makefile and Dockerfile to configure the build environment.
> Ensure this matches the target Flutter version.

**我们之前的错误做法**：直接用 `flutter upgrade` 升级到了最新的 Flutter 3.41.7，导致：
- `font_awesome_flutter` 新版引入了 `FaIconData` 破坏性变更
- Android 依赖（`androidx.core`, `androidx.browser`）版本被拉高，要求更高的 AGP
- `slang_build_runner` 的 `build.yaml` 解析格式不兼容
- 原生 Kotlin 代码中的 `OutboundGroupItem.urlTestDelay` API 消失

**所有这些都是 Flutter SDK 版本不匹配引发的连锁反应。**

### 问题 2: 缺少 hiddify-core 原生库

```
android/app/libs/
└── .gitkeep        ← 空的！没有 .aar 文件
```

这个目录应该包含 hiddify-core 的预编译原生库（`.aar` 文件），它提供了 `com.hiddify.core.libbox.*` 等包。
原生 Kotlin 代码中引用的 `OutboundGroupItem`、`Libbox` 等类都来自这个库。**缺少它，安卓端根本不可能编译成功。**

---

## ✅ 正确的构建流程（来自官方 CONTRIBUTING.md + Makefile）

### 第一步：恢复代码到干净状态
```bash
cd e:\code\vpn\hiddify-app
git checkout .          # 撤销所有修改
git clean -fd           # 清理生成的文件
```

### 第二步：使用项目指定的 Flutter 版本
项目的 `pubspec.yaml` 中指定了 `flutter: ^3.38.5`。你需要切换到匹配的 Flutter 版本：
```bash
# 在 Flutter SDK 目录下
cd D:\sdk\flutter_3.32.8\flutter
git fetch --tags
git checkout 3.38.5       # 切换到项目要求的版本
flutter doctor
```

> [!IMPORTANT]
> 或者更简单的方式：使用 [FVM (Flutter Version Management)](https://fvm.app/) 来管理多个 Flutter 版本。

### 第三步：执行官方的 `make android-prepare`
这一步做了三件事（见 Makefile）：

```makefile
android-prepare: common-prepare android-libs

common-prepare: get gen translate
# 1. flutter pub get      ← 获取依赖
# 2. dart run build_runner ← 生成代码
# 3. dart run slang        ← 生成翻译

android-libs:
# 4. 从 GitHub Releases 下载 hiddify-core 预编译库到 android/app/libs/
```

**在 Windows 上手动执行等价操作**：

```bash
cd e:\code\vpn\hiddify-app

# 1. 获取依赖
flutter pub get

# 2. 生成代码
dart run build_runner build --delete-conflicting-outputs

# 3. 生成翻译
dart run slang

# 4. 下载 Android 原生核心库 (核心版本在 dependencies.properties 里定义为 4.1.0)
mkdir -p android/app/libs
curl -L https://github.com/hiddify/hiddify-next-core/releases/download/v4.1.0/hiddify-lib-android.tar.gz | tar xz -C android/app/libs/
```

### 第四步：运行
```bash
flutter run
```

---

## 📋 我们之前做了哪些不该做的修改

| 文件 | 修改内容 | 是否应该改 |
|------|---------|-----------|
| `pubspec.yaml` | 升级 `font_awesome_flutter` 到 ^11.0.0, 移除 `slang_build_runner` | ❌ 不该改 |
| `build.yaml` | 删除 `slang_build_runner` 配置 | ❌ 不该改 |
| `slang.yaml` | 新建文件 | ❌ 不该建 |
| `connection_button.dart` | `Icon` → `FaIcon` | ❌ 不该改 |
| `json_editor.dart` | `Icon` → `FaIcon` | ❌ 不该改 |
| `OutboundMapper.kt` | `item.urlTestDelay` → `0` | ❌ 不该改 |
| `android/settings.gradle` | AGP 8.6.0 → 8.9.1 | ❌ 不该改 |
| `gradle-wrapper.properties` | Gradle 8.7 → 8.11.1 | ❌ 不该改 |

**所有这些修改都是因为 Flutter 版本不匹配引发的连锁问题。使用正确的 Flutter 版本 + 下载核心库后，原始代码就能直接编译。**

---

## ⚡ 快速修复方案

```bash
# 1. 还原所有代码修改
cd e:\code\vpn\hiddify-app
git checkout .
rm slang.yaml   # 删除额外创建的文件

# 2. 切换 Flutter SDK 版本到 3.38.5
#    (需要在你的 Flutter SDK 安装目录操作)

# 3. 下载核心库
mkdir android\app\libs 2>nul
curl -L https://github.com/hiddify/hiddify-next-core/releases/download/v4.1.0/hiddify-lib-android.tar.gz -o core.tar.gz
tar xzf core.tar.gz -C android/app/libs/
del core.tar.gz

# 4. 重新准备
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run slang

# 5. 运行
flutter run
```
