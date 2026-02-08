import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> initializeStripe() async {
  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_xxx',
  );
}

bool get isStripeSupported => true;
