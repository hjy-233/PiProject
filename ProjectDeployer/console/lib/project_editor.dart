import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';
import 'l10n/generated/app_localizations.dart';
import 'models.dart';

class ProjectEditorResult {
  const ProjectEditorResult({required this.body, required this.syncAfterSave});

  final Map<String, dynamic> body;
  final bool syncAfterSave;
}

class ProjectEditor extends StatefulWidget {
  const ProjectEditor({required this.api, super.key, this.project});

  final ApiClient api;
  final ProjectSummary? project;

  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  late final _id = TextEditingController(text: widget.project?.id);
  late final _name = TextEditingController(text: widget.project?.name);
  late final _repo = TextEditingController(
    text: widget.project?.source.repositoryUrl,
  );
  late final _branch = TextEditingController(
    text: widget.project?.source.branch ?? 'main',
  );
  late final _manifestPath = TextEditingController(
    text: widget.project?.source.manifestPath ?? 'project-deployer.json',
  );
  late final _poll = TextEditingController(
    text: '${widget.project?.source.pollIntervalSeconds ?? 60}',
  );
  late final _include = TextEditingController(
    text: widget.project?.source.trigger.includePaths.join('\n'),
  );
  late final _exclude = TextEditingController(
    text: widget.project?.source.trigger.excludePaths.join('\n'),
  );
  final _dockerfile = TextEditingController(text: 'Dockerfile');
  final _context = TextEditingController(text: '.');
  final _command = TextEditingController();
  final _memory = TextEditingController(text: '256');
  final _cpu = TextEditingController(text: '50');
  final _containerPort = TextEditingController(text: '8080');
  final _hostPort = TextEditingController(text: '18080');
  final _healthPath = TextEditingController(text: '/health');
  final _volumeName = TextEditingController(text: 'data');
  final _volumePath = TextEditingController(text: '/app/data');

  int _step = 0;
  bool _busy = false;
  bool _idWasEdited = false;
  bool _hasPort = true;
  bool _hasVolume = false;
  bool _hasHealthCheck = true;
  bool _volumeReadOnly = false;
  String _mode = 'automatic';
  String _restartPolicy = 'unless-stopped';
  String? _credential;
  String? _error;
  GitSourceInspection? _inspection;
  List<String> _credentials = [];
  final List<_EnvironmentDraft> _environment = [];
  final Map<String, TextEditingController> _environmentValues = {};

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _mode = widget.project?.source.trigger.mode ?? 'automatic';
    _credential = widget.project?.source.credentialId;
    _name.addListener(_updateGeneratedId);
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final credentials = await widget.api.gitCredentials();
      if (mounted) setState(() => _credentials = credentials);
    } catch (_) {
      // Connection testing still reports an actionable credential error.
    }
  }

  void _updateGeneratedId() {
    if (_isEditing || _idWasEdited) return;
    final slug = _name.text
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    _id.value = TextEditingValue(
      text: slug.substring(0, slug.length.clamp(0, 63)),
      selection: TextSelection.collapsed(offset: slug.length.clamp(0, 63)),
    );
  }

  @override
  void dispose() {
    _name.removeListener(_updateGeneratedId);
    for (final controller in [
      _id,
      _name,
      _repo,
      _branch,
      _manifestPath,
      _poll,
      _include,
      _exclude,
      _dockerfile,
      _context,
      _command,
      _memory,
      _cpu,
      _containerPort,
      _hostPort,
      _healthPath,
      _volumeName,
      _volumePath,
      ..._environmentValues.values,
    ]) {
      controller.dispose();
    }
    for (final draft in _environment) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEditing ? strings.editProject : strings.newProject),
      content: SizedBox(
        width: 760,
        height: MediaQuery.sizeOf(context).height.clamp(520, 720),
        child: Column(
          children: [
            _progress(strings),
            const SizedBox(height: 16),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(_error!),
                ),
              ),
            Expanded(child: SingleChildScrollView(child: _page(strings))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        if (_step > 0)
          TextButton(
            onPressed: _busy ? null : _back,
            child: Text(strings.back),
          ),
        if (_step == 4) ...[
          OutlinedButton(
            onPressed: _busy ? null : () => _submit(false),
            child: Text(strings.saveOnly),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : () => _submit(true),
            icon: const Icon(Icons.sync),
            label: Text(strings.saveAndSync),
          ),
        ] else
          FilledButton(
            onPressed: _busy ? null : _continue,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _step == 1 || _step == 2 ? strings.testAgain : strings.next,
                  ),
          ),
      ],
    );
  }

  Widget _progress(AppLocalizations strings) {
    final showManifest = _step == 2 || _inspection?.manifestValid == false;
    final labels = <String>[
      strings.basicInformation,
      strings.gitSource,
      if (showManifest) strings.manifest,
      strings.deploymentPolicy,
      strings.environmentAndReview,
    ];
    final visibleStep = showManifest
        ? _step
        : switch (_step) {
            3 => 2,
            4 => 3,
            _ => _step,
          };
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= visibleStep;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[index], textAlign: TextAlign.center),
            ],
          ),
        );
      }),
    );
  }

  Widget _page(AppLocalizations strings) => switch (_step) {
    0 => _basicPage(strings),
    1 => _gitPage(strings),
    2 => _manifestPage(strings),
    3 => _policyPage(strings),
    _ => _reviewPage(strings),
  };

  Widget _basicPage(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(strings.basicInformationHint),
      const SizedBox(height: 20),
      TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(
          labelText: strings.projectName,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _id,
        enabled: !_isEditing,
        onChanged: (_) => _idWasEdited = true,
        decoration: InputDecoration(
          labelText: strings.projectId,
          helperText: strings.projectIdHint,
          border: const OutlineInputBorder(),
        ),
      ),
    ],
  );

  Widget _gitPage(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(strings.gitSourceHint),
      const SizedBox(height: 20),
      TextField(
        controller: _repo,
        decoration: InputDecoration(
          labelText: strings.repositoryUrl,
          hintText: 'ssh://git@github.com/owner/repository.git',
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _branch,
              decoration: InputDecoration(
                labelText: strings.branch,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _credential,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.credential,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(strings.noCredential),
                ),
                ..._credentials.map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                ),
              ],
              onChanged: (value) => setState(() => _credential = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _manifestPath,
        decoration: InputDecoration(
          labelText: strings.manifestPath,
          helperText: strings.manifestPathHint,
          border: const OutlineInputBorder(),
        ),
      ),
      if (_inspection != null) ...[
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(
            _inspection!.manifestValid ? Icons.check_circle : Icons.warning,
            color: _inspection!.manifestValid ? Colors.green : Colors.orange,
          ),
          title: Text(
            _inspection!.manifestValid
                ? strings.gitAndManifestReady
                : strings.manifestNeedsAttention,
          ),
          subtitle: Text(
            '${_inspection!.branches.length} branches · ${_inspection!.commit.substring(0, 8)}',
          ),
        ),
      ],
    ],
  );

  Widget _manifestPage(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _inspection?.manifestExists == true
            ? strings.manifestInvalidHint
            : strings.manifestMissingHint,
      ),
      const SizedBox(height: 16),
      Text(strings.build, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _field(_dockerfile, strings.dockerfile)),
          const SizedBox(width: 12),
          Expanded(child: _field(_context, strings.buildContext)),
        ],
      ),
      const SizedBox(height: 12),
      _field(_command, strings.command, hint: strings.commandHint, lines: 3),
      const SizedBox(height: 20),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _hasPort,
        onChanged: (value) => setState(() => _hasPort = value),
        title: Text(strings.publishPort),
      ),
      if (_hasPort)
        Row(
          children: [
            Expanded(
              child: _field(
                _containerPort,
                strings.containerPort,
                number: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _field(_hostPort, strings.hostPort, number: true)),
          ],
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _hasVolume,
        onChanged: (value) => setState(() => _hasVolume = value),
        title: Text(strings.persistentVolume),
      ),
      if (_hasVolume) ...[
        Row(
          children: [
            Expanded(child: _field(_volumeName, strings.volumeName)),
            const SizedBox(width: 12),
            Expanded(child: _field(_volumePath, strings.containerPath)),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _volumeReadOnly,
          onChanged: (value) =>
              setState(() => _volumeReadOnly = value ?? false),
          title: Text(strings.readOnly),
        ),
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _hasHealthCheck,
        onChanged: _hasPort
            ? (value) => setState(() => _hasHealthCheck = value)
            : null,
        title: Text(strings.healthCheck),
      ),
      if (_hasHealthCheck && _hasPort) _field(_healthPath, strings.healthPath),
      const SizedBox(height: 12),
      Text(
        strings.environmentDeclarations,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      ..._environment.asMap().entries.map(
        (entry) => _environmentRow(entry.key, entry.value, strings),
      ),
      TextButton.icon(
        onPressed: () => setState(() => _environment.add(_EnvironmentDraft())),
        icon: const Icon(Icons.add),
        label: Text(strings.addEnvironmentVariable),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _field(_memory, strings.memoryMiB, number: true)),
          const SizedBox(width: 12),
          Expanded(child: _field(_cpu, strings.cpuPercent, number: true)),
        ],
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _restartPolicy,
        decoration: InputDecoration(
          labelText: strings.restartPolicy,
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(
            value: 'unless-stopped',
            child: Text('unless-stopped'),
          ),
          DropdownMenuItem(value: 'on-failure', child: Text('on-failure')),
          DropdownMenuItem(value: 'no', child: Text('no')),
        ],
        onChanged: (value) => setState(() => _restartPolicy = value!),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                _manifestJson(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _manifestJson()));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(strings.copied)));
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(strings.copyJson),
                ),
              ),
            ],
          ),
        ),
      ),
      Text(strings.commitManifestHint),
    ],
  );

  Widget _policyPage(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(strings.deploymentPolicyHint),
      const SizedBox(height: 20),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'automatic', label: Text(strings.automatic)),
          ButtonSegment(value: 'manual', label: Text(strings.manual)),
        ],
        selected: {_mode},
        onSelectionChanged: (value) => setState(() => _mode = value.first),
      ),
      const SizedBox(height: 12),
      Text(_mode == 'automatic' ? strings.automaticHint : strings.manualHint),
      const SizedBox(height: 20),
      _field(_poll, strings.pollSeconds, number: true),
      const SizedBox(height: 12),
      _field(_include, strings.includePaths, hint: strings.pathsHint, lines: 4),
      const SizedBox(height: 12),
      _field(_exclude, strings.excludePaths, hint: strings.pathsHint, lines: 4),
    ],
  );

  Widget _reviewPage(AppLocalizations strings) {
    final declarations = _manifestEnvironment();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.environmentValues,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(strings.environmentValuesHint),
        const SizedBox(height: 12),
        if (declarations.isEmpty) Text(strings.noEnvironmentVariables),
        ...declarations.map((item) {
          final name = item['name']! as String;
          final secret = item['secret']! as bool;
          final required = item['required']! as bool;
          final controller = _environmentValues.putIfAbsent(
            name,
            TextEditingController.new,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: controller,
              obscureText: secret,
              decoration: InputDecoration(
                labelText: '$name${required ? ' *' : ''}',
                helperText: secret ? strings.secretValueHint : null,
                border: const OutlineInputBorder(),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(strings.review, style: Theme.of(context).textTheme.titleMedium),
        _reviewLine(strings.projectName, _name.text),
        _reviewLine(strings.projectId, _id.text),
        _reviewLine(strings.repositoryUrl, _repo.text),
        _reviewLine(strings.branch, _branch.text),
        _reviewLine(strings.manifestPath, _manifestPath.text),
        _reviewLine(
          strings.deploymentPolicy,
          _mode == 'automatic' ? strings.automatic : strings.manual,
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int lines = 1,
    bool number = false,
  }) => TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );

  Widget _environmentRow(
    int index,
    _EnvironmentDraft draft,
    AppLocalizations strings,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _field(draft.name, strings.variableName)),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(strings.required),
              Checkbox(
                value: draft.required,
                onChanged: (value) =>
                    setState(() => draft.required = value ?? false),
              ),
            ],
          ),
          Column(
            children: [
              Text(strings.secret),
              Checkbox(
                value: draft.secret,
                onChanged: (value) =>
                    setState(() => draft.secret = value ?? false),
              ),
            ],
          ),
          IconButton(
            onPressed: () => setState(() {
              final removed = _environment.removeAt(index);
              removed.dispose();
            }),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );

  Widget _reviewLine(String label, String value) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
  );

  Future<void> _continue() async {
    setState(() => _error = null);
    if (_step == 0) {
      if (_name.text.trim().isEmpty ||
          !RegExp(
            r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
          ).hasMatch(_id.text.trim())) {
        setState(
          () => _error = AppLocalizations.of(context).invalidBasicInformation,
        );
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1 || _step == 2) {
      await _inspect();
      return;
    }
    if (_step == 3) {
      final poll = int.tryParse(_poll.text);
      if (poll == null || poll < 15 || poll > 3600) {
        setState(
          () => _error = AppLocalizations.of(context).invalidPollInterval,
        );
        return;
      }
      setState(() => _step = 4);
    }
  }

  void _back() {
    setState(() {
      _error = null;
      if (_step == 3 && _inspection?.manifestValid == true) {
        _step = 1;
      } else {
        _step -= 1;
      }
    });
  }

  Future<void> _inspect() async {
    if (_repo.text.trim().isEmpty ||
        _branch.text.trim().isEmpty ||
        _manifestPath.text.trim().isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).completeGitInformation,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final inspection = await widget.api.inspectGitSource(
        _id.text.trim(),
        _source(),
      );
      if (!mounted) return;
      setState(() {
        _inspection = inspection;
        _loadEnvironment(inspection.manifest);
        _step = inspection.manifestValid ? 3 : 2;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _loadEnvironment(Map<String, dynamic>? manifest) {
    if (manifest == null) return;
    final values = (manifest['environment'] as List? ?? const []).map(
      (value) => Map<String, dynamic>.from(value as Map),
    );
    for (final item in values) {
      _environmentValues.putIfAbsent(
        item['name'] as String,
        TextEditingController.new,
      );
    }
  }

  void _submit(bool syncAfterSave) {
    final missing = _manifestEnvironment().where((item) {
      if (item['required'] != true) return false;
      return _environmentValues[item['name']]?.text.isEmpty ?? true;
    });
    if (missing.isNotEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).requiredEnvironmentMissing,
      );
      return;
    }
    final environment = <String, String>{};
    for (final item in _environmentValues.entries) {
      if (item.value.text.isNotEmpty) environment[item.key] = item.value.text;
    }
    Navigator.pop(
      context,
      ProjectEditorResult(
        syncAfterSave: syncAfterSave,
        body: {
          if (!_isEditing) 'id': _id.text.trim(),
          'name': _name.text.trim(),
          'source': _source(),
          if (!_isEditing) 'environment': environment,
        },
      ),
    );
  }

  Map<String, dynamic> _source() => {
    'repositoryURL': _repo.text.trim(),
    'branch': _branch.text.trim(),
    'manifestPath': _manifestPath.text.trim(),
    'pollIntervalSeconds': int.tryParse(_poll.text) ?? 60,
    if (_credential != null) 'credentialId': _credential,
    'trigger': {
      'mode': _mode,
      'includePaths': _lines(_include.text),
      'excludePaths': _lines(_exclude.text),
    },
  };

  List<String> _lines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  List<Map<String, Object>> _manifestEnvironment() {
    final remote = _inspection?.manifest?['environment'] as List?;
    if (remote != null) {
      return remote
          .map((item) => Map<String, Object>.from(item as Map))
          .toList();
    }
    return _environment
        .where((item) => item.name.text.trim().isNotEmpty)
        .map(
          (item) => {
            'name': item.name.text.trim().toUpperCase(),
            'required': item.required,
            'secret': item.secret,
          },
        )
        .toList();
  }

  String _manifestJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'projectId': _id.text.trim(),
    'platform': 'linux/arm64',
    'build': {
      'dockerfile': _dockerfile.text.trim(),
      'context': _context.text.trim(),
    },
    'command': _lines(_command.text),
    'environment': _manifestEnvironment(),
    'ports': _hasPort
        ? [
            {
              'container': int.tryParse(_containerPort.text) ?? 8080,
              'host': int.tryParse(_hostPort.text) ?? 18080,
              'protocol': 'tcp',
            },
          ]
        : <Object>[],
    'volumes': _hasVolume
        ? [
            {
              'name': _volumeName.text.trim(),
              'containerPath': _volumePath.text.trim(),
              'readOnly': _volumeReadOnly,
            },
          ]
        : <Object>[],
    'healthCheck': _hasHealthCheck && _hasPort
        ? {
            'type': 'http',
            'path': _healthPath.text.trim(),
            'port': int.tryParse(_containerPort.text) ?? 8080,
            'timeoutSeconds': 3,
            'startPeriodSeconds': 10,
            'retries': 3,
          }
        : null,
    'resources': {
      'memoryMiB': int.tryParse(_memory.text) ?? 256,
      'cpuPercent': int.tryParse(_cpu.text) ?? 50,
    },
    'restartPolicy': _restartPolicy,
  });
}

class _EnvironmentDraft {
  final name = TextEditingController();
  bool required = true;
  bool secret = true;

  void dispose() => name.dispose();
}
