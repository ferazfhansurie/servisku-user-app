// Stub for web platform - Stripe is not supported on web
class Stripe {
  static String publishableKey = '';
  
  static Future<void> instance() async {}
}

Future<void> initializeStripe() async {
  // No-op on web
}

bool get isStripeSupported => false;
