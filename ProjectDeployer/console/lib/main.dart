import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'api_client.dart';
import 'l10n/generated/app_localizations.dart';
import 'models.dart';
import 'project_editor.dart';

void main() => runApp(const ProjectDeployerApp());

class ProjectDeployerApp extends StatelessWidget {
  const ProjectDeployerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3978F6)),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF76A3FF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const ConsolePage(),
  );
}

class ConsolePage extends StatefulWidget {
  const ConsolePage({super.key});
  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  final _api = ApiClient();
  List<ProjectSummary> _projects = [];
  ProjectDetails? _details;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  int _page = 0;
  int _tab = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final projects = await _api.projects();
      ProjectDetails? details;
      if (_details != null &&
          projects.any((item) => item.id == _details!.project.id)) {
        details = await _api.details(_details!.project.id);
      }
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _details = details;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _select(ProjectSummary project) async {
    setState(() {
      _page = 1;
      _loading = true;
    });
    try {
      final details = await _api.details(project.id);
      if (mounted) {
        setState(() {
          _details = details;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(String action) async {
    final project = _details?.project;
    if (project == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _api.action(project.id, action);
      await _select(project);
      if (!mounted) return;
      _message(AppLocalizations.of(context).operationSucceeded);
    } catch (error) {
      if (!mounted) return;
      _message('$error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deploy(String releaseId) async {
    final project = _details?.project;
    if (project == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _api.deploy(project.id, releaseId);
      await _select(project);
      if (!mounted) return;
      _message(AppLocalizations.of(context).operationSucceeded);
    } catch (error) {
      if (!mounted) return;
      _message('$error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: Text(_details?.project.name ?? strings.appTitle),
              actions: [
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              extended: true,
              minExtendedWidth: 220,
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              leading: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.appTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(strings.overview),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: Text(strings.projects),
                ),
              ],
            ),
          Expanded(
            child: Column(
              children: [
                if (wide) _topBar(),
                Expanded(child: _content()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  label: strings.overview,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: strings.projects,
                ),
              ],
            ),
    );
  }

  Widget _topBar() => Material(
    elevation: 1,
    child: SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _page == 0
                    ? AppLocalizations.of(context).overview
                    : (_details?.project.name ??
                          AppLocalizations.of(context).projects),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (_page == 1 && _details != null) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _action('restart'),
                icon: const Icon(Icons.restart_alt),
                label: Text(AppLocalizations.of(context).restart),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy ? null : () => _action('sync'),
                icon: const Icon(Icons.sync),
                label: Text(AppLocalizations.of(context).sync),
              ),
            ],
            IconButton(
              onPressed: _load,
              tooltip: AppLocalizations.of(context).refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content() {
    if (_loading && _projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            FilledButton(
              onPressed: _load,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }
    return _page == 0 ? _overview() : _projectsPage();
  }

  Widget _overview() {
    final strings = AppLocalizations.of(context);
    final running = _projects
        .where((item) => item.runtimeState == 'running')
        .length;
    final stopped = _projects
        .where((item) => item.runtimeState == 'stopped')
        .length;
    final failed = _projects
        .where(
          (item) => item.runtimeState == 'failed' || item.lastError != null,
        )
        .length;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metric(
              strings.totalProjects,
              _projects.length,
              Icons.inventory_2_outlined,
            ),
            _metric(
              strings.running,
              running,
              Icons.play_circle_outline,
              Colors.green,
            ),
            _metric(
              strings.stopped,
              stopped,
              Icons.stop_circle_outlined,
              Colors.orange,
            ),
            _metric(
              strings.needsAttention,
              failed,
              Icons.error_outline,
              Theme.of(context).colorScheme.error,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.recentProjects,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: _editProject,
              icon: const Icon(Icons.add),
              label: Text(strings.newProject),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_projects.isEmpty)
          _empty()
        else
          Card(child: Column(children: _projects.map(_projectTile).toList())),
      ],
    );
  }

  Widget _metric(String label, int value, IconData icon, [Color? color]) =>
      SizedBox(
        width: 210,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(label),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _empty() => Card(
    child: Padding(
      padding: const EdgeInsets.all(42),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.rocket_launch_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).emptyProjects,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(AppLocalizations.of(context).emptyProjectsHint),
          ],
        ),
      ),
    ),
  );

  Widget _projectTile(ProjectSummary project) => ListTile(
    onTap: () => _select(project),
    leading: _statusIcon(
      project.lastError == null ? project.runtimeState : 'failed',
    ),
    title: Text(project.name),
    subtitle: Text(
      '${project.source.branch} · ${_short(project.observedCommit)}',
    ),
    trailing: const Icon(Icons.chevron_right),
  );

  Widget _projectsPage() {
    final details = _details;
    if (details == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).projects,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _editProject,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).newProject),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_projects.isEmpty)
            _empty()
          else
            Card(child: Column(children: _projects.map(_projectTile).toList())),
        ],
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Row(
      children: [
        if (MediaQuery.sizeOf(context).width >= 760)
          SizedBox(
            width: 280,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ListView(
                children: _projects
                    .map(
                      (project) => ListTile(
                        selected: project.id == details.project.id,
                        onTap: () => _select(project),
                        leading: _statusIcon(project.runtimeState),
                        title: Text(project.name),
                        subtitle: Text(project.source.branch),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        Expanded(child: _projectDetails(details)),
      ],
    );
  }

  Widget _projectDetails(ProjectDetails details) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      if (details.project.lastError != null)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(details.project.lastError!),
          ),
        ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _action('start'),
            icon: const Icon(Icons.play_arrow),
            label: Text(AppLocalizations.of(context).start),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _action('stop'),
            icon: const Icon(Icons.stop),
            label: Text(AppLocalizations.of(context).stop),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _action('restart'),
            icon: const Icon(Icons.restart_alt),
            label: Text(AppLocalizations.of(context).restart),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _action('rollback'),
            icon: const Icon(Icons.undo),
            label: Text(AppLocalizations.of(context).rollback),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : () => _action('sync'),
            icon: const Icon(Icons.sync),
            label: Text(AppLocalizations.of(context).sync),
          ),
        ],
      ),
      const SizedBox(height: 18),
      SegmentedButton<int>(
        segments: [
          ButtonSegment(
            value: 0,
            icon: const Icon(Icons.info_outline),
            label: Text(AppLocalizations.of(context).details),
          ),
          ButtonSegment(
            value: 1,
            icon: const Icon(Icons.timeline),
            label: Text(AppLocalizations.of(context).deployments),
          ),
          ButtonSegment(
            value: 2,
            icon: const Icon(Icons.terminal),
            label: Text(AppLocalizations.of(context).logs),
          ),
          ButtonSegment(
            value: 3,
            icon: const Icon(Icons.settings_outlined),
            label: Text(AppLocalizations.of(context).settings),
          ),
        ],
        selected: {_tab},
        showSelectedIcon: false,
        onSelectionChanged: (value) => setState(() => _tab = value.first),
      ),
      const SizedBox(height: 18),
      switch (_tab) {
        0 => _detailOverview(details),
        1 => _history(details),
        2 => _logs(details.project),
        _ => _settings(details.project),
      },
    ],
  );

  Widget _detailOverview(ProjectDetails details) => Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      SizedBox(
        width: 440,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).status,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _info(
                  AppLocalizations.of(context).runtimeState,
                  details.project.runtimeState,
                ),
                _info(
                  AppLocalizations.of(context).desiredState,
                  details.project.desiredState,
                ),
                _info(
                  AppLocalizations.of(context).currentCommit,
                  _short(details.project.observedCommit),
                ),
                _info(
                  AppLocalizations.of(context).branch,
                  details.project.source.branch,
                ),
                _info(
                  AppLocalizations.of(context).lastUpdated,
                  DateFormat.yMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).add_Hm().format(details.project.updatedAt.toLocal()),
                ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(
        width: 440,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).releases,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...details.releases
                    .take(5)
                    .map(
                      (release) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _statusIcon(release.status),
                        title: Text(_short(release.commit)),
                        subtitle: Text(release.status),
                        trailing: release.status == 'ready'
                            ? TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _deploy(release.id),
                                child: Text(
                                  AppLocalizations.of(context).deploy,
                                ),
                              )
                            : null,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _history(ProjectDetails details) => Card(
    child: Column(
      children: details.deployments
          .map(
            (item) => ListTile(
              leading: _statusIcon(item.status),
              title: Text('${item.action} · ${item.status}'),
              subtitle: Text(
                item.message ??
                    DateFormat.yMd().add_Hm().format(item.startedAt.toLocal()),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _logs(ProjectSummary project) => FutureBuilder<String>(
    future: _api.logs(project.id),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final output =
          snapshot.data ??
          snapshot.error?.toString() ??
          AppLocalizations.of(context).noLogs;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: output)),
                tooltip: AppLocalizations.of(context).copy,
                icon: const Icon(Icons.copy),
              ),
              SelectableText(
                output,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _settings(ProjectSummary project) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info(
            AppLocalizations.of(context).repositoryUrl,
            project.source.repositoryUrl,
          ),
          _info(
            AppLocalizations.of(context).credentialId,
            project.source.credentialId ?? '—',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _editProject(project),
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.of(context).edit),
              ),
              TextButton.icon(
                onPressed: () => _deleteProject(project),
                icon: const Icon(Icons.delete_outline),
                label: Text(AppLocalizations.of(context).delete),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );

  Future<void> _editProject([ProjectSummary? project]) async {
    final value = await showDialog<ProjectEditorResult>(
      context: context,
      builder: (_) => ProjectEditor(api: _api, project: project),
    );
    if (value == null) return;
    try {
      final saved = project == null
          ? await _api.create(value.body)
          : await _api.update(project.id, value.body);
      if (value.syncAfterSave) await _api.action(saved.id, 'sync');
      await _load();
      await _select(saved);
    } catch (error) {
      _message('$error', isError: true);
    }
  }

  Future<void> _deleteProject(ProjectSummary project) async {
    var purge = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(AppLocalizations.of(context).deleteProject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(project.name),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: purge,
                onChanged: (value) => update(() => purge = value ?? false),
                title: Text(AppLocalizations.of(context).purgeVolumes),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).confirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete(project.id, purgeVolumes: purge);
      setState(() {
        _details = null;
        _page = 0;
      });
      await _load();
    } catch (error) {
      _message('$error', isError: true);
    }
  }

  Widget _statusIcon(String status) => Icon(
    switch (status) {
      'running' || 'succeeded' => Icons.check_circle,
      'failed' => Icons.error,
      'stopped' => Icons.stop_circle,
      'ready' => Icons.inventory_2,
      _ => Icons.circle_outlined,
    },
    color: switch (status) {
      'running' || 'succeeded' => Colors.green,
      'failed' => Theme.of(context).colorScheme.error,
      'stopped' => Colors.orange,
      _ => Colors.blue,
    },
  );
  String _short(String? value) =>
      value == null ? '—' : value.substring(0, value.length.clamp(0, 8));
}
