import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item.dart';
import '../models/message.dart';
import '../models/chat.dart';

class DetailScreen extends StatefulWidget {
  final Item item;
  final bool isMine;
  final Chat? existingChat;
  final Function(Item) onFavorite;
  final Function(Item) onEdit;
  final Function(Item) onDelete;
  final Function(Chat) onUpdateChat;
  final Function(String) onBlockUser;
  final Function(Item) onBlockDeposit;

  const DetailScreen({
    super.key,
    required this.item,
    required this.isMine,
    this.existingChat,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateChat,
    required this.onBlockUser,
    required this.onBlockDeposit,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Chat _chat;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ScrollController _mainScrollCtrl = ScrollController();
  bool _showChat = false;
  bool _isBooked = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingChat != null) {
      _chat = widget.existingChat!;
    } else {
      _chat = Chat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: widget.item.id,
        itemTitle: widget.item.title,
        itemImage: widget.item.imagePaths.isNotEmpty ? widget.item.imagePaths.first : '',
        participantName: widget.item.sellerName,
        participantPhone: widget.item.phoneNumber,
        messages: [],
        createdAt: DateTime.now(),
      );
    }
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
    widget.onUpdateChat(_chat);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final responses = ['Да, в наличии', 'Могу встретиться завтра', 'Хорошо, договорились!', 'Спасибо за предложение'];
      final autoMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responses[DateTime.now().millisecondsSinceEpoch % responses.length],
        isMine: false,
        isRead: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        _chat.messages.add(autoMessage);
        _chat.lastMessage = autoMessage.text;
        _chat.lastMessageTime = autoMessage.timestamp;
      });
      widget.onUpdateChat(_chat);
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showReviewDialog() {
    int rating = 5;
    final reviewCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Оцените продавца'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                  onPressed: () => setDialogState(() => rating = i + 1),
                )),
              ),
              const SizedBox(height: 12),
              TextField(controller: reviewCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Напишите отзыв...', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.item.reviews.add({'rating': rating, 'text': reviewCtrl.text, 'date': DateTime.now().toIso8601String()});
                double totalRating = 0;
                for (var review in widget.item.reviews) { totalRating += review['rating'] as int; }
                widget.item.sellerRating = widget.item.reviews.isEmpty ? 0 : totalRating / widget.item.reviews.length;
                widget.item.reviewCount = widget.item.reviews.length;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Спасибо за отзыв!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCB11AB), foregroundColor: Colors.white),
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintDialog() {
    String reason = 'Мошенничество';
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Пожаловаться на продавца'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Причина', border: OutlineInputBorder()),
                items: ['Мошенничество', 'Товар не соответствует', 'Не пришёл на встречу', 'Грубость', 'Другое'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setDialogState(() => reason = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Опишите ситуацию...', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Жалоба отправлена.'), backgroundColor: Colors.orange[700]));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _mainScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PageController pc = PageController();
    final grey200 = Colors.grey[200]!;
    final grey300 = Colors.grey[300]!;
    final grey400 = Colors.grey[400]!;
    final grey600 = Colors.grey[600]!;
    final grey700 = Colors.grey[700]!;
    final orange100 = Colors.orange[100]!;
    final red50 = Colors.red[50]!;
    final red200 = Colors.red[200]!;
    final green50 = Colors.green[50]!;
    final green200 = Colors.green[200]!;
    final grey50 = Colors.grey[50]!;
    final amber100 = Colors.amber[100]!;
    final pink100 = Colors.pink[100]!;

    return SingleChildScrollView(
      controller: _mainScrollCtrl,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.imagePaths.isNotEmpty)
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  PageView.builder(controller: pc, itemCount: widget.item.imagePaths.length, itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(widget.item.imagePaths[i]), width: double.infinity, fit: BoxFit.cover))),
                  if (widget.item.imagePaths.length > 1)
                    Positioned(bottom: 12, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.item.imagePaths.length, (i) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(shape: BoxShape.circle, color: i == 0 ? Colors.white : Colors.white54))))),
                ],
              ),
            ),
          if (widget.item.imagePaths.isEmpty) Container(height: 200, decoration: BoxDecoration(color: grey200, borderRadius: BorderRadius.circular(16)), child: Center(child: Icon(Icons.image, size: 80, color: grey400))),
          const SizedBox(height: 16),
          if (widget.item.type == 'free') const Text('Отдам даром', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green))
          else if (widget.item.type == 'barter') Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Обмен', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)), if (widget.item.description.isNotEmpty) Text('На: ${widget.item.description}', style: const TextStyle(fontSize: 16, color: Colors.blueGrey))])
          else ...[
            Text('${NumberFormat('#,###').format(widget.item.price.toInt())} ${widget.item.priceLabel}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFCB11AB))),
            if (widget.item.type == 'rent') Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: orange100, borderRadius: BorderRadius.circular(8)), child: Text('Аренда • ${widget.item.depositLabel}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500))),
          ],
          Text(widget.item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [CircleAvatar(backgroundColor: const Color(0xFFCB11AB).withAlpha(30), child: Text(widget.item.sellerName[0])), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.item.sellerName, style: const TextStyle(fontWeight: FontWeight.w600)), Text(widget.item.location, style: TextStyle(color: grey600, fontSize: 13))])]),
          const SizedBox(height: 12),
          Row(children: [const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 4), Text(widget.item.reviewCount > 0 ? '${widget.item.sellerRating.toStringAsFixed(1)} (${widget.item.reviewCount} отзывов)' : 'Нет отзывов', style: TextStyle(color: grey700))]),
          if (widget.item.sellerRating < 3 && widget.item.reviewCount > 0) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: red50, borderRadius: BorderRadius.circular(8), border: Border.all(color: red200)), child: const Row(children: [Icon(Icons.warning, color: Colors.red, size: 18), SizedBox(width: 8), Text('Низкий рейтинг продавца', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500))])),
          if (widget.item.description.isNotEmpty && widget.item.type != 'barter') ...[const SizedBox(height: 16), const Text('Описание', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 8), Text(widget.item.description, style: TextStyle(color: grey700))],
          const SizedBox(height: 16),
          if (widget.isMine)
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); widget.onEdit(widget.item); }, icon: const Icon(Icons.edit), label: const Text('Редактировать'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: () { showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Удалить?'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')), TextButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); widget.onDelete(widget.item); }, child: const Text('Удалить', style: TextStyle(color: Colors.red)))])); }, icon: const Icon(Icons.delete), label: const Text('Удалить'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
            ]),
          if (!widget.isMine) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _showChat = !_showChat);
                if (_showChat) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_mainScrollCtrl.hasClients) { _mainScrollCtrl.animateTo(_mainScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut); }
                  });
                }
              },
              icon: Icon(_showChat ? Icons.close : Icons.chat),
              label: Text(_showChat ? 'Закрыть чат' : 'Написать в чат'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCB11AB), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${widget.item.phoneNumber}')),
              icon: const Icon(Icons.phone),
              label: const Text('Позвонить'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
            ),
            if (widget.item.type == 'rent') ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isBooked ? null : () { setState(() => _isBooked = true); widget.onBlockDeposit(widget.item); },
                icon: Icon(_isBooked ? Icons.check_circle : Icons.lock),
                label: Text(_isBooked ? 'Забронировано' : 'Забронировать (залог ${widget.item.deposit?.toInt() ?? 0} ₽)'),
                style: ElevatedButton.styleFrom(backgroundColor: _isBooked ? Colors.grey[400] : Colors.deepPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
              ),
              if (_isBooked) ...[
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: green50, borderRadius: BorderRadius.circular(8), border: Border.all(color: green200)), child: const Row(children: [Icon(Icons.info, color: Colors.green, size: 20), SizedBox(width: 8), Expanded(child: Text('Продавец уведомлён. Ожидайте ответа.', style: TextStyle(fontSize: 13, color: Colors.green)))]))
              ],
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () => widget.onFavorite(widget.item), icon: Icon(widget.item.isFavorite ? Icons.favorite : Icons.favorite_border), label: Text(widget.item.isFavorite ? 'В избранном' : 'В избранное'), style: ElevatedButton.styleFrom(backgroundColor: widget.item.isFavorite ? Colors.red[50] : Colors.grey[100], foregroundColor: widget.item.isFavorite ? Colors.red : Colors.grey[700])),
            TextButton.icon(onPressed: _showComplaintDialog, icon: const Icon(Icons.flag, size: 16, color: Colors.red), label: const Text('Пожаловаться', style: TextStyle(color: Colors.red, fontSize: 13))),
            TextButton.icon(
              onPressed: () {
                showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Заблокировать продавца?'), content: const Text('Вы больше не увидите объявления.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); widget.onBlockUser(widget.item.sellerName); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Продавец заблокирован'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Заблокировать'))]));
              },
              icon: const Icon(Icons.block, size: 16, color: Colors.red),
              label: const Text('Заблокировать', style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
          if (_showChat && !widget.isMine) ...[
            const SizedBox(height: 16), const Divider(), const Text('Чат с продавцом', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 8),
            Container(
              height: 300, decoration: BoxDecoration(color: grey50, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Expanded(child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(8), itemCount: _chat.messages.length, itemBuilder: (_, i) { final msg = _chat.messages[i]; return Align(alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6), decoration: BoxDecoration(color: msg.isMine ? const Color(0xFFCB11AB) : Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(msg.text, style: TextStyle(color: msg.isMine ? Colors.white : Colors.black87, fontSize: 14)), const SizedBox(height: 4), Text(DateFormat('HH:mm').format(msg.timestamp), style: TextStyle(color: msg.isMine ? Colors.white70 : Colors.grey, fontSize: 10))]))); })),
                Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: 'Сообщение...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), onSubmitted: (_) => _sendMessage())), const SizedBox(width: 8), CircleAvatar(backgroundColor: const Color(0xFFCB11AB), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _sendMessage))])),
              ]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _showReviewDialog, icon: const Icon(Icons.star, color: Colors.amber), label: const Text('Завершить сделку и оценить'), style: ElevatedButton.styleFrom(backgroundColor: amber100, foregroundColor: Colors.black87)),
          ],
        ],
      ),
    );
  }
}