/// Represents a customer review for an order.
class CustomerReview {
  /// Unique identifier for the review.
  final int id;

  /// ID of the customer who wrote the review.
  final int customerId;

  /// ID of the order being reviewed.
  final int orderId;

  /// Rating given by the customer (1-5).
  final int rating;

  /// Comment provided by the customer (optional).
  final String? comment;

  /// Name of the customer (for display purposes).
  final String customerName;

  /// Timestamp when the review was created.
  final DateTime createdAt;

  /// Timestamp when the review was last updated (optional).
  final DateTime? updatedAt;

  CustomerReview({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.customerName,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a [CustomerReview] from a JSON map (Laravel API response).
  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      orderId: json['order_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      customerName: json['customer_name'] as String? ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  /// Converts the [CustomerReview] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
      'customer_name': customerName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}