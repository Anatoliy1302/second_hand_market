import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message.dart';
import '../models/chat.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final Function(Chat) onUpdate;

  const ChatScreen({super.key, required this.chat, required this.onUpdate});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late Chat _chat;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    for (var msg in _chat.messages) {
      msg.isRead = true;
    }
    widget.onUpdate(_chat);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _msgCtrl.text.trim(),
      isMine: true,
      isRead: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _chat.messages.add(message);
      _chat.lastMessage = message.text;
      _chat.lastMessageTime = message.timestamp;
    });

    _msgCtrl.clear();
    widget.onUpdate(_chat);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    Future.delayed(Duration(seconds: 1 + DateTime.now().millisecondsSinceEpoch % 3), () {
      if (!mounted) return;
      _simulateResponse();
    });
  }

  void _simulateResponse() {
    final responses = [
      'Да, товар ещё в наличии',
      'Могу встретиться завтра у метро',
      'Цена окончательная',
      'Хорошо, договорились!',
      'Напишите в течение дня',
      'Отличное состояние, всё работает',
      'Могу скинуть ещё фото',
      'Спасибо за предложение',
    ];

    final randomResponse = responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: randomResponse,
      isMine: false,
      isRead: true,
      timestamp: DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _chat.messages.add(message);
      _chat.lastMessage = message.text;
      _chat.lastMessageTime = message.timestamp;
    });

    widget.onUpdate(_chat);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(
                _chat.participantName[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chat.participantName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (_chat.itemTitle.isNotEmpty)
                    Text(
                      _chat.itemTitle,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => launchUrl(Uri.parse('tel:${_chat.participantPhone}')),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_chat.itemTitle.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _chat.itemImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_chat.itemImage),
                              fit: BoxFit.cover,
                              cacheWidth: 100,
                            ),
                          )
                        : Icon(Icons.shopping_bag, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _chat.itemTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _chat.messages.length,
              itemBuilder: (context, index) {
                final msg = _chat.messages[index];
                final isMine = msg.isMine;

                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMine ? const Color(0xFFCB11AB) : Colors.white,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isMine ? const Radius.circular(4) : null,
                        bottomLeft: !isMine ? const Radius.circular(4) : null,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(msg.timestamp),
                              style: TextStyle(
                                color: isMine ? Colors.white70 : Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              Icon(
                                msg.isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: msg.isRead ? Colors.white : Colors.white60,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFCB11AB),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}