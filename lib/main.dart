import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'models/item.dart';
import 'models/chat.dart';
import 'models/booking.dart';
import 'screens/messages_list_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/add_item_screen.dart';
import 'models/message.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => runApp(MarketApp()));
}

class MarketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Hand Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFCB11AB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCB11AB),
          primary: const Color(0xFFCB11AB),
          secondary: const Color(0xFFF55123),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFCB11AB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  TabController? _tab;
  List<Item> items = [];
  List<Item> favs = [];
  List<Chat> chats = [];
  List<String> blockedUsers = [];
  List<Booking> bookings = [];
  double walletBalance = 50000;
  final TextEditingController _searchCtrl = TextEditingController();
  String _cat = 'Все';
  String _query = '';
  int _tabIdx = 0;
  bool _loading = true;
  int _unreadCount = 0;
  bool _initialized = false;

  final List<String> cats = ['Все', 'Бесплатно', 'Одежда', 'Электроника', 'Мебель', 'Детское', 'Спорт', 'Другое'];

  final List<Map<String, dynamic>> mock = [
    {'t': 'Велосипед Stels', 'p': 15000, 'c': 'Спорт', 'd': 'Отличный горный велосипед.', 's': 'Андрей', 'l': 'м. Тверская', 'ph': '+79001234567', 'r': 4.5},
    {'t': 'iPhone 12 64GB', 'p': 35000, 'c': 'Электроника', 'd': 'Телефон в отличном состоянии.', 's': 'Марина', 'l': 'м. Пушкинская', 'ph': '+79007654321', 'r': 4.8},
    {'t': 'Диван угловой', 'p': 22000, 'c': 'Мебель', 'd': 'Угловой диван, раскладной.', 's': 'Игорь', 'l': 'м. Юго-Западная', 'ph': '+79001112233', 'r': 4.0},
    {'t': 'Куртка Zara', 'p': 5000, 'c': 'Одежда', 'd': 'Зимняя куртка, размер M.', 's': 'Ольга', 'l': 'м. Белорусская', 'ph': '+79005554433', 'r': 3.5},
    {'t': 'Коляска детская', 'p': 12000, 'c': 'Детское', 'd': 'Коляска 2 в 1.', 's': 'Екатерина', 'l': 'м. Алтуфьево', 'ph': '+79005556677', 'r': 5.0},
    {'t': 'Настольная лампа', 'p': 1500, 'c': 'Другое', 'd': 'Лампа в стиле лофт.', 's': 'Дмитрий', 'l': 'м. Новослободская', 'ph': '+79009876543', 'r': 4.2},
    {'t': 'Дрель Bosch', 'p': 800, 'c': 'Инструменты', 'd': 'Мощная дрель в отличном состоянии.', 's': 'Сергей', 'l': 'м. Арбатская', 'ph': '+79003334455', 'r': 4.7},
    {'t': 'Палатка 4-местная', 'p': 1200, 'c': 'Спорт', 'd': 'Палатка для кемпинга.', 's': 'Анна', 'l': 'м. Сокольники', 'ph': '+79007778899', 'r': 4.9},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() async {
    final p = await SharedPreferences.getInstance();
    final ij = null;
    final fj = null;
    final cj = null;
    final bl = null;
    final bj = null;
    final wb = null;

    if (ij != null) {
      items = List<Item>.from(jsonDecode(ij).map((j) => Item.fromJson(j)));
    } else {
      items = [];
      for (int i = 0; i < mock.length; i++) {
        final d = mock[i];
        String type = 'sale';
        double? deposit;
        
        if (i == 2 || i == 6) { 
          type = 'rent'; 
          deposit = 3000; 
        }
        if (i == 4) { type = 'free'; }
        if (i == 5) { type = 'barter'; }
        
        items.add(Item(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          title: d['t'] as String,
          price: (d['p'] as int).toDouble(),
          category: d['c'] as String,
          imagePaths: [],
          description: d['d'] as String,
          sellerName: d['s'] as String,
          location: d['l'] as String,
          phoneNumber: d['ph'] as String,
          sellerRating: (d['r'] as num).toDouble(),
          createdAt: DateTime.now(),
          type: type,
          deposit: deposit,
        ));
      }
    }

    if (fj != null) {
      favs = List<Item>.from(jsonDecode(fj).map((j) => Item.fromJson(j)));
    }

    if (cj != null) {
      chats = List<Chat>.from(jsonDecode(cj).map((j) => Chat.fromJson(j)));
    }

    if (bl != null) {
      blockedUsers = List<String>.from(jsonDecode(bl));
    }

    if (bj != null) {
      bookings = List<Booking>.from(jsonDecode(bj).map((j) => Booking.fromJson(j)));
    }

        if (wb != null) {
      walletBalance = wb;
    }

    _updateUnreadCount();
    if (mounted) setState(() => _loading = false);
  }

  void _updateUnreadCount() {
    int count = 0;
    for (var chat in chats) {
      count += chat.messages.where((m) => !m.isRead && !m.isMine).length;
    }
    _unreadCount = count;
  }

  Future<void> _saveItems() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('items', jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  Future<void> _saveFavorites() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('favorites', jsonEncode(favs.map((i) => i.toJson()).toList()));
  }

  Future<void> _saveChats() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('chats', jsonEncode(chats.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveBlocked() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('blocked_users', jsonEncode(blockedUsers));
  }

  Future<void> _saveBookings() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('bookings', jsonEncode(bookings.map((b) => b.toJson()).toList()));
  }

  Future<void> _saveWallet() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('wallet_balance', walletBalance);
  }

  void _blockUser(String userName) {
    setState(() {
      blockedUsers.add(userName);
      items.removeWhere((i) => i.sellerName == userName);
      favs.removeWhere((i) => i.sellerName == userName);
    });
    _saveBlocked();
    _saveItems();
    _saveFavorites();
  }

  void _blockDeposit(Item item) {
    if (item.deposit == null || item.deposit! > walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств для залога')),
      );
      return;
    }

    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: item.id,
      itemTitle: item.title,
      renterName: 'Я',
      ownerName: item.sellerName,
      depositAmount: item.deposit!,
      depositBlocked: true,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    setState(() {
      bookings.insert(0, booking);
      walletBalance -= item.deposit!;
    });

    _saveBookings();
    _saveWallet();

    // Отправляем авто-сообщение продавцу в чат
    Chat? chat;
    for (var c in chats) {
      if (c.itemId == item.id && c.participantName == item.sellerName) {
        chat = c;
        break;
      }
    }
    
    if (chat == null) {
      chat = Chat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: item.id, itemTitle: item.title,
        itemImage: item.imagePaths.isNotEmpty ? item.imagePaths.first : '',
        participantName: item.sellerName,
        participantPhone: item.phoneNumber,
        messages: [], createdAt: DateTime.now(),
      );
      chats.insert(0, chat);
    }
    
    chat.messages.add(Message(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  text: 'Здравствуйте! Я забронировал(а) ваш товар "${item.title}". Залог ${item.deposit!.toInt()} ₽ заблокирован.',
  isMine: true,
  isRead: false,
  timestamp: DateTime.now(),
));
    chat.lastMessage = chat.messages.last.text;
    chat.lastMessageTime = DateTime.now();
    _saveChats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Залог ${item.deposit!.toInt()} ₽ заблокирован. Продавец уведомлён.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _fav(Item i) {
    setState(() {
      i.isFavorite = !i.isFavorite;
      if (i.isFavorite) { favs.add(i); } else { favs.removeWhere((x) => x.id == i.id); }
    });
    _saveFavorites();
  }

  void _add(Item i) {
    setState(() => items.insert(0, i));
    _saveItems();
  }

  void _upd(Item old, Item n) {
    setState(() {
      final idx = items.indexWhere((x) => x.id == old.id);
      if (idx != -1) { n.isFavorite = old.isFavorite; items[idx] = n; }
      final fi = favs.indexWhere((x) => x.id == old.id);
      if (fi != -1) favs[fi] = n;
    });
    _saveItems();
    _saveFavorites();
  }

  void _del(Item i) {
    setState(() {
      items.removeWhere((x) => x.id == i.id);
      favs.removeWhere((x) => x.id == i.id);
    });
    _saveItems();
    _saveFavorites();
  }

  List<Item> _filtered() {
    List<Item> src = _tabIdx == 0 ? items : _tabIdx == 1 ? favs : items.where((i) => i.sellerName == 'Я').toList();
    src = src.where((i) => !blockedUsers.contains(i.sellerName)).toList();
    
    if (_cat == 'Бесплатно') {
      return src.where((i) => 
        (i.type == 'free' || i.type == 'barter') &&
        (_query.isEmpty || i.title.toLowerCase().contains(_query.toLowerCase()))
      ).toList();
    }
    
    return src.where((i) =>
        (_cat == 'Все' || i.category == _cat) &&
        (_query.isEmpty || i.title.toLowerCase().contains(_query.toLowerCase()))).toList();
  }

  void _showMessagesList() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MessagesListScreen(
        chats: chats,
        onUpdateChat: (chat) {
          final idx = chats.indexWhere((c) => c.id == chat.id);
          if (idx != -1) { chats[idx] = chat; } else { chats.insert(0, chat); }
          _updateUnreadCount();
          _saveChats();
          if (mounted) setState(() {});
        },
        onDeleteChat: (chat) {
          setState(() { chats.removeWhere((c) => c.id == chat.id); _updateUnreadCount(); });
          _saveChats();
        },
      ),
    )).then((_) {
      if (mounted) { _updateUnreadCount(); _saveChats(); setState(() {}); }
    });
  }

  void _showAdd() async {
    final result = await Navigator.push<Item>(context, MaterialPageRoute(
      builder: (_) => const AddItemScreen(),
    ));
    if (result != null) _add(result);
  }

  void _showEdit(Item item) async {
    final result = await Navigator.push<Item>(context, MaterialPageRoute(
      builder: (_) => AddItemScreen(existingItem: item),
    ));
    if (result != null) _upd(item, result);
  }

  void _showDetail(Item item) {
    Chat? existingChat;
    for (var chat in chats) {
      if (chat.itemId == item.id && chat.participantName == item.sellerName) {
        existingChat = chat;
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(item.title),
            backgroundColor: const Color(0xFFCB11AB),
            foregroundColor: Colors.white,
          ),
          body: DetailScreen(
            item: item,
            isMine: item.sellerName == 'Я',
            existingChat: existingChat,
            onFavorite: (it) => _fav(it),
            onEdit: (it) {
              Navigator.pop(context);
              _showEdit(it);
            },
            onDelete: (it) {
              Navigator.pop(context);
              _del(it);
            },
            onUpdateChat: (chat) {
              final idx = chats.indexWhere((c) => c.id == chat.id);
              if (idx != -1) { chats[idx] = chat; } else { chats.insert(0, chat); }
              _saveChats();
            },
            onBlockUser: (userName) {
              Navigator.pop(context);
              _blockUser(userName);
            },
            onBlockDeposit: (it) => _blockDeposit(it),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }

    _updateUnreadCount();
    final f = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Hand Market', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${walletBalance.toInt()} ₽',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.message), onPressed: _showMessagesList),
              if (_unreadCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(_unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (idx) => setState(() => _tabIdx = idx),
          tabs: const [
            Tab(text: 'Товары'),
            Tab(text: 'Избранное'),
            Tab(text: 'Мои'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final cat = cats[i];
                final isFree = cat == 'Бесплатно';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFree) const Icon(Icons.card_giftcard, size: 16),
                        if (isFree) const SizedBox(width: 4),
                        Text(cat),
                      ],
                    ),
                    selected: _cat == cat,
                    onSelected: (_) => setState(() => _cat = cat),
                    selectedColor: isFree ? Colors.green[100] : Colors.pink[100],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : f.isEmpty
                    ? Center(child: Text('Ничего не найдено', style: TextStyle(fontSize: 18, color: Colors.grey[600])))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 0.7,
                          crossAxisSpacing: 8, mainAxisSpacing: 8,
                        ),
                        itemCount: f.length,
                        itemBuilder: (_, i) {
                          final it = f[i];
                          return GestureDetector(
                            onTap: () => _showDetail(it),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: it.imagePaths.isNotEmpty
                                          ? Image.file(File(it.imagePaths.first), width: double.infinity, fit: BoxFit.cover, cacheWidth: 300)
                                          : Container(color: Colors.grey[300], child: Center(child: Icon(Icons.image, size: 50, color: Colors.grey[500]))),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (it.type == 'free')
                                              const Text('Отдам даром', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14))
                                            else if (it.type == 'barter')
                                              const Text('Обмен', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14))
                                            else
                                              Text('${NumberFormat('#,###').format(it.price.toInt())} ${it.priceLabel}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCB11AB), fontSize: 14)),
                                            if (it.type == 'rent') ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                                                child: const Text('Аренда', style: TextStyle(fontSize: 9, color: Colors.orange)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 12),
                                            const SizedBox(width: 2),
                                            Text(
                                              it.reviewCount > 0 ? '${it.sellerRating.toStringAsFixed(1)} (${it.reviewCount})' : 'Нет отзывов',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        backgroundColor: const Color(0xFFF55123),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}