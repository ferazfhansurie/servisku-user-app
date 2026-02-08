import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api/api_client.dart';
import '../models/models.dart';

// Chat rooms list
final chatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.getChatRooms();
    print('Chat rooms response: $response');
    if (response['success'] == true) {
      final data = response['rooms'] ?? response['data'] ?? [];
      print('Chat rooms data: $data');
      return (data as List).map((e) => ChatRoom.fromJson(e)).toList();
    }
  } catch (e) {
    print('Error fetching chat rooms: $e');
    rethrow; // Rethrow so the UI can show the error
  }
  return [];
});

// Single chat room detail
final chatRoomDetailProvider =
    FutureProvider.family<ChatRoom?, String>((ref, roomId) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.getChatRoom(roomId);
    if (response['success'] == true) {
      final data = response['room'] ?? response['data'];
      if (data != null) return ChatRoom.fromJson(data);
    }
  } catch (e) {
    // Return null on error
  }
  return null;
});

// Messages for a room
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, roomId) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.getChatMessages(roomId);
    if (response['success'] == true) {
      final data = response['messages'] ?? response['data'] ?? [];
      return (data as List).map((e) => ChatMessage.fromJson(e)).toList();
    }
  } catch (e) {
    // Return empty list on error
  }
  return [];
});

// Chat Actions Notifier
final chatActionsProvider =
    StateNotifierProvider<ChatActionsNotifier, AsyncValue<void>>((ref) {
  return ChatActionsNotifier(ref);
});

class ChatActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  io.Socket? _socket;

  ChatActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  void connectSocket() {
    _socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.on('new_message', (data) {
      _ref.invalidate(chatMessagesProvider(data['room_id']));
      _ref.invalidate(chatRoomsProvider);
    });
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'room_id': roomId});
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', {'room_id': roomId});
  }

  /// Start or find existing chat with a contractor
  Future<String?> startChat(String contractorId, {String? serviceId}) async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.startChat(contractorId, serviceId: serviceId);
      if (response['success'] == true && response['room'] != null) {
        _ref.invalidate(chatRoomsProvider);
        return response['room']['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendMessage(String roomId, String content) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.sendMessage(roomId, content);
      _ref.invalidate(chatMessagesProvider(roomId));
      _ref.invalidate(chatRoomsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String roomId) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.put('/chat/rooms/$roomId/read');
      _ref.invalidate(chatRoomsProvider);
    } catch (e) {
      // Silent fail
    }
  }
}

// Unread chat count
final unreadChatCountProvider = Provider<int>((ref) {
  final rooms = ref.watch(chatRoomsProvider);
  return rooms.maybeWhen(
    data: (data) => data.fold(0, (sum, room) => sum + room.unreadCount),
    orElse: () => 0,
  );
});
