import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class ReportLoadRequested extends ReportEvent {
  final int month;
  final int year;

  const ReportLoadRequested({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class ReportChangeMonth extends ReportEvent {
  final int month;
  final int year;

  const ReportChangeMonth({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}
