class Signal {
  final String location;
  final String signalType;
  final String urgencyHint;
  final String rawText;
  final String source;
  final String reasoning;

  Signal({
    required this.location,
    required this.signalType,
    required this.urgencyHint,
    required this.rawText,
    required this.source,
    required this.reasoning,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      location: json['location']?.toString() ?? '',
      signalType: json['signal_type']?.toString() ?? '',
      urgencyHint: json['urgency_hint']?.toString() ?? '',
      rawText: json['raw_text']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      reasoning: json['reasoning']?.toString() ?? '',
    );
  }
}

class CrisisEvent {
  final String location;
  final String crisisType;
  final String severity;
  final double confidence;
  final String situationSummary;
  final String affectedPopulation;
  final List<String> reasoningSteps;

  CrisisEvent({
    required this.location,
    required this.crisisType,
    required this.severity,
    required this.confidence,
    required this.situationSummary,
    required this.affectedPopulation,
    required this.reasoningSteps,
  });

  factory CrisisEvent.fromJson(Map<String, dynamic> json) {
    // confidence might be parsed as int or double or string in json
    double parsedConfidence = 0.0;
    if (json['confidence'] != null) {
      if (json['confidence'] is num) {
        parsedConfidence = (json['confidence'] as num).toDouble();
      } else {
        parsedConfidence = double.tryParse(json['confidence'].toString()) ?? 0.0;
      }
    }

    return CrisisEvent(
      location: json['location']?.toString() ?? '',
      crisisType: json['crisis_type']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      confidence: parsedConfidence,
      situationSummary: json['situation_summary']?.toString() ?? '',
      affectedPopulation: json['affected_population']?.toString() ?? '',
      reasoningSteps: List<String>.from(json['reasoning_steps'] ?? []),
    );
  }
}

class ActionItem {
  final String id;
  final String title;
  final String resource;
  final String priority;
  final String description;

  ActionItem({
    required this.id,
    required this.title,
    required this.resource,
    required this.priority,
    required this.description,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      resource: json['resource_assignment']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class ExecutedAction {
  final String actionId;
  final String actionName;
  final String executionStatus;
  final String timestamp;
  final String beforeState;
  final String afterState;

  ExecutedAction({
    required this.actionId,
    required this.actionName,
    required this.executionStatus,
    required this.timestamp,
    required this.beforeState,
    required this.afterState,
  });

  factory ExecutedAction.fromJson(Map<String, dynamic> json) {
    return ExecutedAction(
      actionId: json['action_id']?.toString() ?? '',
      actionName: json['action_name']?.toString() ?? '',
      executionStatus: json['execution_status']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      beforeState: json['before_state']?.toString() ?? '',
      afterState: json['after_state']?.toString() ?? '',
    );
  }
}

class PipelineResult {
  final List<Signal> signals;
  final CrisisEvent? crisisEvent;
  final List<ActionItem> actions;
  final List<ExecutedAction> executedActions;
  final List<String> auditLog;
  final Map<String, dynamic> systemStateBefore;
  final Map<String, dynamic> systemStateAfter;

  PipelineResult({
    required this.signals,
    this.crisisEvent,
    required this.actions,
    required this.executedActions,
    required this.auditLog,
    required this.systemStateBefore,
    required this.systemStateAfter,
  });

  static PipelineResult fromApiResponse(Map<String, dynamic> json) {
    final pipelineData = json['pipeline_results'] ?? {};
    
    // Parse Signals
    final collectorData = pipelineData['signal_collector'] ?? {};
    final signalsList = (collectorData['signals'] as List<dynamic>?) ?? [];
    final signals = signalsList.map((e) => Signal.fromJson(e)).toList();

    // Parse Crisis Event
    final detectorData = pipelineData['crisis_detector'] ?? {};
    final crisisJson = detectorData['crisis_event'] ?? {};
    CrisisEvent? crisis;
    if (crisisJson.isNotEmpty && !crisisJson.containsKey('error')) {
      crisis = CrisisEvent.fromJson(crisisJson);
    }

    // Parse Actions
    final plannerData = pipelineData['response_planner'] ?? {};
    final planJson = plannerData['response_plan'] ?? {};
    final actionsList = (planJson['actions'] as List<dynamic>?) ?? [];
    final actions = actionsList.map((e) => ActionItem.fromJson(e)).toList();

    // Parse Executed Actions & Audit Log
    final executorData = pipelineData['action_executor'] ?? {};
    final report = executorData['execution_report'] ?? {};
    
    final executedList = (report['executed_actions'] as List<dynamic>?) ?? [];
    final executedActions = executedList.map((e) => ExecutedAction.fromJson(e)).toList();

    return PipelineResult(
      signals: signals,
      crisisEvent: crisis,
      actions: actions,
      executedActions: executedActions,
      auditLog: List<String>.from(report['audit_log'] ?? []),
      systemStateBefore: Map<String, dynamic>.from(report['system_state_before'] ?? {}),
      systemStateAfter: Map<String, dynamic>.from(report['system_state_after'] ?? {}),
    );
  }
}
