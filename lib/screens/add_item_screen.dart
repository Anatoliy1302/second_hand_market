import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class AddItemScreen extends StatefulWidget {
  final Item? existingItem;
  const AddItemScreen({super.key, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _depositCtrl;
  late String _category;
  late String _type;
  late List<String> _images;

  final List<String> _categories = ['Одежда', 'Электроника', 'Мебель', 'Детское', 'Спорт', 'Инструменты', 'Другое'];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _priceCtrl = TextEditingController(text: item?.price.toInt().toString() ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _phoneCtrl = TextEditingController(text: item?.phoneNumber ?? '');
    _depositCtrl = TextEditingController(text: item?.deposit?.toInt().toString() ?? '');
    _category = item?.category ?? 'Одежда';
    _type = item?.type ?? 'sale';
    _images = List<String>.from(item?.imagePaths ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage(maxWidth: 800);
      if (images.isNotEmpty) {
        setState(() => _images.addAll(images.map((e) => e.path)));
      }
    } catch (_) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (image != null) {
        setState(() => _images.add(image.path));
      }
    }
  }

  void _save() {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название обязательно'))
      );
      return;
    }

    if ((_type == 'sale' || _type == 'rent') && _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите цену'))
      );
      return;
    }

    final item = Item(
      id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text,
      price: _type == 'free' || _type == 'barter' ? 0 : double.parse(_priceCtrl.text),
      category: _category,
      imagePaths: _images,
      description: _descCtrl.text,
      sellerName: 'Я',
      location: 'м. Моя станция',
      phoneNumber: _phoneCtrl.text,
      sellerRating: 5.0,
      createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
      type: _type,
      deposit: _type == 'rent' ? (double.tryParse(_depositCtrl.text) ?? 0) : null,
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final bool edit = widget.existingItem != null;
    return Scaffold(
      appBar: AppBar(title: Text(edit ? 'Редактировать' : 'Новое объявление')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Фото
            Text('Фото:', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ...List.generate(_images.length, (i) => Stack(
                  key: ValueKey(_images[i]),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_images[i]), width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                )),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(child: Icon(Icons.add_a_photo, size: 28, color: Colors.grey)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Тип объявления
            Text('Тип объявления:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Продажа', style: TextStyle(fontSize: 13)),
                    value: 'sale',
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v!),
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Аренда', style: TextStyle(fontSize: 13)),
                    value: 'rent',
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v!),
                    dense: true,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Дарение', style: TextStyle(fontSize: 13)),
                    value: 'free',
                    groupValue: _type,
                    onChanged: (v) => setState(() {
                      _type = v!;
                      _priceCtrl.text = '0';
                    }),
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Обмен', style: TextStyle(fontSize: 13)),
                    value: 'barter',
                    groupValue: _type,
                    onChanged: (v) => setState(() {
                      _type = v!;
                      _priceCtrl.text = '0';
                    }),
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            
            // Цена
            if (_type == 'sale' || _type == 'rent') ...[
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _type == 'rent' ? 'Цена за день (₽) *' : 'Цена (₽) *',
                  border: const OutlineInputBorder(),
                  prefixText: '₽ ',
                ),
              ),
            ],
            
            // Залог для аренды
            if (_type == 'rent') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _depositCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Залог (₽)',
                  border: OutlineInputBorder(),
                  prefixText: '₽ ',
                ),
              ),
            ],
            
            // На что меняете для обмена
            if (_type == 'barter') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'На что меняете? *',
                  border: OutlineInputBorder(),
                  hintText: 'Например: на книги, инструменты...',
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            
            // Описание (для продажи/аренды/дарения)
            if (_type != 'barter') ...[
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                  hintText: 'Опишите товар...',
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Телефон',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Color(0xFFCB11AB)),
                  onPressed: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setString('my_phone', _phoneCtrl.text);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Сохранено'))
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF55123),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(edit ? 'Сохранить' : 'Опубликовать', style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}