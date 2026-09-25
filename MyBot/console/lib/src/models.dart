enum MemoryMode { codexDefault, library, none }

class Library {
  const Library({
    required this.id,
    required this.name,
    required this.workspacePath,
    required this.memoryMode,
  });

  factory Library.fromJson(Map<String, dynamic> json) => Library(
    id: json['id'] as String,
    name: json['name'] as String,
    workspacePath: json['workspacePath'] as String,
    memoryMode: MemoryMode.values.byName(json['memoryMode'] as String),
  );

  final String id;
  final String name;
  final String workspacePath;
  final MemoryMode memoryMode;
}

class Conversation {
  const Conversation({required this.id, required this.title});

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      Conversation(id: json['id'] as String, title: json['title'] as String);

  final String id;
  final String title;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: json['role'] as String,
    content: json['content'] as String,
  );

  final String id;
  final String role;
  final String content;
}

class PromptResult {
  const PromptResult({required this.message, required this.taskState});

  factory PromptResult.fromJson(Map<String, dynamic> json) => PromptResult(
    message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
    taskState: (json['task'] as Map<String, dynamic>)['state'] as String,
  );

  final ChatMessage message;
  final String taskState;
}
