import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../config/app_config.dart';
import '../models/realtime_message.dart';

// ── Realtime provider ─────────────────────────────────────────────────────
/// Wraps a STOMP connection to the backend's WebSocket endpoint and exposes
/// a reactive [Stream<RealtimeMessage>].
///
/// STOMP connection code lives here — never in the view.

class RealtimeProvider {
  const RealtimeProvider({
    this.url = const String.fromEnvironment('REALTIME_URL'),
    this.destination = const String.fromEnvironment(
      'REALTIME_AMBULANCE_DESTINATION',
      defaultValue: '/topic/ambulance-locations',
    ),
    this.useSockJs = const bool.fromEnvironment(
      'REALTIME_USE_SOCKJS',
      defaultValue: true,
    ),
  });

  final String url;
  final String destination;
  final bool useSockJs;

  /// Returns a broadcast-capable stream of [RealtimeMessage] events.
  /// The STOMP client connects on first listen and disconnects on cancel.
  Stream<RealtimeMessage> watchEvents() {
    StompClient? client;
    late final StreamController<RealtimeMessage> events;

    void addError(Object error) {
      if (!events.isClosed) events.addError(error);
    }

    void onConnect(StompFrame frame) {
      try {
        client!.subscribe(
          destination: destination,
          callback: (message) {
            try {
              final parsed = _parseMessage(message);
              if (parsed != null && !events.isClosed) events.add(parsed);
            } catch (error) {
              addError(error);
            }
          },
        );
        if (!events.isClosed) {
          events.add(
            RealtimeMessage(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              type: 'realtime.connected',
              payload: const <String, Object?>{},
            ),
          );
        }
      } catch (error) {
        addError(error);
      }
    }

    final config = useSockJs
        ? StompConfig.sockJS(
            url: _resolvedUrl(),
            onConnect: onConnect,
            onStompError: (frame) => addError(
              StateError(
                frame.body ?? 'The realtime server returned an error.',
              ),
            ),
            onWebSocketError: (error) => addError(error),
            onWebSocketDone: () =>
                addError(StateError('The realtime connection was closed.')),
          )
        : StompConfig(
            url: _resolvedUrl(),
            onConnect: onConnect,
            onStompError: (frame) => addError(
              StateError(
                frame.body ?? 'The realtime server returned an error.',
              ),
            ),
            onWebSocketError: (error) => addError(error),
            onWebSocketDone: () =>
                addError(StateError('The realtime connection was closed.')),
          );

    client = StompClient(config: config);
    events = StreamController<RealtimeMessage>(
      onListen: client.activate,
      onCancel: client.deactivate,
    );
    return events.stream;
  }

  // ────────────────────────────────────────────────────────────────────────

  String _resolvedUrl() {
    final configuredUrl = url.trim();
    final apiUri = Uri.parse(
      configuredUrl.isEmpty ? AppConfig.apiBaseUrl : configuredUrl,
    );
    final basePath = apiUri.path.endsWith('/')
        ? apiUri.path.substring(0, apiUri.path.length - 1)
        : apiUri.path;
    final path = configuredUrl.isEmpty ? '$basePath/ws' : basePath;
    final scheme = useSockJs
        ? switch (apiUri.scheme) {
            'ws' => 'http',
            'wss' => 'https',
            _ => apiUri.scheme,
          }
        : switch (apiUri.scheme) {
            'http' => 'ws',
            'https' => 'wss',
            _ => apiUri.scheme,
          };
    return apiUri.replace(scheme: scheme, path: path).toString();
  }

  RealtimeMessage? _parseMessage(StompFrame frame) {
    final body = frame.body?.trim() ?? '';
    if (body.isEmpty) return null;

    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final message = decoded.map(
      (key, value) => MapEntry(key.toString(), value as Object?),
    );
    final payloadValue = message['payload'] ?? message['data'] ?? message;
    final payload = payloadValue is Map
        ? payloadValue.map(
            (key, value) => MapEntry(key.toString(), value as Object?),
          )
        : message;

    return RealtimeMessage(
      id:
          (message['id'] ??
                  message['eventId'] ??
                  DateTime.now().microsecondsSinceEpoch)
              .toString(),
      type: (message['type'] ?? message['eventType'] ?? 'ambulance.location')
          .toString(),
      payload: payload,
    );
  }
}
