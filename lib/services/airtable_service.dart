import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AirtableService {
  static const String _baseId = 'applG9kbUJHfNL8cv';
  static const String _personalAccessToken = 'patFGIGa2OwgN8bkH.d175e49fdbf537d52c8a6440e155a34a34c9ed68887cc3b3176487d7e008c5a3';
  static const String _baseUrl = 'https://api.airtable.com/v0/$_baseId';

  static const List<String> paymentMethods = ['Cash', 'Transfer', 'Card'];

  void _log(String message) {
    if (kDebugMode) {
      print('[AirtableService] $message');
    }
  }

  Future<List<String>> getVendorNames() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Vendors'),
        headers: {'Authorization': 'Bearer $_personalAccessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['records'] as List)
            .map((record) => (record['fields'] as Map)['Vendor Name'].toString())
            .where((name) => name.isNotEmpty)
            .toList();
      }
      throw Exception('Failed to load vendors: ${response.statusCode}');
    } catch (e) {
      _log('getVendorNames error: $e');
      return [];
    }
  }

  Future<List<String>> getCategoryNames() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Categories'),
        headers: {'Authorization': 'Bearer $_personalAccessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['records'] as List)
            .map((record) => (record['fields'] as Map)['Categories'].toString())
            .where((name) => name.isNotEmpty)
            .toList();
      }
      throw Exception('Failed to load categories: ${response.statusCode}');
    } catch (e) {
      _log('getCategoryNames error: $e');
      return [];
    }
  }

  Future<Map<String, String>> getVendorIdMap() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Vendors'),
        headers: {'Authorization': 'Bearer $_personalAccessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          for (var record in data['records'] as List)
            (record['fields'] as Map)['Vendor Name'].toString(): record['id'].toString()
        };
      }
      throw Exception('Failed to load vendor IDs: ${response.statusCode}');
    } catch (e) {
      _log('getVendorIdMap error: $e');
      return {};
    }
  }

  Future<Map<String, String>> getCategoryIdMap() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Categories'),
        headers: {'Authorization': 'Bearer $_personalAccessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          for (var record in data['records'] as List)
            (record['fields'] as Map)['Categories'].toString(): record['id'].toString()
        };
      }
      throw Exception('Failed to load category IDs: ${response.statusCode}');
    } catch (e) {
      _log('getCategoryIdMap error: $e');
      return {};
    }
  }

  Future<bool> submitExpense({
    required DateTime date,
    required String vendorRecordId,
    required String categoryRecordId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      if (!paymentMethods.contains(paymentMethod)) {
        throw ArgumentError('Invalid payment method');
      }
      if (vendorRecordId.isEmpty || categoryRecordId.isEmpty) {
        throw ArgumentError('Missing vendor or category ID');
      }
      if (amount <= 0) {
        throw ArgumentError('Amount must be positive');
      }

      final fields = {
        'Date': '${date.month}/${date.day}/${date.year}',
        'Vendor': [vendorRecordId],
        'Category': [categoryRecordId],
        'Amount': amount,
        'Payment Method': paymentMethod,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/Expenses'),
        headers: {
          'Authorization': 'Bearer $_personalAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'records': [{'fields': fields}]}),
      );

      if (response.statusCode != 200) {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
      return true;
    } catch (e) {
      _log('submitExpense error: $e');
      rethrow;
    }
  }
}