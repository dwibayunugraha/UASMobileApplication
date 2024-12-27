// lib/utils/midtrans_config.dart
class MidtransConfig {
  static const String merchantId = "G812785411";
  static const String clientKey = "SB-Mid-client-U73_o6sl1UvGKGvp";
  static const String serverKey = "SB-Mid-server-8055QNA56pEPx4G8aywKOWh4";
  
  // URL endpoints
  static const String baseUrl = "https://app.sandbox.midtrans.com/snap/v1";
  static const String checkStatusUrl = "https://api.sandbox.midtrans.com/v2";
  
  // Payment channels
  static const List<String> enabledPayments = [
    'credit_card',
    'bca_va',
    'bni_va',
    'bri_va',
    'gopay',
    'shopeepay'
  ];
}