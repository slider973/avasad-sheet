import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ManagerEndpoint extends Endpoint {
  /// Créer un nouveau manager
  Future<Manager> createManager(
    Session session,
    String email,
    String firstName,
    String lastName,
    String company,
    String? signature,
  ) async {
    try {
      // Vérifier si le manager existe déjà
      final existing = await Manager.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );
      
      if (existing != null) {
        throw Exception('Un manager avec cet email existe déjà');
      }
      
      // Créer le nouveau manager
      final manager = Manager(
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        signature: signature,
        isActive: true,
      );
      
      await Manager.db.insertRow(session, manager);
      
      session.log('Created new manager: $firstName $lastName (${manager.email})');
      
      return manager;
    } catch (e) {
      session.log('Error creating manager: $e');
      throw Exception('Impossible de créer le manager: $e');
    }
  }
  
  /// Mettre à jour un manager
  Future<Manager> updateManager(
    Session session,
    int managerId,
    String firstName,
    String lastName,
    String company,
    String? signature,
    bool isActive,
  ) async {
    try {
      final manager = await Manager.db.findById(session, managerId);
      
      if (manager == null) {
        throw Exception('Manager introuvable');
      }
      
      // Mettre à jour les informations
      manager.firstName = firstName;
      manager.lastName = lastName;
      manager.company = company;
      manager.signature = signature;
      manager.isActive = isActive;
      manager.updatedAt = DateTime.now();
      
      await Manager.db.updateRow(session, manager);
      
      return manager;
    } catch (e) {
      session.log('Error updating manager: $e');
      throw Exception('Impossible de mettre à jour le manager: $e');
    }
  }
  
  /// Obtenir tous les managers actifs
  Future<List<Manager>> getActiveManagers(Session session) async {
    try {
      return await Manager.db.find(
        session,
        where: (t) => t.isActive.equals(true),
        orderBy: (t) => t.lastName,
      );
    } catch (e) {
      session.log('Error getting active managers: $e');
      throw Exception('Impossible de récupérer les managers: $e');
    }
  }
  
  /// Obtenir un manager par son ID
  Future<Manager?> getManagerById(
    Session session,
    int managerId,
  ) async {
    try {
      return await Manager.db.findById(session, managerId);
    } catch (e) {
      session.log('Error getting manager by ID: $e');
      throw Exception('Impossible de récupérer le manager: $e');
    }
  }
  
  /// Obtenir un manager par son email
  Future<Manager?> getManagerByEmail(
    Session session,
    String email,
  ) async {
    try {
      return await Manager.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );
    } catch (e) {
      session.log('Error getting manager by email: $e');
      throw Exception('Impossible de récupérer le manager: $e');
    }
  }
  
  /// Désactiver un manager
  Future<void> deactivateManager(
    Session session,
    int managerId,
  ) async {
    try {
      final manager = await Manager.db.findById(session, managerId);
      
      if (manager == null) {
        throw Exception('Manager introuvable');
      }
      
      manager.isActive = false;
      manager.updatedAt = DateTime.now();
      
      await Manager.db.updateRow(session, manager);
      
      session.log('Deactivated manager: ${manager.firstName} ${manager.lastName}');
    } catch (e) {
      session.log('Error deactivating manager: $e');
      throw Exception('Impossible de désactiver le manager: $e');
    }
  }
  
  /// Activer un manager
  Future<void> activateManager(
    Session session,
    int managerId,
  ) async {
    try {
      final manager = await Manager.db.findById(session, managerId);
      
      if (manager == null) {
        throw Exception('Manager introuvable');
      }
      
      manager.isActive = true;
      manager.updatedAt = DateTime.now();
      
      await Manager.db.updateRow(session, manager);
      
      session.log('Activated manager: ${manager.firstName} ${manager.lastName}');
    } catch (e) {
      session.log('Error activating manager: $e');
      throw Exception('Impossible d\'activer le manager: $e');
    }
  }
  
  /// Créer ou réactiver un manager
  Future<Manager> createOrActivateManager(
    Session session,
    String email,
    String firstName,
    String lastName,
    String company,
    String? signature,
  ) async {
    try {
      // Vérifier si le manager existe déjà
      final existing = await Manager.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );
      
      if (existing != null) {
        // Le manager existe, on l'active s'il est inactif
        if (!existing.isActive) {
          existing.isActive = true;
          existing.updatedAt = DateTime.now();
          await Manager.db.updateRow(session, existing);
          session.log('Reactivated existing manager: $firstName $lastName (${existing.email})');
        } else {
          session.log('Manager already active: $firstName $lastName (${existing.email})');
        }
        return existing;
      }
      
      // Créer le nouveau manager
      final manager = Manager(
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        signature: signature,
        isActive: true,
      );
      
      await Manager.db.insertRow(session, manager);
      
      session.log('Created new manager: $firstName $lastName (${manager.email})');
      
      return manager;
    } catch (e) {
      session.log('Error creating/activating manager: $e');
      throw Exception('Impossible de créer ou activer le manager: $e');
    }
  }
  
  /// Obtenir les statistiques de validation d'un manager
  Future<Map<String, dynamic>> getManagerStatistics(
    Session session,
    int managerId,
  ) async {
    try {
      final manager = await Manager.db.findById(session, managerId);
      
      if (manager == null) {
        throw Exception('Manager introuvable');
      }
      
      // Compter les validations par statut
      final allValidations = await ValidationRequest.db.find(
        session,
        where: (t) => t.managerId.equals(manager.id.toString()),
      );
      
      final pendingCount = allValidations.where((v) => v.status == ValidationStatus.pending).length;
      final approvedCount = allValidations.where((v) => v.status == ValidationStatus.approved).length;
      final rejectedCount = allValidations.where((v) => v.status == ValidationStatus.rejected).length;
      
      // Obtenir les validations récentes
      final recentValidations = await ValidationRequest.db.find(
        session,
        where: (t) => t.managerId.equals(manager.id.toString()),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 10,
      );
      
      return {
        'manager': manager,
        'statistics': {
          'pending': pendingCount,
          'approved': approvedCount,
          'rejected': rejectedCount,
          'total': pendingCount + approvedCount + rejectedCount,
        },
        'recentValidations': recentValidations,
      };
    } catch (e) {
      session.log('Error getting manager statistics: $e');
      throw Exception('Impossible de récupérer les statistiques: $e');
    }
  }
  
  /// Rechercher des managers
  Future<List<Manager>> searchManagers(
    Session session,
    String query,
  ) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      
      // Recherche dans le nom et l'email
      return await Manager.db.find(
        session,
        where: (t) => t.firstName.ilike('%$lowercaseQuery%') | 
                      t.lastName.ilike('%$lowercaseQuery%') |
                      t.email.ilike('%$lowercaseQuery%'),
        orderBy: (t) => t.lastName,
      );
    } catch (e) {
      session.log('Error searching managers: $e');
      throw Exception('Impossible de rechercher les managers: $e');
    }
  }
  
  /// Importer plusieurs managers depuis une liste
  Future<List<Manager>> importManagers(
    Session session,
    List<Map<String, dynamic>> managersData,
  ) async {
    final importedManagers = <Manager>[];
    final errors = <String>[];
    
    for (final data in managersData) {
      try {
        final email = data['email'] as String?;
        final firstName = data['firstName'] as String?;
        final lastName = data['lastName'] as String?;
        final company = data['company'] as String?;
        
        if (email == null || firstName == null || lastName == null || company == null) {
          errors.add('Email, prénom, nom et entreprise requis pour chaque manager');
          continue;
        }
        
        // Vérifier si le manager existe déjà
        final existing = await Manager.db.findFirstRow(
          session,
          where: (t) => t.email.equals(email),
        );
        
        if (existing != null) {
          errors.add('Manager $email existe déjà');
          continue;
        }
        
        final manager = Manager(
          email: email,
          firstName: firstName,
          lastName: lastName,
          company: company,
          signature: data['signature'] as String?,
          isActive: true,
        );
        
        await Manager.db.insertRow(session, manager);
        importedManagers.add(manager);
        
      } catch (e) {
        errors.add('Erreur lors de l\'import: $e');
      }
    }
    
    session.log('Imported ${importedManagers.length} managers, ${errors.length} errors');
    
    if (errors.isNotEmpty) {
      throw Exception('Import partiel: ${errors.join(', ')}');
    }
    
    return importedManagers;
  }
}