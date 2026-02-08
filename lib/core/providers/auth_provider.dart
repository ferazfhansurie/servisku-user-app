import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/models.dart';

// Secure storage for persisting user data
const _storage = FlutterSecureStorage();

// Auth initialization provider - waits for auth to be restored from storage
final authInitProvider = FutureProvider<bool>((ref) async {
  final authNotifier = ref.read(authProvider.notifier);
  await authNotifier.initComplete;
  return true;
});

// Auth state provider - checks if user is authenticated via token
final authStateProvider = FutureProvider<bool>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.isAuthenticated();
});

// Current user state (for UI access)
final currentUserProvider = StateProvider<User?>((ref) => null);

// Current user profile from API
final userProfileProvider = FutureProvider<User?>((ref) async {
  final api = ref.read(apiClientProvider);
  final isAuthenticated = await api.isAuthenticated();
  if (!isAuthenticated) return null;

  try {
    final response = await api.getProfile();
    if (response['success'] == true) {
      final user = User.fromJson(response['data']);
      ref.read(currentUserProvider.notifier).state = user;
      return user;
    }
  } catch (e) {
    // User not registered yet or token expired
  }
  return null;
});

// Auth notifier provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

// Auth actions
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  late final Future<void> initComplete;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    initComplete = _init();
  }

  Future<void> _init() async {
    try {
      // First try to restore user from local storage
      final storedUser = await _storage.read(key: 'user_data');
      if (storedUser != null) {
        try {
          final userData = jsonDecode(storedUser);
          final user = User.fromJson(userData);
          _ref.read(currentUserProvider.notifier).state = user;
          state = AsyncValue.data(user);

          // Verify token is still valid by loading fresh profile
          final api = _ref.read(apiClientProvider);
          final isAuthenticated = await api.isAuthenticated();
          if (isAuthenticated) {
            try {
              await _loadProfile();
            } catch (e) {
              // Profile load failed but local user is still valid
            }
          }
          return;
        } catch (e) {
          // Invalid stored data, clear it
          await _storage.delete(key: 'user_data');
        }
      }

      // No stored user, check if token exists
      final api = _ref.read(apiClientProvider);
      final isAuthenticated = await api.isAuthenticated();

      if (isAuthenticated) {
        await _loadProfile();
      } else {
        state = const AsyncValue.data(null);
        _ref.read(currentUserProvider.notifier).state = null;
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      _ref.read(currentUserProvider.notifier).state = null;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.getProfile();
      final userData = response['data'] ?? response['user'];
      if (userData != null) {
        final user = User.fromJson(userData);
        _ref.read(currentUserProvider.notifier).state = user;
        state = AsyncValue.data(user);
        // Persist user data
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _persistUser(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_data', value: jsonEncode(userData));
  }

  Future<void> sendOtp(String phone) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.sendOtp(phone);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.verifyOtp(phone, otp);

      if (response['success'] == true && response['data'] != null) {
        final token = response['data']['token'];
        if (token != null) {
          await api.setToken(token);
        }

        // Check if user profile exists
        if (response['data']['user'] != null) {
          final user = User.fromJson(response['data']['user']);
          _ref.read(currentUserProvider.notifier).state = user;
          state = AsyncValue.data(user);
          return true; // User exists
        }
        return false; // User needs to register
      }
      throw Exception('Invalid OTP');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.login(email, password);

      if (response['success'] == true) {
        final token = response['token'];
        await api.setToken(token);

        // User is returned directly in the response
        if (response['user'] != null) {
          final user = User.fromJson(response['user']);
          _ref.read(currentUserProvider.notifier).state = user;
          state = AsyncValue.data(user);
          // Persist user data
          await _persistUser(response['user']);
        } else {
          await _loadProfile();
        }
      } else {
        throw Exception(response['error'] ?? 'Login failed');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.register({
        'email': email,
        'password': password,
        'full_name': name,
        if (phone != null) 'phone': phone,
        'role': 'user',
      });

      if (response['success'] == true) {
        if (response['token'] != null) {
          await api.setToken(response['token']);
        }
        if (response['user'] != null) {
          final user = User.fromJson(response['user']);
          _ref.read(currentUserProvider.notifier).state = user;
          state = AsyncValue.data(user);
          // Persist user data
          await _persistUser(response['user']);
        } else {
          await _loadProfile();
        }
      } else {
        throw Exception(response['error'] ?? 'Registration failed');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> registerWithPhone({
    required String phone,
    required String name,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.register({
        'phone': phone,
        'full_name': name,
        if (email != null) 'email': email,
        'role': 'user',
      });

      if (response['success'] == true) {
        if (response['data']['token'] != null) {
          await api.setToken(response['data']['token']);
        }
        await _loadProfile();
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.updateProfile({
        if (name != null) 'full_name': name,
        if (phone != null) 'phone': phone,
      });
      await _loadProfile();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ref.read(apiClientProvider).clearToken();
    await _storage.delete(key: 'user_data');
    state = const AsyncValue.data(null);
    _ref.read(currentUserProvider.notifier).state = null;
  }
}
