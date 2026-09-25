// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ProjectDeployer';

  @override
  String get overview => 'Overview';

  @override
  String get projects => 'Projects';

  @override
  String get refresh => 'Refresh';

  @override
  String get newProject => 'New project';

  @override
  String get totalProjects => 'Total projects';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get emptyProjects => 'No projects yet';

  @override
  String get emptyProjectsHint => 'Create your first Git-driven deployment.';

  @override
  String get recentProjects => 'Project status';

  @override
  String get branch => 'Branch';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get details => 'Details';

  @override
  String get deployments => 'Deployments';

  @override
  String get releases => 'Releases';

  @override
  String get logs => 'Logs';

  @override
  String get settings => 'Settings';

  @override
  String get sync => 'Sync now';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get restart => 'Restart';

  @override
  String get rollback => 'Rollback';

  @override
  String get deploy => 'Deploy';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get purgeVolumes => 'Also delete Docker volumes (irreversible)';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get projectId => 'Project ID';

  @override
  String get projectName => 'Project name';

  @override
  String get repositoryUrl => 'Git repository URL';

  @override
  String get credentialId => 'SSH credential ID (optional)';

  @override
  String get pollSeconds => 'Polling interval (seconds)';

  @override
  String get automatic => 'Automatic deployment';

  @override
  String get manual => 'Manual deployment';

  @override
  String get status => 'Status';

  @override
  String get currentCommit => 'Current commit';

  @override
  String get runtimeState => 'Runtime state';

  @override
  String get desiredState => 'Desired state';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get operationSucceeded => 'Operation completed';

  @override
  String get copy => 'Copy';

  @override
  String get noLogs => 'No logs';

  @override
  String get serviceOnline => 'Service online';

  @override
  String get unknown => 'Unknown';

  @override
  String get editProject => 'Edit project';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get saveOnly => 'Save only';

  @override
  String get saveAndSync => 'Save and sync';

  @override
  String get basicInformation => 'Basics';

  @override
  String get gitSource => 'Git source';

  @override
  String get manifest => 'Manifest';

  @override
  String get deploymentPolicy => 'Policy';

  @override
  String get environmentAndReview => 'Variables & review';

  @override
  String get basicInformationHint =>
      'Name the project first. Its generated ID identifies containers, images, and data directories.';

  @override
  String get projectIdHint =>
      'Lowercase letters, numbers, and hyphens; it cannot be changed after creation.';

  @override
  String get gitSourceHint =>
      'Enter the remote repository and test the real connection. ProjectDeployer reads branches and the manifest without creating a project.';

  @override
  String get credential => 'SSH deploy key';

  @override
  String get noCredential => 'No credential (public repository)';

  @override
  String get manifestPath => 'Manifest path';

  @override
  String get manifestPathHint =>
      'Relative to the repository root; defaults to project-deployer.json';

  @override
  String get gitAndManifestReady => 'Git connection and manifest are valid';

  @override
  String get manifestNeedsAttention =>
      'Git connected, but the manifest needs attention';

  @override
  String get manifestMissingHint =>
      'The target branch has no manifest. Complete the runtime form, copy the JSON, commit and push it, then test again.';

  @override
  String get manifestInvalidHint =>
      'The repository manifest is invalid or belongs to another project. Use the generated JSON as a guide, commit and push the fix, then test again.';

  @override
  String get build => 'Docker build';

  @override
  String get dockerfile => 'Dockerfile path';

  @override
  String get buildContext => 'Build context';

  @override
  String get command => 'Container command';

  @override
  String get commandHint =>
      'One argument per line, for example /app/server on the first line';

  @override
  String get publishPort => 'Publish a container port';

  @override
  String get containerPort => 'Container port';

  @override
  String get hostPort => 'Raspberry Pi port';

  @override
  String get persistentVolume => 'Use a persistent volume';

  @override
  String get volumeName => 'Volume name';

  @override
  String get containerPath => 'Container path';

  @override
  String get readOnly => 'Read only';

  @override
  String get healthCheck => 'Enable HTTP health check';

  @override
  String get healthPath => 'Health-check path';

  @override
  String get environmentDeclarations => 'Environment declarations';

  @override
  String get addEnvironmentVariable => 'Add environment variable';

  @override
  String get variableName => 'Variable name';

  @override
  String get required => 'Required';

  @override
  String get secret => 'Secret';

  @override
  String get memoryMiB => 'Memory limit (MiB)';

  @override
  String get cpuPercent => 'CPU limit (%)';

  @override
  String get restartPolicy => 'Restart policy';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get copied => 'Copied';

  @override
  String get commitManifestHint =>
      'Save the JSON at the manifest path above, commit and push it, then select Test again.';

  @override
  String get testAgain => 'Test connection and inspect';

  @override
  String get deploymentPolicyHint =>
      'Choose when new commits deploy, with optional changed-path filters.';

  @override
  String get automaticHint =>
      'Matching new commits are built and switched into service automatically.';

  @override
  String get manualHint =>
      'New commits only create ready releases; deploy them manually from the console.';

  @override
  String get includePaths => 'Included paths';

  @override
  String get excludePaths => 'Excluded paths';

  @override
  String get pathsHint => 'One path or glob per line, for example service/**';

  @override
  String get environmentValues => 'Environment values';

  @override
  String get environmentValuesHint =>
      'Variables come from the repository manifest. Secret values stay in the Pi database and are not returned by list APIs.';

  @override
  String get noEnvironmentVariables =>
      'The manifest declares no environment variables.';

  @override
  String get secretValueHint => 'The secret value is obscured';

  @override
  String get review => 'Review before creation';

  @override
  String get invalidBasicInformation =>
      'Enter a name and a valid lowercase project ID.';

  @override
  String get invalidPollInterval =>
      'The polling interval must be between 15 and 3600 seconds.';

  @override
  String get completeGitInformation =>
      'Complete the repository, branch, and manifest path.';

  @override
  String get requiredEnvironmentMissing =>
      'Complete all required environment variables.';
}
