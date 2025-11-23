# Design Document

## Overview

The Expense Report Management feature extends the Time Sheet application to handle employee expense submissions, manager approvals, and PDF generation for expense reports. The design follows the existing Clean Architecture pattern used in the validation feature, with clear separation between domain, data, and presentation layers. The system will support offline-first functionality with automatic synchronization, similar to the timesheet validation workflow.

### Key Design Principles

- **Consistency**: Follow the same architectural patterns as the validation feature
- **Offline-First**: Use Isar for local storage with Serverpod synchronization
- **Reusability**: Leverage existing PDF generation and signature infrastructure
- **Scalability**: Design for future enhancements (multi-currency, approval workflows)

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Expense List │  │ Expense Form │  │ Expense      │      │
│  │ Page         │  │ Page         │  │ Detail Page  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                    ┌───────▼────────┐                        │
│                    │  Expense BLoC  │                        │
│                    └───────┬────────┘                        │
└────────────────────────────┼──────────────────────────────────┘
                             │
┌────────────────────────────┼──────────────────────────────────┐
│                    Domain Layer                               │
│                    ┌───────▼────────┐                         │
│                    │   Use Cases    │                         │
│                    └───────┬────────┘                         │
│                            │                                  │
│                    ┌───────▼────────┐                         │
│                    │  Repository    │                         │
│                    │  Interface     │                         │
│                    └────────────────┘                         │
└──────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────┼──────────────────────────────────┐
│                     Data Layer                                │
│         ┌──────────────────┴──────────────────┐               │
│         │                                     │               │
│  ┌──────▼────────┐                  ┌────────▼────────┐      │
│  │ Local Data    │                  │ Remote Data     │      │
│  │ Source (Isar) │                  │ Source          │      │
│  └───────────────┘                  │ (Serverpod)     │      │
│                                     └─────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```


### Feature Structure

Following the existing validation feature pattern:

```
lib/features/expense/
├── data/
│   ├── data_sources/
│   │   ├── expense_local_data_source.dart
│   │   └── expense_remote_data_source.dart
│   ├── models/
│   │   ├── expense_report_cache.dart (Isar)
│   │   ├── expense_report_cache.g.dart
│   │   ├── expense_entry_cache.dart (Isar)
│   │   ├── expense_entry_cache.g.dart
│   │   ├── receipt_cache.dart (Isar)
│   │   ├── receipt_cache.g.dart
│   │   └── sync_queue_item.dart (Isar)
│   └── repositories/
│       └── expense_repository_serverpod_impl.dart
├── domain/
│   ├── entities/
│   │   ├── expense_report.dart
│   │   ├── expense_entry.dart
│   │   ├── receipt.dart
│   │   └── expense_category.dart
│   ├── repositories/
│   │   └── expense_repository.dart
│   ├── use_cases/
│   │   ├── create_expense_report_usecase.dart
│   │   ├── add_expense_entry_usecase.dart
│   │   ├── attach_receipt_usecase.dart
│   │   ├── submit_expense_report_usecase.dart
│   │   ├── get_employee_expenses_usecase.dart
│   │   ├── get_manager_expenses_usecase.dart
│   │   ├── approve_expense_usecase.dart
│   │   ├── reject_expense_usecase.dart
│   │   ├── generate_expense_pdf_usecase.dart
│   │   └── duplicate_expense_report_usecase.dart
│   └── services/
│       ├── expense_pdf_generator_service.dart
│       └── expense_sync_service.dart
└── presentation/
    ├── bloc/
    │   ├── expense_list/
    │   │   ├── expense_list_bloc.dart
    │   │   ├── expense_list_event.dart
    │   │   └── expense_list_state.dart
    │   ├── expense_form/
    │   │   ├── expense_form_bloc.dart
    │   │   ├── expense_form_event.dart
    │   │   └── expense_form_state.dart
    │   └── expense_approval/
    │       ├── expense_approval_bloc.dart
    │       ├── expense_approval_event.dart
    │       └── expense_approval_state.dart
    ├── pages/
    │   ├── expense_list_page.dart
    │   ├── expense_form_page.dart
    │   ├── expense_detail_page.dart
    │   └── expense_approval_page.dart
    └── widgets/
        ├── expense_card.dart
        ├── expense_entry_item.dart
        ├── receipt_thumbnail.dart
        ├── expense_category_selector.dart
        └── expense_status_badge.dart
```

## Components and Interfaces

### Domain Entities

#### ExpenseReport Entity

```dart
class ExpenseReport extends Equatable {
  final String id;
  final String organizationId;
  final String employeeId;
  final String? employeeName;
  final String title;
  final int month;
  final int year;
  final ExpenseStatus status;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? managerId;
  final String? managerName;
  final String? managerComment;
  final String? managerSignature;
  final String? rejectionReason;
  final double totalAmount;
  final String? pdfPath;
  final String? signedPdfPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseEntry> entries;
  
  // Computed properties
  bool get isDraft => status == ExpenseStatus.draft;
  bool get isSubmitted => status == ExpenseStatus.submitted;
  bool get isApproved => status == ExpenseStatus.approved;
  bool get isRejected => status == ExpenseStatus.rejected;
  bool get isPaid => status == ExpenseStatus.paid;
  bool get canEdit => status == ExpenseStatus.draft || status == ExpenseStatus.rejected;
  bool get canSubmit => entries.isNotEmpty && isDraft;
  
  Map<ExpenseCategory, double> get totalsByCategory;
}

enum ExpenseStatus {
  draft,
  submitted,
  approved,
  rejected,
  paid,
}
```


#### ExpenseEntry Entity

```dart
class ExpenseEntry extends Equatable {
  final String id;
  final String expenseReportId;
  final DateTime date;
  final ExpenseCategory category;
  final String description;
  final double amount;
  final String? notes;
  final List<Receipt> receipts;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  bool get hasReceipts => receipts.isNotEmpty;
}
```

#### Receipt Entity

```dart
class Receipt extends Equatable {
  final String id;
  final String expenseEntryId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String localPath;
  final String? remotePath;
  final bool isSynced;
  final DateTime createdAt;
  
  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
}
```

#### ExpenseCategory Enum

```dart
enum ExpenseCategory {
  transport,
  meals,
  accommodation,
  supplies,
  communication,
  training,
  entertainment,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.meals:
        return 'Repas';
      case ExpenseCategory.accommodation:
        return 'Hébergement';
      case ExpenseCategory.supplies:
        return 'Fournitures';
      case ExpenseCategory.communication:
        return 'Communication';
      case ExpenseCategory.training:
        return 'Formation';
      case ExpenseCategory.entertainment:
        return 'Représentation';
      case ExpenseCategory.other:
        return 'Autre';
    }
  }
  
  IconData get icon {
    // Return appropriate Material icons
  }
  
  Color get color {
    // Return category-specific colors
  }
}
```

### Repository Interface

```dart
abstract class ExpenseRepository {
  // Expense Report Operations
  Future<Either<Failure, ExpenseReport>> createExpenseReport({
    required String employeeId,
    required String title,
    required int month,
    required int year,
  });
  
  Future<Either<Failure, ExpenseReport>> getExpenseReport(String id);
  
  Future<Either<Failure, List<ExpenseReport>>> getEmployeeExpenses(
    String employeeId, {
    ExpenseStatus? status,
    int? year,
  });
  
  Future<Either<Failure, List<ExpenseReport>>> getManagerExpenses(
    String managerId, {
    ExpenseStatus? status,
  });
  
  Future<Either<Failure, ExpenseReport>> updateExpenseReport(
    ExpenseReport report,
  );
  
  Future<Either<Failure, void>> deleteExpenseReport(String id);
  
  // Expense Entry Operations
  Future<Either<Failure, ExpenseEntry>> addExpenseEntry({
    required String expenseReportId,
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    required double amount,
    String? notes,
  });
  
  Future<Either<Failure, ExpenseEntry>> updateExpenseEntry(
    ExpenseEntry entry,
  );
  
  Future<Either<Failure, void>> deleteExpenseEntry(String id);
  
  // Receipt Operations
  Future<Either<Failure, Receipt>> attachReceipt({
    required String expenseEntryId,
    required String filePath,
    required String fileName,
  });
  
  Future<Either<Failure, void>> deleteReceipt(String id);
  
  Future<Either<Failure, Uint8List>> getReceiptData(String id);
  
  // Submission and Approval
  Future<Either<Failure, ExpenseReport>> submitExpenseReport(String id);
  
  Future<Either<Failure, ExpenseReport>> approveExpense({
    required String expenseReportId,
    required String managerSignature,
    String? comment,
  });
  
  Future<Either<Failure, ExpenseReport>> rejectExpense({
    required String expenseReportId,
    required String reason,
  });
  
  // PDF Generation
  Future<Either<Failure, Uint8List>> generateExpensePdf(String expenseReportId);
  
  Future<Either<Failure, String>> downloadExpensePdf(String expenseReportId);
  
  // Utility Operations
  Future<Either<Failure, ExpenseReport>> duplicateExpenseReport(String id);
  
  Future<Either<Failure, void>> syncOfflineData();
  
  Stream<Either<Failure, List<ExpenseReport>>> watchEmployeeExpenses(
    String employeeId,
  );
}
```


## Data Models

### Isar Local Storage Models

#### ExpenseReportCache (Isar Collection)

```dart
@collection
class ExpenseReportCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String expenseReportId;
  
  late String organizationId;
  late String employeeId;
  String? employeeName;
  late String title;
  late int month;
  late int year;
  
  @Enumerated(EnumType.name)
  late ExpenseStatus status;
  
  DateTime? submittedAt;
  DateTime? approvedAt;
  String? managerId;
  String? managerName;
  String? managerComment;
  String? managerSignature;
  String? rejectionReason;
  late double totalAmount;
  String? pdfPath;
  String? signedPdfPath;
  late DateTime createdAt;
  late DateTime updatedAt;
  
  bool isSynced = false;
  bool needsSync = false;
  DateTime? lastSyncedAt;
  
  // Relationships
  final entries = IsarLinks<ExpenseEntryCache>();
}
```

#### ExpenseEntryCache (Isar Collection)

```dart
@collection
class ExpenseEntryCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String entryId;
  
  late String expenseReportId;
  late DateTime date;
  
  @Enumerated(EnumType.name)
  late ExpenseCategory category;
  
  late String description;
  late double amount;
  String? notes;
  late DateTime createdAt;
  late DateTime updatedAt;
  
  bool isSynced = false;
  bool needsSync = false;
  
  // Relationships
  final receipts = IsarLinks<ReceiptCache>();
}
```

#### ReceiptCache (Isar Collection)

```dart
@collection
class ReceiptCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String receiptId;
  
  late String expenseEntryId;
  late String fileName;
  late String mimeType;
  late int sizeBytes;
  late String localPath;
  String? remotePath;
  late DateTime createdAt;
  
  bool isSynced = false;
  bool needsUpload = true;
}
```

### Serverpod Protocol Models

#### ExpenseReportProtocol

```yaml
# protocol/expense_report.yaml
class: ExpenseReport
table: expense_reports
fields:
  id: String, database=uuid
  organizationId: String
  employeeId: String
  employeeName: String?
  title: String
  month: int
  year: int
  status: String
  submittedAt: DateTime?
  approvedAt: DateTime?
  managerId: String?
  managerName: String?
  managerComment: String?
  managerSignature: String?
  rejectionReason: String?
  totalAmount: double
  pdfPath: String?
  signedPdfPath: String?
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  employee_idx:
    fields: employeeId, status
  manager_idx:
    fields: managerId, status
  period_idx:
    fields: year, month
```

#### ExpenseEntryProtocol

```yaml
# protocol/expense_entry.yaml
class: ExpenseEntry
table: expense_entries
fields:
  id: String, database=uuid
  expenseReportId: String
  date: DateTime
  category: String
  description: String
  amount: double
  notes: String?
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  report_idx:
    fields: expenseReportId
  date_idx:
    fields: date
```

#### ReceiptProtocol

```yaml
# protocol/receipt.yaml
class: Receipt
table: receipts
fields:
  id: String, database=uuid
  expenseEntryId: String
  fileName: String
  mimeType: String
  sizeBytes: int
  storagePath: String
  createdAt: DateTime
indexes:
  entry_idx:
    fields: expenseEntryId
```


## Error Handling

### Failure Types

Following the existing pattern in `core/error/failures.dart`:

```dart
// Expense-specific failures
class ExpenseFailure extends Failure {
  ExpenseFailure(String message) : super(message);
}

class ExpenseNotFoundFailure extends ExpenseFailure {
  ExpenseNotFoundFailure(String id) 
    : super('Expense report not found: $id');
}

class ExpenseValidationFailure extends ExpenseFailure {
  ExpenseValidationFailure(String message) : super(message);
}

class ReceiptUploadFailure extends ExpenseFailure {
  ReceiptUploadFailure(String message) 
    : super('Failed to upload receipt: $message');
}

class ExpenseSyncFailure extends ExpenseFailure {
  ExpenseSyncFailure(String message) 
    : super('Sync failed: $message');
}

class ExpensePdfGenerationFailure extends ExpenseFailure {
  ExpensePdfGenerationFailure(String message) 
    : super('PDF generation failed: $message');
}
```

### Error Handling Strategy

1. **Network Errors**: Queue operations for later sync when offline
2. **Validation Errors**: Display user-friendly messages in UI
3. **Storage Errors**: Log and attempt recovery with fallback
4. **PDF Generation Errors**: Retry with simplified template if needed
5. **Receipt Upload Errors**: Queue for background upload with retry logic

## PDF Generation

### ExpensePdfGeneratorService

The PDF generator will create expense reports similar to the existing timesheet PDFs, following the format shown in the reference PDF.

```dart
class ExpensePdfGeneratorService {
  Future<Uint8List> generateExpensePdf({
    required ExpenseReport report,
    required List<ExpenseEntry> entries,
    String? managerSignature,
    bool includeReceipts = false,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader(report),
          pw.SizedBox(height: 20),
          _buildEmployeeInfo(report),
          pw.SizedBox(height: 20),
          _buildExpenseTable(entries),
          pw.SizedBox(height: 20),
          _buildCategorySummary(entries),
          pw.SizedBox(height: 20),
          _buildTotalSection(report),
          pw.SizedBox(height: 40),
          _buildSignatureSection(report, managerSignature),
        ],
      ),
    );
    
    if (includeReceipts) {
      await _appendReceiptPages(pdf, entries);
    }
    
    return pdf.save();
  }
  
  pw.Widget _buildHeader(ExpenseReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTE DE FRAIS',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('${report.title}'),
          pw.Text('Période: ${report.month}/${report.year}'),
          pw.Text('Statut: ${_getStatusText(report.status)}'),
        ],
      ),
    );
  }
  
  pw.Widget _buildExpenseTable(List<ExpenseEntry> entries) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(2), // Category
        2: const pw.FlexColumnWidth(4), // Description
        3: const pw.FlexColumnWidth(2), // Amount
        4: const pw.FlexColumnWidth(1), // Receipt
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Catégorie', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Montant', isHeader: true),
            _buildTableCell('Justif.', isHeader: true),
          ],
        ),
        // Data rows
        ...entries.map((entry) => pw.TableRow(
          children: [
            _buildTableCell(_formatDate(entry.date)),
            _buildTableCell(entry.category.displayName),
            _buildTableCell(entry.description),
            _buildTableCell('${entry.amount.toStringAsFixed(2)} €', 
              alignment: pw.Alignment.centerRight),
            _buildTableCell(entry.hasReceipts ? '✓' : '', 
              alignment: pw.Alignment.center),
          ],
        )),
      ],
    );
  }
  
  pw.Widget _buildCategorySummary(List<ExpenseEntry> entries) {
    final categoryTotals = <ExpenseCategory, double>{};
    for (final entry in entries) {
      categoryTotals[entry.category] = 
        (categoryTotals[entry.category] ?? 0) + entry.amount;
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Récapitulatif par catégorie',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...categoryTotals.entries.map((e) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.key.displayName),
              pw.Text('${e.value.toStringAsFixed(2)} €'),
            ],
          )),
        ],
      ),
    );
  }
}
```


## Offline Synchronization Strategy

### Sync Queue Architecture

Similar to the validation feature, use a sync queue for offline operations:

```dart
@collection
class ExpenseSyncQueueItem {
  Id id = Isar.autoIncrement;
  
  @Enumerated(EnumType.name)
  late SyncOperation operation;
  
  @Enumerated(EnumType.name)
  late SyncEntityType entityType;
  
  late String entityId;
  late String jsonData;
  late DateTime createdAt;
  late int retryCount;
  DateTime? lastAttemptAt;
  String? errorMessage;
}

enum SyncOperation {
  create,
  update,
  delete,
  uploadReceipt,
}

enum SyncEntityType {
  expenseReport,
  expenseEntry,
  receipt,
}
```

### Sync Flow

1. **User Action**: User creates/updates expense data
2. **Local Storage**: Save immediately to Isar
3. **Queue Operation**: Add to sync queue if online
4. **Background Sync**: Process queue items when connectivity available
5. **Conflict Resolution**: Server data takes precedence, notify user of conflicts
6. **Receipt Upload**: Upload receipts separately with progress tracking

### Sync Service

```dart
class ExpenseSyncService {
  final ExpenseLocalDataSource _localDataSource;
  final ExpenseRemoteDataSource _remoteDataSource;
  final Isar _isar;
  
  Future<void> syncAll() async {
    if (!await _hasConnectivity()) return;
    
    try {
      // 1. Pull server changes first
      await _pullServerChanges();
      
      // 2. Process local sync queue
      await _processQueuedOperations();
      
      // 3. Upload pending receipts
      await _uploadPendingReceipts();
      
      // 4. Mark everything as synced
      await _updateSyncStatus();
    } catch (e) {
      logger.e('Sync failed: $e');
      rethrow;
    }
  }
  
  Future<void> _pullServerChanges() async {
    final serverReports = await _remoteDataSource.getExpenseReports();
    
    for (final serverReport in serverReports) {
      final localReport = await _localDataSource.getExpenseReport(
        serverReport.id,
      );
      
      if (localReport == null || 
          serverReport.updatedAt.isAfter(localReport.updatedAt)) {
        await _localDataSource.saveExpenseReport(serverReport);
      }
    }
  }
  
  Future<void> _processQueuedOperations() async {
    final queueItems = await _isar.expenseSyncQueueItems
      .where()
      .sortByCreatedAt()
      .findAll();
    
    for (final item in queueItems) {
      try {
        await _processSyncItem(item);
        await _isar.writeTxn(() async {
          await _isar.expenseSyncQueueItems.delete(item.id);
        });
      } catch (e) {
        await _handleSyncError(item, e);
      }
    }
  }
}
```

## UI/UX Design

### Screen Layouts

#### Expense List Page

- **Header**: Month/Year selector, filter by status
- **List Items**: 
  - Expense report title
  - Total amount with currency
  - Status badge (draft, submitted, approved, rejected, paid)
  - Number of entries
  - Submission date
- **FAB**: Create new expense report
- **Actions**: Tap to view details, swipe for quick actions

#### Expense Form Page

- **Header**: Report title, period, total amount
- **Tabs**: 
  - Entries: List of expense entries
  - Summary: Category breakdown chart
- **Entry List**:
  - Date, category icon, description
  - Amount
  - Receipt indicator
  - Swipe to edit/delete
- **FAB**: Add new expense entry
- **Bottom Bar**: Save draft, Submit buttons

#### Expense Entry Dialog

- **Fields**:
  - Date picker
  - Category dropdown with icons
  - Description text field
  - Amount input with currency
  - Notes (optional)
  - Receipt attachments (camera/gallery)
- **Receipt Preview**: Thumbnail grid with delete option
- **Actions**: Cancel, Save

#### Expense Detail Page (Read-only)

- **Header**: Report info, status
- **Content**: 
  - Employee information
  - Expense entries table
  - Category summary
  - Total amount
  - Receipt gallery
- **Actions**: 
  - Download PDF
  - View signed PDF (if approved)
  - Duplicate (for employees)
  - Approve/Reject (for managers)

### Manager Approval Flow

1. Manager opens expense from notification or list
2. Reviews expense entries and receipts
3. Can zoom into receipt images
4. Adds optional comment
5. Draws signature (reuse validation signature component)
6. Confirms approval/rejection
7. System generates signed PDF
8. Employee receives notification


## Testing Strategy

### Unit Tests

1. **Entity Tests**:
   - ExpenseReport computed properties
   - ExpenseCategory extensions
   - Status transitions

2. **Use Case Tests**:
   - CreateExpenseReportUseCase validation
   - AddExpenseEntryUseCase validation
   - SubmitExpenseReportUseCase business rules
   - ApproveExpenseUseCase authorization

3. **Repository Tests**:
   - CRUD operations
   - Offline queue management
   - Sync conflict resolution

4. **Service Tests**:
   - PDF generation with various data
   - Receipt compression
   - Sync service logic

### Integration Tests

1. **Offline Flow**:
   - Create expense offline
   - Add entries and receipts
   - Submit when online
   - Verify sync

2. **Approval Workflow**:
   - Employee submits
   - Manager receives notification
   - Manager approves with signature
   - PDF regeneration
   - Employee receives notification

3. **Receipt Management**:
   - Attach multiple receipts
   - Upload progress
   - Retry failed uploads
   - Delete receipts

### Widget Tests

1. **ExpenseListPage**: Display, filtering, navigation
2. **ExpenseFormPage**: Form validation, entry management
3. **ExpenseCategorySelector**: Selection, icons, colors
4. **ReceiptThumbnail**: Image display, delete action
5. **ExpenseStatusBadge**: Status colors and text

## Performance Considerations

### Image Optimization

```dart
class ReceiptImageProcessor {
  Future<File> compressReceipt(File originalFile) async {
    final image = img.decodeImage(await originalFile.readAsBytes());
    
    if (image == null) throw Exception('Invalid image');
    
    // Resize if too large (max 1920x1920)
    final resized = image.width > 1920 || image.height > 1920
      ? img.copyResize(image, width: 1920, height: 1920)
      : image;
    
    // Compress to JPEG with 85% quality
    final compressed = img.encodeJpg(resized, quality: 85);
    
    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${uuid.v4()}.jpg');
    await tempFile.writeAsBytes(compressed);
    
    return tempFile;
  }
}
```

### Pagination

- Load expense reports in pages of 20
- Lazy load expense entries when viewing details
- Cache receipt thumbnails
- Implement infinite scroll for large lists

### Background Upload

```dart
class ReceiptUploadService {
  final Queue<Receipt> _uploadQueue = Queue();
  bool _isUploading = false;
  
  Future<void> queueReceiptUpload(Receipt receipt) async {
    _uploadQueue.add(receipt);
    _processQueue();
  }
  
  Future<void> _processQueue() async {
    if (_isUploading || _uploadQueue.isEmpty) return;
    
    _isUploading = true;
    
    while (_uploadQueue.isNotEmpty) {
      final receipt = _uploadQueue.removeFirst();
      
      try {
        await _uploadReceipt(receipt);
      } catch (e) {
        // Retry logic with exponential backoff
        await _handleUploadError(receipt, e);
      }
    }
    
    _isUploading = false;
  }
}
```

## Security Considerations

### Data Encryption

- Encrypt receipt files at rest using flutter_secure_storage
- Use HTTPS for all API communications
- Store sensitive data (signatures) encrypted in Isar

### Access Control

- Employees can only view/edit their own expenses
- Managers can only approve expenses for their team
- Implement role-based access control (RBAC)
- Validate permissions on both client and server

### Audit Trail

```dart
class ExpenseAuditLog {
  final String id;
  final String expenseReportId;
  final String userId;
  final String action; // created, updated, submitted, approved, rejected
  final Map<String, dynamic>? changes;
  final DateTime timestamp;
}
```

## Migration Strategy

### Phase 1: Core Infrastructure (Week 1-2)
- Set up Serverpod protocol models
- Create database migrations
- Implement Isar collections
- Set up repository interfaces

### Phase 2: Basic CRUD (Week 3-4)
- Implement expense report creation
- Add expense entry management
- Basic UI for list and form
- Local storage working

### Phase 3: Receipt Management (Week 5)
- Image picker integration
- Receipt compression
- Upload service
- Thumbnail display

### Phase 4: PDF Generation (Week 6)
- PDF template design
- PDF generator service
- Preview functionality
- Download capability

### Phase 5: Approval Workflow (Week 7)
- Manager approval UI
- Signature integration
- Notification system
- Status updates

### Phase 6: Offline Sync (Week 8)
- Sync queue implementation
- Conflict resolution
- Background sync
- Error handling

### Phase 7: Polish & Testing (Week 9-10)
- UI/UX refinements
- Comprehensive testing
- Performance optimization
- Documentation

## Dependencies

### New Dependencies Required

```yaml
dependencies:
  # Image handling
  image_picker: ^1.0.0
  image: ^4.0.0
  
  # File handling
  path_provider: ^2.0.0
  file_picker: ^6.0.0
  
  # PDF viewing
  flutter_pdfview: ^1.3.0
  
  # Charts for category breakdown
  fl_chart: ^0.65.0
  
  # Currency formatting
  intl: ^0.18.0
```

### Existing Dependencies to Leverage

- isar: Local storage
- flutter_bloc: State management
- fpdart: Functional error handling
- equatable: Value equality
- pdf: PDF generation
- serverpod_flutter: Backend communication

## Future Enhancements

### Phase 2 Features (Post-MVP)

1. **Multi-Currency Support**
   - Currency selection per entry
   - Exchange rate integration
   - Multi-currency totals

2. **Advanced Approval Workflows**
   - Multi-level approvals
   - Approval delegation
   - Automatic approval rules

3. **Analytics Dashboard**
   - Spending trends
   - Category analysis
   - Budget tracking
   - Export to Excel

4. **OCR Receipt Scanning**
   - Automatic data extraction from receipts
   - ML-based categorization
   - Vendor recognition

5. **Policy Enforcement**
   - Per-diem limits
   - Category budgets
   - Approval thresholds
   - Compliance checks

6. **Integration**
   - Accounting software export
   - Bank statement reconciliation
   - Corporate card integration
