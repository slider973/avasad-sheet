import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_report.dart';
import '../repositories/expense_repository.dart';

/// Use case pour générer un rapport mensuel de frais
class GetMonthlyReportUseCase {
  final ExpenseRepository repository;

  GetMonthlyReportUseCase({required this.repository});

  Future<Either<Failure, ExpenseReport>> execute(int month, int year) {
    return repository.getMonthlyReport(month, year);
  }
}
