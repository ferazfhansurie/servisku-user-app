import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/search_screen.dart';
import '../features/home/screens/contractor_profile_screen.dart';
import '../features/home/screens/service_detail_screen.dart';
import '../features/home/screens/help_request_screen.dart';
import '../features/booking/screens/booking_form_screen.dart';
import '../features/booking/screens/booking_detail_screen.dart';
import '../features/booking/screens/bookings_list_screen.dart';
import '../features/booking/screens/bids_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_room_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/addresses_screen.dart';
import '../shared/widgets/main_scaffold.dart';

// Auth state notifier for router refresh
class AuthStateNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  void update(bool isLoggedIn, bool isLoading) {
    if (_isLoggedIn != isLoggedIn || _isLoading != isLoading) {
      _isLoggedIn = isLoggedIn;
      _isLoading = isLoading;
      notifyListeners();
    }
  }
}

final _authStateNotifier = AuthStateNotifier();

final routerProvider = Provider<GoRouter>((ref) {
  // Read initial auth state
  final authState = ref.watch(authProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  // Update the notifier
  _authStateNotifier.update(
    currentUser != null,
    authState.isLoading,
  );

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _authStateNotifier,
    redirect: (context, state) {
      // While auth is loading, don't redirect
      if (_authStateNotifier.isLoading) {
        return null;
      }
      
      // User is logged in if currentUser exists (from API auth or test mode)
      final isLoggedIn = _authStateNotifier.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) {
        return '/auth/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
            routes: [
              GoRoute(
                path: 'search',
                builder: (context, state) {
                  final query = state.uri.queryParameters['q'] ?? '';
                  final category = state.uri.queryParameters['category'];
                  return SearchScreen(query: query, categoryId: category);
                },
              ),
              GoRoute(
                path: 'contractor/:id',
                builder: (context, state) => ContractorProfileScreen(
                  contractorId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'service/:id',
                builder: (context, state) => ServiceDetailScreen(
                  serviceId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'help',
                builder: (context, state) => const HelpRequestScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookingsListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BookingDetailScreen(
                  bookingId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'bids',
                    builder: (context, state) => BidsScreen(
                      bookingId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (context, state) => ChatRoomScreen(
                  roomId: state.pathParameters['roomId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
            routes: [
              GoRoute(
                path: 'addresses',
                builder: (context, state) => const AddressesScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (outside bottom nav)
      GoRoute(
        path: '/booking/new',
        builder: (context, state) {
          final serviceId = state.uri.queryParameters['serviceId']!;
          final contractorId = state.uri.queryParameters['contractorId']!;
          return BookingFormScreen(
            serviceId: serviceId,
            contractorId: contractorId,
          );
        },
      ),
    ],
  );
});
