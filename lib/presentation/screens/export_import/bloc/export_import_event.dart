import 'package:equatable/equatable.dart';

abstract class ExportImportEvent extends Equatable {
  const ExportImportEvent();

  @override
  List<Object?> get props => [];
}

class ExportImportLoadRequested extends ExportImportEvent {
  final int month;
  final int year;

  const ExportImportLoadRequested({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class ExportImportExportPdf extends ExportImportEvent {
  final int month;
  final int year;

  const ExportImportExportPdf({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class ExportImportExportExcel extends ExportImportEvent {
  final int month;
  final int year;

  const ExportImportExportExcel({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}
