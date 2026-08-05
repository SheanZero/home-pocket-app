# iOS Simulator 截图采集命令

这些命令只负责构建、安装、切换启动语言和截屏；页面导航、演示数据录入与隐私复核仍需人工完成。

## 推荐模拟器

- iPhone 16 Pro Max：原生 1320×2868，属于 6.9 英寸接受规格。
- iPad Pro 13-inch (M4)：原生 2064×2752，属于 13 英寸接受规格。

先查看本机实际名称：

```bash
xcrun simctl list devices available
```

## 构建 Simulator Release

```bash
flutter clean
flutter pub get
flutter build ios --simulator --release
```

## 安装与启动

以下以已在 Simulator app 中启动目标设备为前提：

```bash
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

日语：

```bash
xcrun simctl launch --terminate-running-process booted \
  com.sheanzero.happypocket.app \
  -AppleLanguages '(ja)' \
  -AppleLocale 'ja_JP'
```

简体中文：

```bash
xcrun simctl launch --terminate-running-process booted \
  com.sheanzero.happypocket.app \
  -AppleLanguages '(zh-Hans)' \
  -AppleLocale 'zh_CN'
```

英语：

```bash
xcrun simctl launch --terminate-running-process booted \
  com.sheanzero.happypocket.app \
  -AppleLanguages '(en)' \
  -AppleLocale 'en_US'
```

每次切换语言后，完整退出并重新启动 app，确认权限弹窗与系统文案也使用预期语言。

## 截屏

导航到分镜要求的页面后：

```bash
xcrun simctl io booted screenshot \
  publish/ios/screenshots/raw/ja/iphone-6.9/01-home.png
```

按 `storyboard.csv` 重复 5 个页面，再切换 locale/device。若模拟器输出不是目标原生像素，停止采集并选用正确 device；不要事后拉伸。

## 真机补充

Simulator 图可用于 App Store，但以下项目仍需真机/TestFlight 证据：Face ID、APNs production、麦克风/语音识别、照片权限、后台状态和双设备同步。审核附件中的双设备演示应优先使用真实设备。
