import 'package:flutter/material.dart';
import 'services/airtable_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AirtableService airtableService = AirtableService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExpenseFormScreen(airtableService: airtableService),
    );
  }
}

class ExpenseFormScreen extends StatefulWidget {
  final AirtableService airtableService;

  const ExpenseFormScreen({super.key, required this.airtableService});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedVendor;
  String? _selectedCategory;
  String _paymentMethod = 'Cash';
  List<String> _vendors = [];
  List<String> _categories = [];
  Map<String, String> _vendorIdMap = {};
  Map<String, String> _categoryIdMap = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      
      _vendors = await widget.airtableService.getVendorNames();
      _categories = await widget.airtableService.getCategoryNames();
      
      _vendorIdMap = await widget.airtableService.getVendorIdMap();
      _categoryIdMap = await widget.airtableService.getCategoryIdMap();

      if (mounted) {
        setState(() {
          _selectedVendor = _vendors.isNotEmpty ? _vendors.first : null;
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVendor == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select vendor and category')),
      );
      return;
    }

    final vendorId = _vendorIdMap[_selectedVendor];
    final categoryId = _categoryIdMap[_selectedCategory];

    if (vendorId == null || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid vendor or category selection')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      final success = await widget.airtableService.submitExpense(
        date: _selectedDate,
        vendorRecordId: vendorId,
        categoryRecordId: categoryId,
        amount: amount,
        paymentMethod: _paymentMethod,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense submitted successfully!')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedVendor = _vendors.isNotEmpty ? _vendors.first : null;
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      _paymentMethod = 'Cash';
    });
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('New Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Date Picker
              ListTile(
                title: Text('Date'),
                subtitle: Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              
              // Vendor Dropdown
              DropdownButtonFormField<String>(
                value: _selectedVendor,
                items: _vendors.map((vendor) => DropdownMenuItem(
                  value: vendor,
                  child: Text(vendor),
                )).toList(),
                onChanged: (value) => setState(() => _selectedVendor = value),
                decoration: InputDecoration(labelText: 'Vendor'),
                validator: (value) => value == null ? 'Required' : null,
              ),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) => value == null ? 'Required' : null,
              ),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final amount = double.tryParse(value);
                  if (amount == null) return 'Invalid number';
                  if (amount <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              
              // Payment Method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: AirtableService.paymentMethods.map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                )).toList(),
                onChanged: (value) => setState(() => _paymentMethod = value!),
                decoration: InputDecoration(labelText: 'Payment Method'),
                validator: (value) => value == null ? 'Required' : null,
              ),
              
              SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitExpense,
                child: _isSubmitting 
                    ? CircularProgressIndicator()
                    : Text('Submit Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}