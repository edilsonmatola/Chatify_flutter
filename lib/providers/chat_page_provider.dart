import 'dart:async';

// Packages
import 'package:chatifyapp/models/chat_message_model.dart';
import 'package:chatifyapp/models/chats_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

// Services
import '../services/database_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/media_service.dart';
import '../services/navigation_service.dart';

// Providers
import '../providers/authentication_provider.dart';

// Models
import '../models/chat_user_model.dart';

class ChatPageProvider extends ChangeNotifier {
  ChatPageProvider(this._chatId, this._auth, this._messagesListViewController) {
    _database = GetIt.instance.get<DatabaseService>();
    _storage = GetIt.instance.get<CloudStorageService>();
    _navigation = GetIt.instance.get<NavigationService>();
    listenToMessages();
  }

  late DatabaseService _database;
  late CloudStorageService _storage;
  late MediaService _media;
  late NavigationService _navigation;

  AuthenticationProvider _auth;
  ScrollController _messagesListViewController;

  String _chatId;
  List<ChatMessage>? messages;

  late StreamSubscription _messagesStream;

  String? _message;

  String get message => _message as String;

  @override
  void dispose() {
    _messagesStream.cancel();
    super.dispose();
  }

  void listenToMessages() {
    try {
      _messagesStream = _database.streamMessagesForChatPage(_chatId).listen(
        (_snapshot) {
          List<ChatMessage> _messages = _snapshot.docs.map(
            (_message) {
              final messageData = _message.data() as Map<String, dynamic>;
              return ChatMessage.fromJSON(messageData);
            },
          ).toList();
          messages = _messages;
          notifyListeners();
        },
      );
    } catch (error) {
      debugPrint('$error');
    }
  }

  //* =============== Media Type messages =======================

  // * TEXT messages
  void sendTextMessage() {
    if (_message != null) {
      final _messageToSend = ChatMessage(
        senderID: _auth.user.uid,
        type: MessageType.text,
        content: _message!,
        sentTime: DateTime.now(),
      );
      _database.addMessagesToChat(_chatId, _messageToSend);
    }
  }

  // * IMAGE messages
  void sendImageMessage() async {
    try {
      final _file = await _media.pickImageFromLibrary();
      if (_file != null) {
        final downloadUrl = await _storage.saveChatImageToStorage(
          _chatId,
          _auth.user.uid,
          _file,
        );
        final _messageToSend = ChatMessage(
          senderID: _auth.user.uid,
          type: MessageType.image,
          content: downloadUrl!,
          sentTime: DateTime.now(),
        );
        _database.addMessagesToChat(_chatId, _messageToSend);
      }
    } catch (error) {
      debugPrint('$error');
    }
  }

  //* Delete chats
  void deleteChat() {
    goBack();
    _database.deleteChat(_chatId);
  }

  void goBack() {
    _navigation.goBack();
  }
}
