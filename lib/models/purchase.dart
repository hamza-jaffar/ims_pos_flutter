import 'package:ims_pos_system/models/purchase_item.dart';
import 'package:ims_pos_system/models/supplier.dart';

class Purchase {
  final int? id;
  final String referenceNo;
  final int? supplierId;
  final int? customerId;
  final DateTime purchaseDate;
  final String type; // Purchase, Order, Return, Sale, SaleReturn
  final String status; // Received, Pending, Ordered, Returned, Completed
  final String paymentStatus; // Paid, Unpaid, Partial
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String? paymentMethod;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relational data
  final Supplier? supplier;
  final List<PurchaseItem> items;

  Purchase({
    this.id,
    required this.referenceNo,
    this.supplierId,
    this.customerId,
    required this.purchaseDate,
    this.type = 'Purchase',
    this.status = 'Received',
    this.paymentStatus = 'Unpaid',
    this.grandTotal = 0.0,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.paymentMethod,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.supplier,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference_no': referenceNo,
      'supplier_id': supplierId,
      'customer_id': customerId,
      'purchase_date': purchaseDate.toIso8601String(),
      'type': type,
      'status': status,
      'payment_status': paymentStatus,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'note': note,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Purchase.fromMap(
    Map<String, dynamic> map, {
    Supplier? supplier,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: map['id'] as int?,
      referenceNo: map['reference_no'] as String,
      supplierId: map['supplier_id'] as int?,
      customerId: map['customer_id'] as int?,
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      type: map['type'] as String? ?? 'Purchase',
      status: map['status'] as String? ?? 'Received',
      paymentStatus: map['payment_status'] as String? ?? 'Unpaid',
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      supplier: supplier,
      items: items ?? const [],
    );
  }

  Purchase copyWith({
    int? id,
    String? referenceNo,
    int? supplierId,
    int? customerId,
    DateTime? purchaseDate,
    String? type,
    String? status,
    String? paymentStatus,
    double? grandTotal,
    double? paidAmount,
    double? dueAmount,
    String? paymentMethod,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    Supplier? supplier,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      referenceNo: referenceNo ?? this.referenceNo,
      supplierId: supplierId ?? this.supplierId,
      customerId: customerId ?? this.customerId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supplier: supplier ?? this.supplier,
      items: items ?? this.items,
    );
  }
}
