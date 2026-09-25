class GitTrigger {
  const GitTrigger({
    required this.mode,
    required this.includePaths,
    required this.excludePaths,
  });

  final String mode;
  final List<String> includePaths;
  final List<String> excludePaths;

  factory GitTrigger.fromJson(Map<String, dynamic> json) => GitTrigger(
    mode: json['mode'] as String,
    includePaths: List<String>.from(json['includePaths'] as List),
    excludePaths: List<String>.from(json['excludePaths'] as List),
  );

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'includePaths': includePaths,
    'excludePaths': excludePaths,
  };
}

class GitSource {
  const GitSource({
    required this.repositoryUrl,
    required this.branch,
    required this.manifestPath,
    required this.pollIntervalSeconds,
    required this.credentialId,
    required this.trigger,
  });

  final String repositoryUrl;
  final String branch;
  final String manifestPath;
  final int pollIntervalSeconds;
  final String? credentialId;
  final GitTrigger trigger;

  factory GitSource.fromJson(Map<String, dynamic> json) => GitSource(
    repositoryUrl: json['repositoryURL'] as String,
    branch: json['branch'] as String,
    manifestPath: json['manifestPath'] as String,
    pollIntervalSeconds: json['pollIntervalSeconds'] as int,
    credentialId: json['credentialId'] as String?,
    trigger: GitTrigger.fromJson(json['trigger'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'repositoryURL': repositoryUrl,
    'branch': branch,
    'manifestPath': manifestPath,
    'pollIntervalSeconds': pollIntervalSeconds,
    if (credentialId != null && credentialId!.isNotEmpty)
      'credentialId': credentialId,
    'trigger': trigger.toJson(),
  };
}

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.source,
    required this.environmentNames,
    required this.observedCommit,
    required this.currentReleaseId,
    required this.previousReleaseId,
    required this.desiredState,
    required this.runtimeState,
    required this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final GitSource source;
  final List<String> environmentNames;
  final String? observedCommit;
  final String? currentReleaseId;
  final String? previousReleaseId;
  final String desiredState;
  final String runtimeState;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    source: GitSource.fromJson(json['source'] as Map<String, dynamic>),
    environmentNames: List<String>.from(json['environmentNames'] as List),
    observedCommit: json['observedCommit'] as String?,
    currentReleaseId: json['currentReleaseId'] as String?,
    previousReleaseId: json['previousReleaseId'] as String?,
    desiredState: json['desiredState'] as String,
    runtimeState: json['runtimeState'] as String,
    lastError: json['lastError'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class ReleaseRecord {
  const ReleaseRecord({
    required this.id,
    required this.commit,
    required this.status,
    required this.message,
    required this.createdAt,
  });
  final String id;
  final String commit;
  final String status;
  final String? message;
  final DateTime createdAt;

  factory ReleaseRecord.fromJson(Map<String, dynamic> json) => ReleaseRecord(
    id: json['id'] as String,
    commit: json['commit'] as String,
    status: json['status'] as String,
    message: json['message'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class DeploymentRecord {
  const DeploymentRecord({
    required this.action,
    required this.status,
    required this.message,
    required this.startedAt,
  });
  final String action;
  final String status;
  final String? message;
  final DateTime startedAt;

  factory DeploymentRecord.fromJson(Map<String, dynamic> json) =>
      DeploymentRecord(
        action: json['action'] as String,
        status: json['status'] as String,
        message: json['message'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );
}

class ProjectDetails {
  const ProjectDetails({
    required this.project,
    required this.releases,
    required this.deployments,
  });
  final ProjectSummary project;
  final List<ReleaseRecord> releases;
  final List<DeploymentRecord> deployments;

  factory ProjectDetails.fromJson(Map<String, dynamic> json) => ProjectDetails(
    project: ProjectSummary.fromJson(json['project'] as Map<String, dynamic>),
    releases: (json['releases'] as List)
        .map((item) => ReleaseRecord.fromJson(item as Map<String, dynamic>))
        .toList(),
    deployments: (json['deployments'] as List)
        .map((item) => DeploymentRecord.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class GitSourceInspection {
  const GitSourceInspection({
    required this.branches,
    required this.commit,
    required this.manifestExists,
    required this.manifestValid,
    required this.manifest,
    required this.issues,
  });

  final List<String> branches;
  final String commit;
  final bool manifestExists;
  final bool manifestValid;
  final Map<String, dynamic>? manifest;
  final List<Map<String, dynamic>> issues;

  factory GitSourceInspection.fromJson(Map<String, dynamic> json) =>
      GitSourceInspection(
        branches: List<String>.from(json['branches'] as List),
        commit: json['commit'] as String,
        manifestExists: json['manifestExists'] as bool,
        manifestValid: json['manifestValid'] as bool,
        manifest: json['manifest'] as Map<String, dynamic>?,
        issues: (json['issues'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
      );
}
