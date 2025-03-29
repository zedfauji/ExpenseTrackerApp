import 'package:flutter/material.dart';

class ExpenseFormScreen extends StatelessWidget {
  const ExpenseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense'),
      ),
      body: const Center(
        child: Text('Expense Form Will Appear Here'),
      ),
    );
  }
}