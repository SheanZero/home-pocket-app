import Flutter
import UIKit
import UserNotifications

private let apnsPushMethodChannelName = "home_pocket/apns_push/methods"
private let apnsPushTokenEventChannelName = "home_pocket/apns_push/token_refresh"
private let apnsPushForegroundEventChannelName = "home_pocket/apns_push/foreground_messages"
private let apnsPushOpenedEventChannelName = "home_pocket/apns_push/opened_messages"

private final class PushEventStreamHandler: NSObject, FlutterStreamHandler {
  private(set) var eventSink: FlutterEventSink?

  var hasListener: Bool {
    eventSink != nil
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func emit(_ event: Any) {
    guard let eventSink else { return }
    DispatchQueue.main.async {
      eventSink(event)
    }
  }
}

private extension Data {
  var hexEncodedString: String {
    map { String(format: "%02x", $0) }.joined()
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let tokenStreamHandler = PushEventStreamHandler()
  private let foregroundStreamHandler = PushEventStreamHandler()
  private let openedStreamHandler = PushEventStreamHandler()

  private var methodChannel: FlutterMethodChannel?
  private var apnsToken: String?
  private var pendingInitialMessage: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      pendingInitialMessage = normalize(userInfo: remoteNotification)
    }
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let methodChannel = FlutterMethodChannel(
      name: apnsPushMethodChannelName,
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler(handleMethodCall)
    self.methodChannel = methodChannel

    FlutterEventChannel(
      name: apnsPushTokenEventChannelName,
      binaryMessenger: messenger
    ).setStreamHandler(tokenStreamHandler)

    FlutterEventChannel(
      name: apnsPushForegroundEventChannelName,
      binaryMessenger: messenger
    ).setStreamHandler(foregroundStreamHandler)

    FlutterEventChannel(
      name: apnsPushOpenedEventChannelName,
      binaryMessenger: messenger
    ).setStreamHandler(openedStreamHandler)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.hexEncodedString
    apnsToken = token
    tokenStreamHandler.emit(token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let payload = normalize(userInfo: userInfo)
    if !payload.isEmpty {
      foregroundStreamHandler.emit(payload)
    }
    completionHandler(.newData)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.trigger is UNPushNotificationTrigger {
      let payload = normalize(userInfo: notification.request.content.userInfo)
      if !payload.isEmpty {
        foregroundStreamHandler.emit(payload)
      }
      completionHandler([])
      return
    }

    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let payload = normalize(userInfo: response.notification.request.content.userInfo)
    if !payload.isEmpty {
      if openedStreamHandler.hasListener {
        openedStreamHandler.emit(payload)
      } else {
        pendingInitialMessage = payload
      }
    }
    completionHandler()
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestPermission(result: result)
    case "getToken":
      result(apnsToken)
    case "getInitialMessage":
      let message = pendingInitialMessage
      pendingInitialMessage = nil
      result(message)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermission(result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error {
        result(
          FlutterError(
            code: "apns_permission_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }

      guard granted else {
        result(nil)
        return
      }

      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      }
    }
  }

  private func normalize(userInfo: [AnyHashable: Any]) -> [String: Any] {
    var normalized: [String: Any] = [:]

    for (key, value) in userInfo {
      guard let key = key as? String else { continue }
      if key == "aps" { continue }
      if let value = normalize(value: value) {
        normalized[key] = value
      }
    }

    return normalized
  }

  private func normalize(value: Any) -> Any? {
    switch value {
    case let string as String:
      return string
    case let number as NSNumber:
      return number
    case let dictionary as [AnyHashable: Any]:
      return normalize(userInfo: dictionary)
    case let array as [Any]:
      return array.compactMap(normalize(value:))
    default:
      return nil
    }
  }
}
