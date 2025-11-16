import 'package:equatable/equatable.dart';

class DateRange extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class PaymentReportData extends Equatable {
  final double totalIncome;
  final double completePayments;
  final double partialPayments;
  final int debtorCount;
  final Map<String, double> monthlyIncome;
  final List<DebtorDetail> debtors;
  final List<PaymentDetail> payments;

  const PaymentReportData({
    required this.totalIncome,
    required this.completePayments,
    required this.partialPayments,
    required this.debtorCount,
    required this.monthlyIncome,
    required this.debtors,
    required this.payments,
  });

  @override
  List<Object?> get props => [
    totalIncome,
    completePayments,
    partialPayments,
    debtorCount,
    monthlyIncome,
    debtors,
    payments,
  ];
}

class DebtorDetail extends Equatable {
  final int asesoradoId;
  final String asesoradoName;
  final double debtAmount;
  final DateTime lastPaymentDate;

  const DebtorDetail({
    required this.asesoradoId,
    required this.asesoradoName,
    required this.debtAmount,
    required this.lastPaymentDate,
  });

  @override
  List<Object?> get props => [
    asesoradoId,
    asesoradoName,
    debtAmount,
    lastPaymentDate,
  ];
}

class PaymentDetail extends Equatable {
  final int id;
  final String asesoradoName;
  final DateTime paymentDate;
  final double amount;
  final String type;
  final String period;

  const PaymentDetail({
    required this.id,
    required this.asesoradoName,
    required this.paymentDate,
    required this.amount,
    required this.type,
    required this.period,
  });

  @override
  List<Object?> get props => [
    id,
    asesoradoName,
    paymentDate,
    amount,
    type,
    period,
  ];
}

class RoutineReportData extends Equatable {
  final List<RoutineUsage> mostUsedRoutines;
  final Map<String, int> exerciseCompletion;
  final Map<String, double> adherenceByAsesorado;
  final List<RoutineProgress> routineProgress;

  const RoutineReportData({
    required this.mostUsedRoutines,
    required this.exerciseCompletion,
    required this.adherenceByAsesorado,
    required this.routineProgress,
  });

  @override
  List<Object?> get props => [
    mostUsedRoutines,
    exerciseCompletion,
    adherenceByAsesorado,
    routineProgress,
  ];
}

class RoutineUsage extends Equatable {
  final int routineId;
  final String routineName;
  final String category;
  final int usageCount;
  final int assignedCount;

  const RoutineUsage({
    required this.routineId,
    required this.routineName,
    required this.category,
    required this.usageCount,
    required this.assignedCount,
  });

  @override
  List<Object?> get props => [
    routineId,
    routineName,
    category,
    usageCount,
    assignedCount,
  ];
}

class RoutineProgress extends Equatable {
  final String asesoradoName;
  final String routineName;
  final int seriesCompleted;
  final int seriesAssigned;
  final double completionPercentage;

  const RoutineProgress({
    required this.asesoradoName,
    required this.routineName,
    required this.seriesCompleted,
    required this.seriesAssigned,
    required this.completionPercentage,
  });

  @override
  List<Object?> get props => [
    asesoradoName,
    routineName,
    seriesCompleted,
    seriesAssigned,
    completionPercentage,
  ];
}

class MetricsReportData extends Equatable {
  final List<MetricsEvolution> evolution;
  final List<MetricsSummary> summaryByAsesorado;
  final List<MetricsChange> significantChanges;

  const MetricsReportData({
    required this.evolution,
    required this.summaryByAsesorado,
    required this.significantChanges,
  });

  @override
  List<Object?> get props => [
    evolution,
    summaryByAsesorado,
    significantChanges,
  ];
}

class MetricsEvolution extends Equatable {
  final String asesoradoName;
  final DateTime measurementDate;
  final double? weight;
  final double? fatPercentage;
  final double? imc;
  final double? muscleMass;

  const MetricsEvolution({
    required this.asesoradoName,
    required this.measurementDate,
    this.weight,
    this.fatPercentage,
    this.imc,
    this.muscleMass,
  });

  @override
  List<Object?> get props => [
    asesoradoName,
    measurementDate,
    weight,
    fatPercentage,
    imc,
    muscleMass,
  ];
}

class MetricsSummary extends Equatable {
  final String asesoradoName;
  final double? initialWeight;
  final double? currentWeight;
  final double? weightChange;
  final double? initialFat;
  final double? currentFat;
  final double? fatChange;
  final int measurementCount;

  const MetricsSummary({
    required this.asesoradoName,
    this.initialWeight,
    this.currentWeight,
    this.weightChange,
    this.initialFat,
    this.currentFat,
    this.fatChange,
    required this.measurementCount,
  });

  @override
  List<Object?> get props => [
    asesoradoName,
    initialWeight,
    currentWeight,
    weightChange,
    initialFat,
    currentFat,
    fatChange,
    measurementCount,
  ];
}

class MetricsChange extends Equatable {
  final String asesoradoName;
  final String metric;
  final double change;
  final double changePercentage;
  final DateTime startDate;
  final DateTime endDate;

  const MetricsChange({
    required this.asesoradoName,
    required this.metric,
    required this.change,
    required this.changePercentage,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
    asesoradoName,
    metric,
    change,
    changePercentage,
    startDate,
    endDate,
  ];
}

class BitacoraReportData extends Equatable {
  final int totalNotes;
  final int priorityNotes;
  final List<NoteEntry> notesByPeriod;
  final Map<String, int> notesByAsesorado;
  final List<ObjectiveTracking> objectiveTracking;

  const BitacoraReportData({
    required this.totalNotes,
    required this.priorityNotes,
    required this.notesByPeriod,
    required this.notesByAsesorado,
    required this.objectiveTracking,
  });

  @override
  List<Object?> get props => [
    totalNotes,
    priorityNotes,
    notesByPeriod,
    notesByAsesorado,
    objectiveTracking,
  ];
}

class NoteEntry extends Equatable {
  final int id;
  final String asesoradoName;
  final String content;
  final DateTime createdAt;
  final bool isPriority;

  const NoteEntry({
    required this.id,
    required this.asesoradoName,
    required this.content,
    required this.createdAt,
    required this.isPriority,
  });

  @override
  List<Object?> get props => [
    id,
    asesoradoName,
    content,
    createdAt,
    isPriority,
  ];
}

class ObjectiveTracking extends Equatable {
  final String asesoradoName;
  final String objective;
  final int notesCount;
  final DateTime firstNote;
  final DateTime lastNote;

  const ObjectiveTracking({
    required this.asesoradoName,
    required this.objective,
    required this.notesCount,
    required this.firstNote,
    required this.lastNote,
  });

  @override
  List<Object?> get props => [
    asesoradoName,
    objective,
    notesCount,
    firstNote,
    lastNote,
  ];
}

class ConsolidatedReportData extends Equatable {
  final PaymentReportData paymentData;
  final RoutineReportData routineData;
  final MetricsReportData metricsData;
  final BitacoraReportData bitacoraData;
  final DateTime generatedAt;

  const ConsolidatedReportData({
    required this.paymentData,
    required this.routineData,
    required this.metricsData,
    required this.bitacoraData,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
    paymentData,
    routineData,
    metricsData,
    bitacoraData,
    generatedAt,
  ];
}
