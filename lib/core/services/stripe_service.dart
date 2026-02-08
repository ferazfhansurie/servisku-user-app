// Conditional export based on platform
export 'stripe_stub_web.dart' if (dart.library.io) 'stripe_stub_mobile.dart';

