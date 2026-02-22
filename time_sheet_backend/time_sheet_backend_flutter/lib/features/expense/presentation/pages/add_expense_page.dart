import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../../../services/injection_container.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/use_cases/create_expense_usecase.dart';
import '../../domain/use_cases/update_expense_usecase.dart';
import '../../domain/use_cases/calculate_mileage_usecase.dart';

class AddExpensePage extends StatefulWidget {
  final Expense? expense; // null = mode création, non-null = mode édition

  const AddExpensePage({Key? key, this.expense}) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _createExpenseUseCase = getIt<CreateExpenseUseCase>();
  final _updateExpenseUseCase = getIt<UpdateExpenseUseCase>();
  final _calculateMileageUseCase = getIt<CalculateMileageUseCase>();

  // Champs communs
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // Champs spécifiques au déplacement
  final _distanceController = TextEditingController();
  final _mileageRateController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();

  // Justificatif (receipt photo)
  File? _receiptImage;
  String? _existingAttachmentUrl;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();

    // Initialiser avec les valeurs de la dépense si en mode édition
    if (_isEditMode) {
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
      _descriptionController.text = widget.expense!.description;
      _existingAttachmentUrl = widget.expense!.attachmentPath;

      if (_selectedCategory == ExpenseCategory.mileage) {
        _distanceController.text = widget.expense!.distanceKm?.toString() ?? '';
        _mileageRateController.text =
            widget.expense!.mileageRate?.toStringAsFixed(2) ?? '';
        _departureController.text = widget.expense!.departureLocation ?? '';
        _arrivalController.text = widget.expense!.arrivalLocation ?? '';
        _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      } else {
        _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      }
    } else {
      // Mode création : valeurs par défaut
      _selectedDate = DateTime.now();
      _selectedCategory = ExpenseCategory.mileage;
      _mileageRateController.text =
          _calculateMileageUseCase.getDefaultMileageRate().toStringAsFixed(2);
    }

    // Calculer automatiquement le montant pour les déplacements
    _distanceController.addListener(_calculateMileageAmount);
    _mileageRateController.addListener(_calculateMileageAmount);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _distanceController.dispose();
    _mileageRateController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  void _calculateMileageAmount() {
    if (_selectedCategory != ExpenseCategory.mileage) return;

    final distance = int.tryParse(_distanceController.text);
    final rate = double.tryParse(_mileageRateController.text);

    if (distance != null && rate != null) {
      final amount = _calculateMileageUseCase.execute(
        distanceKm: distance,
        mileageRate: rate,
      );
      _amountController.text = amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la dépense' : 'Ajouter une dépense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate)),
              onTap: _selectDate,
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  _amountController.clear();
                });
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Formulaire conditionnel selon la catégorie
            if (_selectedCategory == ExpenseCategory.mileage)
              _buildMileageForm()
            else
              _buildStandardForm(),

            const SizedBox(height: 24),

            // Justificatif (receipt photo)
            _buildReceiptSection(),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMileageForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails du déplacement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _departureController,
          decoration: const InputDecoration(
            labelText: 'Lieu de départ',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le lieu de départ';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _arrivalController,
          decoration: const InputDecoration(
            labelText: 'Lieu d\'arrivée',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le lieu d\'arrivée';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (km)',
                  prefixIcon: Icon(Icons.route),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Distance requise';
                  }
                  final distance = int.tryParse(value);
                  if (distance == null || !_calculateMileageUseCase.isValidDistance(distance)) {
                    return 'Distance invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _mileageRateController,
                decoration: const InputDecoration(
                  labelText: 'Taux (CHF/km)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Taux requis';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || !_calculateMileageUseCase.isValidRate(rate)) {
                    return 'Taux invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Montant calculé (lecture seule)
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Montant total (CHF)',
            prefixIcon: const Icon(Icons.calculate),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          readOnly: true,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStandardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Montant (CHF)',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un montant';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Montant invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Justificatif',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_receiptImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _receiptImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _receiptImage = null),
                  ),
                ),
              ),
            ],
          )
        else if (_existingAttachmentUrl != null && _existingAttachmentUrl!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade400),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Justificatif déjà attaché'),
                ),
                TextButton(
                  onPressed: _pickReceiptImage,
                  child: const Text('Remplacer'),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickReceiptImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter un justificatif',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    '(optionnel)',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickReceiptImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _receiptImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadReceipt() async {
    if (_receiptImage == null) return _existingAttachmentUrl;

    try {
      final storageService = StorageService();
      final expenseId = 'receipt_${DateTime.now().millisecondsSinceEpoch}';
      final bytes = await _receiptImage!.readAsBytes();

      final url = await storageService.uploadReceipt(
        expenseId: expenseId,
        imageBytes: bytes,
      );
      return url;
    } catch (e) {
      debugPrint('Receipt upload error: $e');
      return null;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Upload receipt if selected
    final attachmentUrl = await _uploadReceipt();

    final result = _isEditMode
        ? await _updateExpenseUseCase.execute(
            id: widget.expense!.id!,
            date: _selectedDate,
            category: _selectedCategory,
            description: _descriptionController.text,
            amount: double.tryParse(_amountController.text),
            mileageRate: _selectedCategory == ExpenseCategory.mileage
                ? double.tryParse(_mileageRateController.text)
                : null,
            distanceKm: _selectedCategory == ExpenseCategory.mileage
                ? int.tryParse(_distanceController.text)
                : null,
            departureLocation: _selectedCategory == ExpenseCategory.mileage
                ? _departureController.text
                : null,
            arrivalLocation: _selectedCategory == ExpenseCategory.mileage
                ? _arrivalController.text
                : null,
          )
        : await _createExpenseUseCase.execute(
            date: _selectedDate,
            category: _selectedCategory,
            description: _descriptionController.text,
            amount: double.tryParse(_amountController.text),
            mileageRate: _selectedCategory == ExpenseCategory.mileage
                ? double.tryParse(_mileageRateController.text)
                : null,
            distanceKm: _selectedCategory == ExpenseCategory.mileage
                ? int.tryParse(_distanceController.text)
                : null,
            departureLocation: _selectedCategory == ExpenseCategory.mileage
                ? _departureController.text
                : null,
            arrivalLocation: _selectedCategory == ExpenseCategory.mileage
                ? _arrivalController.text
                : null,
          );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (expense) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Dépense modifiée avec succès'
                : 'Dépense enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour rafraîchir la liste
      },
    );
  }
}
