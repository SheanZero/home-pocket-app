/// Connection state for the WebSocket realtime channel.
enum WebSocketConnectionState {
  /// Not connected. Fallback to polling.
  disconnected,

  /// Connection attempt in progress.
  connecting,

  /// Connected and authenticated. Receiving realtime events.
  connected,
}
