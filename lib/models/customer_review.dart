import 'package:flutter/foundation.dart'; // Add this import for debugPrint

class CustomerReview {
  final int id;
  final int customerId;
  final int? orderId;
  final int rating;
  final String? comment;
  final String customerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerReview({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.rating,
    this.comment,
    required this.customerName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerReview(
        id: _parseInt(json['id'], 'id'),
        customerId: _parseInt(json['customer_id'], 'customer_id'),
        orderId: json['order_id'] != null
            ? _parseInt(json['order_id'], 'order_id')
            : null,
        rating: _parseInt(json['rating'], 'rating'),
        comment: json['comment'] as String?,
        customerName: json['customer_name'] as String? ?? 'Unknown Customer',
        createdAt: _parseDateTime(json['created_at'], 'created_at'),
        updatedAt: _parseDateTime(json['updated_at'], 'updated_at'),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing CustomerReview: $e\n$stackTrace');
      rethrow; // Rethrow the exception for debugging, but you can handle it differently if needed
    }
  }

  // Helper method to parse int values safely
  static int _parseInt(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('$fieldName is null');
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        throw FormatException('Invalid $fieldName format: $value');
      }
    }
    throw FormatException(
        '$fieldName must be an int or String, got ${value.runtimeType}');
  }

  // Helper method to parse DateTime values safely
  static DateTime _parseDateTime(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('$fieldName is null');
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw FormatException('Invalid $fieldName format: $value');
      }
    }
    throw FormatException(
        '$fieldName must be a String, got ${value.runtimeType}');
  }

  @override
  String toString() {
    return 'CustomerReview(id: $id, customerId: $customerId, orderId: $orderId, '
        'rating: $rating, comment: $comment, customerName: $customerName, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
