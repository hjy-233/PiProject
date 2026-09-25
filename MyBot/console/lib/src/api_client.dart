import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mybot_console/src/models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? _defaultBaseUri();

  final http.Client _client;
  final Uri _baseUri;

  static Uri _defaultBaseUri() {
    const configured = String.fromEnvironment('MYBOT_API_BASE');
    if (configured.isNotEmpty) return Uri.parse(configured);
    return Uri(scheme: Uri.base.scheme, host: Uri.base.host, port: 11000);
  }

  Future<List<Library>> libraries() async {
    final json = await _request('GET', '/api/v1/libraries') as List<dynamic>;
    return json
        .map((item) => Library.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Library> createLibrary({
    required String name,
    required String workspacePath,
    required MemoryMode memoryMode,
  }) async {
    final json = await _request(
      'POST',
      '/api/v1/libraries',
      body: {
        'name': name,
        'workspacePath': workspacePath,
        'memoryMode': memoryMode.name,
      },
    );
    return Library.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Conversation>> conversations(String libraryId) async {
    final json =
        await _request('GET', '/api/v1/libraries/$libraryId/conversations')
            as List<dynamic>;
    return json
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> createConversation(
    String libraryId,
    String title,
  ) async {
    final json = await _request(
      'POST',
      '/api/v1/libraries/$libraryId/conversations',
      body: {'title': title},
    );
    return Conversation.fromJson(json as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final json =
        await _request('GET', '/api/v1/conversations/$conversationId/messages')
            as List<dynamic>;
    return json
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String?> latestTaskState(String conversationId) async {
    final json =
        await _request('GET', '/api/v1/conversations/$conversationId/tasks')
            as List<dynamic>;
    if (json.isEmpty) return null;
    return (json.first as Map<String, dynamic>)['state'] as String;
  }

  Future<PromptResult> sendMessage(
    String conversationId,
    String content,
  ) async {
    final json = await _request(
      'POST',
      '/api/v1/conversations/$conversationId/messages',
      body: {'content': content},
    );
    return PromptResult.fromJson(json as Map<String, dynamic>);
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final uri = _baseUri.resolve(path);
    final response = switch (method) {
      'GET' => await _client.get(uri),
      'POST' => await _client.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      ),
      _ => throw ArgumentError.value(method, 'method'),
    };
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map<String, dynamic>
          ? decoded['error'] as Map<String, dynamic>?
          : null;
      throw ApiException(
        error?['message'] as String? ?? 'HTTP ${response.statusCode}',
      );
    }
    return decoded;
  }
}
