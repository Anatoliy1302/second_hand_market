import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat.dart';
import '../models/message.dart';

class MessagesListScreen extends StatefulWidget {
  final List<Chat> chats;
  final Function(Chat) onUpdateChat;
  final Function(Chat) onDeleteChat;

  const MessagesListScreen({
    super.key,
    required this.chats,
    required this.onUpdateChat,
    required this.onDeleteChat,
  });

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  Chat? _selectedChat;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty || _selectedChat == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _msgCtrl.text.trim(),
      isMine: true,
      isRead: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _selectedChat!.messages.add(message);
      _selectedChat!.lastMessage = message.text;
      _selectedChat!.lastMessageTime = message.timestamp;
    });

    _msgCtrl.clear();
    widget.onUpdateChat(_selectedChat!);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _selectedChat == null) return;
      final responses = ['Да, в наличии', 'Договорились', 'Отлично!', 'Скоро'];
      final autoMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responses[DateTime.now().millisecondsSinceEpoch % responses.length],
        isMine: false,
        isRead: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        _selectedChat!.messages.add(autoMessage);
        _selectedChat!.lastMessage = autoMessage.text;
        _selectedChat!.lastMessageTime = autoMessage.timestamp;
      });
      widget.onUpdateChat(_selectedChat!);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedChat != null ? _selectedChat!.participantName : 'Сообщения'),
        leading: _selectedChat != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedChat = null),
              )
            : null,
      ),
      body: _selectedChat != null
          ? _buildChatView()
          : widget.chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Нет сообщений', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.chats.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final chat = widget.chats[index];
                    final unreadCount = chat.messages.where((m) => !m.isRead && !m.isMine).length;

                    return Dismissible(
                      key: Key(chat.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => widget.onDeleteChat(chat),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFCB11AB).withAlpha(30),
                                child: Text(chat.participantName[0], style: const TextStyle(color: Color(0xFFCB11AB), fontWeight: FontWeight.bold)),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0, top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(chat.participantName, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text(chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Нет сообщений', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(_formatTime(chat.lastMessageTime), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          onTap: () {
                            for (var msg in chat.messages) {
                              msg.isRead = true;
                            }
                            setState(() => _selectedChat = chat);
                            widget.onUpdateChat(chat);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        if (_selectedChat!.itemTitle.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(children: [
              const Icon(Icons.shopping_bag, color: Color(0xFFCB11AB)),
              const SizedBox(width: 8),
              Text(_selectedChat!.itemTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: _selectedChat!.messages.length,
            itemBuilder: (_, i) {
              final msg = _selectedChat!.messages[i];
              return Align(
                alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: msg.isMine ? const Color(0xFFCB11AB) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.text, style: TextStyle(color: msg.isMine ? Colors.white : Colors.black87, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(DateFormat('HH:mm').format(msg.timestamp), style: TextStyle(color: msg.isMine ? Colors.white70 : Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, -2))]),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 4, minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFCB11AB),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return DateFormat('HH:mm').format(time);
    if (diff.inDays == 1) return 'вчера';
    return DateFormat('dd.MM').format(time);
  }
}