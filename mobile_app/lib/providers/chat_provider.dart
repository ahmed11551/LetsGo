import 'package:flutter/foundation.dart';
import 'package:letsgo/services/chat_service.dart';
import 'package:letsgo/models/message.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentTripId;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentTripId => _currentTripId;

  void connectToChat(String tripId, String token) {
    _currentTripId = tripId;
    _chatService.connectToWebSocket(token, _handleNewMessage);
    _loadChatHistory(token);
  }

  void disconnectFromChat() {
    _chatService.disconnect();
    _currentTripId = null;
    _messages.clear();
    notifyListeners();
  }

  Future<void> _loadChatHistory(String token) async {
    if (_currentTripId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final history = await _chatService.getChatHistory(_currentTripId!, token);
      _messages.clear();
      _messages.addAll(history);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleNewMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> sendMessage(String content, String token) async {
    if (_currentTripId == null) return;

    try {
      _chatService.sendMessage(content, token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String messageId, String token) async {
    try {
      await _chatService.markAsRead(messageId, token);
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = Message(
          id: _messages[index].id,
          senderId: _messages[index].senderId,
          senderName: _messages[index].senderName,
          content: _messages[index].content,
          timestamp: _messages[index].timestamp,
          isRead: true,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 