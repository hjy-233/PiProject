import 'package:flutter/material.dart';
import 'package:mybot_console/l10n/app_localizations.dart';
import 'package:mybot_console/src/api_client.dart';
import 'package:mybot_console/src/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  final _messageController = TextEditingController();
  List<Library> _libraries = [];
  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  Library? _selectedLibrary;
  Conversation? _selectedConversation;
  String? _taskState;
  bool _loading = true;
  bool _sending = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadLibraries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final libraries = await _api.libraries();
      if (!mounted) return;
      setState(() {
        _libraries = libraries;
        _loading = false;
      });
      if (libraries.isNotEmpty) await _selectLibrary(libraries.first);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _selectLibrary(Library library) async {
    setState(() {
      _selectedLibrary = library;
      _selectedConversation = null;
      _conversations = [];
      _messages = [];
      _taskState = null;
    });
    try {
      final conversations = await _api.conversations(library.id);
      if (!mounted || _selectedLibrary?.id != library.id) return;
      setState(() => _conversations = conversations);
      if (conversations.isNotEmpty) {
        await _selectConversation(conversations.first);
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _selectConversation(Conversation conversation) async {
    setState(() {
      _selectedConversation = conversation;
      _messages = [];
      _taskState = null;
    });
    try {
      final messages = await _api.messages(conversation.id);
      final taskState = await _api.latestTaskState(conversation.id);
      if (!mounted || _selectedConversation?.id != conversation.id) return;
      setState(() {
        _messages = messages;
        _taskState = taskState;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createLibrary() async {
    final input = await showDialog<_LibraryInput>(
      context: context,
      builder: (context) => const _NewLibraryDialog(),
    );
    if (input == null) return;
    try {
      final library = await _api.createLibrary(
        name: input.name,
        workspacePath: input.workspacePath,
        memoryMode: input.memoryMode,
      );
      if (!mounted) return;
      setState(() => _libraries = [..._libraries, library]);
      await _selectLibrary(library);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createConversation() async {
    final library = _selectedLibrary;
    if (library == null) return;
    final title = await showDialog<String>(
      context: context,
      builder: (context) => const _NewConversationDialog(),
    );
    if (title == null) return;
    try {
      final conversation = await _api.createConversation(library.id, title);
      if (!mounted) return;
      setState(() => _conversations = [conversation, ..._conversations]);
      await _selectConversation(conversation);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _sendMessage() async {
    final conversation = _selectedConversation;
    final content = _messageController.text.trim();
    if (conversation == null || content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final result = await _api.sendMessage(conversation.id, content);
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messages = [..._messages, result.message];
        _taskState = result.taskState;
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          const Icon(Icons.circle, size: 9, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Text(strings.offline),
          const SizedBox(width: 20),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadLibraries)
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) return _buildCompact(strings);
                return Row(
                  children: [
                    SizedBox(width: 250, child: _buildLibraries(strings)),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 280, child: _buildConversations(strings)),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildChat(strings)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCompact(AppLocalizations strings) => Column(
    children: [
      Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showPicker(_buildLibraries(strings)),
                icon: const Icon(Icons.folder_outlined),
                label: Text(_selectedLibrary?.name ?? strings.libraries),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _selectedLibrary == null
                    ? null
                    : () => _showPicker(_buildConversations(strings)),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  _selectedConversation?.title ?? strings.newConversation,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(child: _buildChat(strings)),
    ],
  );

  Future<void> _showPicker(Widget child) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SizedBox(height: 520, child: child),
  );

  Widget _buildLibraries(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PanelHeader(
        title: strings.libraries,
        icon: Icons.add,
        onPressed: _createLibrary,
      ),
      ListTile(
        leading: const Icon(Icons.bolt_outlined),
        title: Text(strings.temporary),
        subtitle: Text(strings.temporaryUnavailable, maxLines: 2),
        enabled: false,
      ),
      const Divider(),
      Expanded(
        child: _libraries.isEmpty
            ? _EmptyPanel(
                title: strings.noLibraries,
                detail: strings.noLibrariesHint,
              )
            : ListView.builder(
                itemCount: _libraries.length,
                itemBuilder: (context, index) {
                  final library = _libraries[index];
                  return ListTile(
                    selected: library.id == _selectedLibrary?.id,
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(library.name),
                    subtitle: Text(
                      library.workspacePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.maybePop(context);
                      _selectLibrary(library);
                    },
                  );
                },
              ),
      ),
    ],
  );

  Widget _buildConversations(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PanelHeader(
        title: _selectedLibrary?.name ?? strings.libraries,
        icon: Icons.add_comment_outlined,
        onPressed: _selectedLibrary == null ? null : _createConversation,
      ),
      Expanded(
        child: _conversations.isEmpty
            ? _EmptyPanel(title: strings.noConversation)
            : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return ListTile(
                    selected: conversation.id == _selectedConversation?.id,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(conversation.title),
                    onTap: () {
                      Navigator.maybePop(context);
                      _selectConversation(conversation);
                    },
                  );
                },
              ),
      ),
    ],
  );

  Widget _buildChat(AppLocalizations strings) {
    final conversation = _selectedConversation;
    if (conversation == null) return _EmptyPanel(title: strings.noConversation);
    return Column(
      children: [
        ListTile(
          title: Text(
            conversation.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: _selectedLibrary == null
              ? null
              : Text(_selectedLibrary!.workspacePath),
        ),
        const Divider(height: 1),
        Expanded(
          child: _messages.isEmpty
              ? _EmptyPanel(title: strings.noMessages)
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: _messages[index]),
                ),
        ),
        if (_taskState == 'queued')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Text(strings.queued),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 6,
                  decoration: InputDecoration(hintText: strings.messageHint),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: strings.send,
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(onPressed: onPressed, icon: Icon(icon)),
      ],
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(detail!, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          Text(error.toString()),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(strings.retry)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: isUser ? Theme.of(context).colorScheme.primaryContainer : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(message.content),
          ),
        ),
      ),
    );
  }
}

class _LibraryInput {
  const _LibraryInput({
    required this.name,
    required this.workspacePath,
    required this.memoryMode,
  });

  final String name;
  final String workspacePath;
  final MemoryMode memoryMode;
}

class _NewLibraryDialog extends StatefulWidget {
  const _NewLibraryDialog();

  @override
  State<_NewLibraryDialog> createState() => _NewLibraryDialogState();
}

class _NewLibraryDialogState extends State<_NewLibraryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _path = TextEditingController();
  MemoryMode _memoryMode = MemoryMode.codexDefault;

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(strings.newLibrary),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: strings.libraryName),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.required
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _path,
                decoration: InputDecoration(labelText: strings.workspacePath),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.required
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemoryMode>(
                initialValue: _memoryMode,
                decoration: InputDecoration(labelText: strings.memoryMode),
                items: MemoryMode.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(switch (mode) {
                          MemoryMode.codexDefault => strings.codexDefault,
                          MemoryMode.library => strings.libraryMemory,
                          MemoryMode.none => strings.noMemory,
                        }),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _memoryMode = value ?? _memoryMode),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              _LibraryInput(
                name: _name.text.trim(),
                workspacePath: _path.text.trim(),
                memoryMode: _memoryMode,
              ),
            );
          },
          child: Text(strings.create),
        ),
      ],
    );
  }
}

class _NewConversationDialog extends StatefulWidget {
  const _NewConversationDialog();

  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(strings.newConversation),
      content: TextField(
        controller: _title,
        autofocus: true,
        decoration: InputDecoration(labelText: strings.conversationTitle),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _title.text.trim()),
          child: Text(strings.create),
        ),
      ],
    );
  }
}
