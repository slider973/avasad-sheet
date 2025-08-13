import 'dart:io';
import 'package:postgres/postgres.dart';
import 'dart:convert';

void main() async {
  // Configuration de la base de données
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'time_sheet_backend', // Nom de votre base de données
    username: 'postgres',
    password: 'your_password', // Remplacez par votre mot de passe
  );

  try {
    await connection.open();
    print('✅ Connexion à la base de données réussie');

    // Données de test
    final timesheetData = {
      'validationRequestId': 1,
      'employeeId': 'john_doe',
      'employeeName': 'John Doe',
      'employeeCompany': 'Avasad',
      'month': 7,
      'year': 2024,
      'entries': [
        {
          'dayDate': '21-Jun-24',
          'startMorning': '08:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '17:00',
          'isAbsence': false,
          'hasOvertimeHours': false,
        },
        {
          'dayDate': '24-Jun-24',
          'startMorning': '08:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '17:00',
          'isAbsence': false,
          'hasOvertimeHours': false,
        }
      ],
      'totalDays': 20.0,
      'totalHours': '160:00',
      'totalOvertimeHours': '0:00',
    };

    // 1. Vérifier si la table existe
    final tableExists = await connection.query('''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public'
        AND table_name = 'timesheet_data'
      );
    ''');
    
    print('Table timesheet_data existe: ${tableExists.first.first}');

    if (!tableExists.first.first) {
      print('⚠️  La table timesheet_data n\'existe pas!');
      print('Création de la table...');
      
      await connection.execute('''
        CREATE TABLE timesheet_data (
          id SERIAL PRIMARY KEY,
          validation_request_id INTEGER NOT NULL UNIQUE,
          employee_id VARCHAR(255) NOT NULL,
          employee_name VARCHAR(255) NOT NULL,
          employee_company VARCHAR(255),
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          entries TEXT NOT NULL,
          total_days DOUBLE PRECISION NOT NULL,
          total_hours VARCHAR(50) NOT NULL,
          total_overtime_hours VARCHAR(50) NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      ''');
      
      print('✅ Table créée avec succès');
    }

    // 2. Sauvegarder les données
    print('\n📝 Sauvegarde des données timesheet...');
    
    final entriesJson = jsonEncode(timesheetData['entries']);
    
    final result = await connection.query('''
      INSERT INTO timesheet_data (
        validation_request_id,
        employee_id,
        employee_name,
        employee_company,
        month,
        year,
        entries,
        total_days,
        total_hours,
        total_overtime_hours,
        created_at,
        updated_at
      ) VALUES (
        @validationRequestId,
        @employeeId,
        @employeeName,
        @employeeCompany,
        @month,
        @year,
        @entries,
        @totalDays,
        @totalHours,
        @totalOvertimeHours,
        NOW(),
        NOW()
      ) 
      ON CONFLICT (validation_request_id) 
      DO UPDATE SET 
        entries = EXCLUDED.entries,
        total_days = EXCLUDED.total_days,
        total_hours = EXCLUDED.total_hours,
        total_overtime_hours = EXCLUDED.total_overtime_hours,
        updated_at = NOW()
      RETURNING id;
    ''', substitutionValues: {
      'validationRequestId': timesheetData['validationRequestId'],
      'employeeId': timesheetData['employeeId'],
      'employeeName': timesheetData['employeeName'],
      'employeeCompany': timesheetData['employeeCompany'],
      'month': timesheetData['month'],
      'year': timesheetData['year'],
      'entries': entriesJson,
      'totalDays': timesheetData['totalDays'],
      'totalHours': timesheetData['totalHours'],
      'totalOvertimeHours': timesheetData['totalOvertimeHours'],
    });

    print('✅ Données sauvegardées avec l\'ID: ${result.first.first}');

    // 3. Récupérer et afficher les données
    print('\n🔍 Récupération des données...');
    
    final savedData = await connection.query('''
      SELECT 
        id,
        validation_request_id,
        employee_name,
        month,
        year,
        entries,
        total_hours
      FROM timesheet_data 
      WHERE validation_request_id = @validationRequestId;
    ''', substitutionValues: {
      'validationRequestId': timesheetData['validationRequestId'],
    });

    if (savedData.isNotEmpty) {
      final row = savedData.first;
      print('ID: ${row[0]}');
      print('Validation Request ID: ${row[1]}');
      print('Employee: ${row[2]}');
      print('Period: ${row[3]}/${row[4]}');
      print('Total Hours: ${row[6]}');
      
      // Décoder les entries
      final entries = jsonDecode(row[5]);
      print('Entries count: ${entries.length}');
      print('First entry: ${entries.first}');
    }

  } catch (e) {
    print('❌ Erreur: $e');
  } finally {
    await connection.close();
    print('\n👋 Connexion fermée');
  }
}