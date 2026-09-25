import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.base.replace(path: path, queryParameters: query);

  Future<List<ProjectSummary>> projects() async {
    final response = await _client.get(_uri('/api/v1/projects'));
    final body = _decode(response);
    return (body as List)
        .map((item) => ProjectSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectDetails> details(String id) async {
    final response = await _client.get(_uri('/api/v1/projects/$id'));
    return ProjectDetails.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<ProjectSummary> create(Map<String, dynamic> body) async {
    final response = await _client.post(
      _uri('/api/v1/projects'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return ProjectSummary.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<ProjectSummary> update(String id, Map<String, dynamic> body) async {
    final response = await _client.put(
      _uri('/api/v1/projects/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return ProjectSummary.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<void> action(String id, String action) async {
    final response = await _client.post(_uri('/api/v1/projects/$id/$action'));
    _decode(response);
  }

  Future<void> deploy(String id, String releaseId) async {
    final response = await _client.post(
      _uri('/api/v1/projects/$id/deploy'),
      headers: _headers,
      body: jsonEncode({'releaseId': releaseId}),
    );
    _decode(response);
  }

  Future<List<String>> gitCredentials() async {
    final response = await _client.get(_uri('/api/v1/git/credentials'));
    final body = _decode(response) as Map<String, dynamic>;
    return List<String>.from(body['credentials'] as List);
  }

  Future<GitSourceInspection> inspectGitSource(
    String projectId,
    Map<String, dynamic> source,
  ) async {
    final response = await _client.post(
      _uri('/api/v1/sources/git/inspect'),
      headers: _headers,
      body: jsonEncode({'projectId': projectId, 'source': source}),
    );
    return GitSourceInspection.fromJson(
      _decode(response) as Map<String, dynamic>,
    );
  }

  Future<void> delete(String id, {required bool purgeVolumes}) async {
    final response = await _client.delete(
      _uri('/api/v1/projects/$id', {'purgeVolumes': '$purgeVolumes'}),
    );
    _decode(response);
  }

  Future<String> logs(String id) async {
    final response = await _client.get(
      _uri('/api/v1/projects/$id/logs', {'lines': '300'}),
    );
    final body = _decode(response) as Map<String, dynamic>;
    return body['output'] as String;
  }

  Object? _decode(http.Response response) {
    final body = response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final message = body is Map<String, dynamic>
        ? ((body['error'] as Map<String, dynamic>?)?['message'] as String? ??
              response.reasonPhrase)
        : response.reasonPhrase;
    throw ApiException(message ?? 'HTTP ${response.statusCode}');
  }

  static const _headers = {'Content-Type': 'application/json'};
}
