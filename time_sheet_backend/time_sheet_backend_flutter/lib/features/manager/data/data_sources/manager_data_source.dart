/// Interface du data source pour l'espace manager.
///
/// Retourne des lignes brutes (maps SQL) ; le mapping vers les entités du
/// domaine est fait par le repository.
abstract class ManagerDataSource {
  /// Membres de l'équipe du manager courant (profiles).
  Future<List<Map<String, dynamic>>> getTeamEmployees();

  /// Entrée de pointage du jour pour un employé, ou null.
  Future<Map<String, dynamic>?> getTodayEntry(String employeeId, String today);

  /// Absence en cours pour un employé à la date donnée, ou null.
  Future<Map<String, dynamic>?> getCurrentAbsence(
      String employeeId, String today);

  /// Nombre de validations en attente pour le manager courant.
  Future<int> countPendingValidations();

  /// Nombre de notes de frais en attente pour l'équipe.
  Future<int> countPendingExpenses();

  /// Nombre d'anomalies non résolues dans l'équipe.
  Future<int> countUnresolvedAnomalies();

  /// Validations en attente (avec nom de l'employé).
  Future<List<Map<String, dynamic>>> getPendingValidations();

  /// Notes de frais en attente (avec nom de l'employé).
  Future<List<Map<String, dynamic>>> getPendingExpenses();

  /// Approuve une note de frais.
  Future<void> approveExpense(String expenseId);

  /// Rejette une note de frais.
  Future<void> rejectExpense(String expenseId);

  /// Anomalies non résolues de l'équipe (avec nom de l'employé).
  Future<List<Map<String, dynamic>>> getTeamAnomalies();

  /// Marque une anomalie comme résolue.
  Future<void> resolveAnomaly(String anomalyId);

  /// Pointages d'un employé entre deux dates (incluses).
  Future<List<Map<String, dynamic>>> getEmployeeTimesheet(
      String employeeId, String startDate, String endDate);

  /// Rôle de l'utilisateur courant, ou null si introuvable.
  Future<String?> getCurrentUserRole();
}
