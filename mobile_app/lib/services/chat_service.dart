import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:letsgo/models/message.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:8000/api/chat';
  WebSocketChannel? _channel;

  void connectToWebSocket(String token, Function(Message) onMessage) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/chat?token=$token'),
    );

    _channel!.stream.listen(
      (message) {
        final data = json.decode(message);
        onMessage(Message.fromJson(data));
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void sendMessage(String content, String token) {
    if (_channel != null) {
      _channel!.sink.add(json.encode({
        'content': content,
        'token': token,
      }));
    }
  }

  Future<List<Message>> getChatHistory(String tripId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/history/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении истории чата');
    }
  }

  Future<void> markAsRead(String messageId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/read/$messageId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при отметке сообщения как прочитанного');
    }
  }
} 