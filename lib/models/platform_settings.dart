class PlatformSettings {
  final int id;
  final String platformName;
  final String currencyCode;
  final String currencySymbol;
  final String contactEmail;
  final String contactPhone;
  final String address;

  // New fields
  final String? logoPath;
  final double taxRate;
  final String taxName;
  final String invoicePrefix;
  final String timezone;
  final String dateFormat;

  PlatformSettings({
    this.id = 1,
    required this.platformName,
    required this.currencyCode,
    required this.currencySymbol,
    this.contactEmail = '',
    this.contactPhone = '',
    this.address = '',
    this.logoPath,
    this.taxRate = 0.0,
    this.taxName = 'VAT',
    this.invoicePrefix = 'INV-',
    this.timezone = 'UTC',
    this.dateFormat = 'dd/MM/yyyy',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform_name': platformName,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'logo_path': logoPath,
      'tax_rate': taxRate,
      'tax_name': taxName,
      'invoice_prefix': invoicePrefix,
      'timezone': timezone,
      'date_format': dateFormat,
    };
  }

  factory PlatformSettings.fromMap(Map<String, dynamic> map) {
    return PlatformSettings(
      id: map['id'] as int,
      platformName: map['platform_name'] as String,
      currencyCode: map['currency_code'] as String,
      currencySymbol: map['currency_symbol'] as String,
      contactEmail: map['contact_email'] as String? ?? '',
      contactPhone: map['contact_phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      logoPath: map['logo_path'] as String?,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxName: map['tax_name'] as String? ?? 'VAT',
      invoicePrefix: map['invoice_prefix'] as String? ?? 'INV-',
      timezone: map['timezone'] as String? ?? 'UTC',
      dateFormat: map['date_format'] as String? ?? 'dd/MM/yyyy',
    );
  }

  PlatformSettings copyWith({
    int? id,
    String? platformName,
    String? currencyCode,
    String? currencySymbol,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? logoPath,
    double? taxRate,
    String? taxName,
    String? invoicePrefix,
    String? timezone,
    String? dateFormat,
  }) {
    return PlatformSettings(
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      taxRate: taxRate ?? this.taxRate,
      taxName: taxName ?? this.taxName,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}
