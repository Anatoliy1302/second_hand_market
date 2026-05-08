import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/item.dart';

class MapScreen extends StatefulWidget {
  final List<Item> items;
  const MapScreen({super.key, required this.items});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(55.7558, 37.6173);
  LatLng? _myLocation;
  List<Marker> _markers = [];
  bool _searchMode = false;
  double _radiusKm = 3.0;
  List<Item> _nearbyItems = [];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _requestLocation();
    _updateMarkers();
  }

  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Включите GPS в настройках телефона')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Разрешите доступ к геолокации')),
            );
          }
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _myLocation = _center;
      });
      _mapController.move(_center, 14.0);
      _updateMarkers();
    } catch (e) {
      // Остаёмся в Москве
    }
  }

  void _updateMarkers() {
    final markers = <Marker>[];

    if (_myLocation != null) {
      markers.add(
        Marker(
          point: _myLocation!,
          width: 40, height: 40,
          child: Container(
            decoration: BoxDecoration(color: Colors.blue.withAlpha(80), shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 3)),
            child: const Center(child: Icon(Icons.circle, color: Colors.blue, size: 12)),
          ),
        ),
      );
    }

    for (final item in _nearbyItems.isNotEmpty ? _nearbyItems : widget.items) {
      final lat = _center.latitude + (item.id.hashCode % 100 - 50) * 0.002;
      final lng = _center.longitude + ((item.id.hashCode >> 8) % 100 - 50) * 0.002;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 80, height: 80,
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} — ${item.price.toInt()} ₽'))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFCB11AB), borderRadius: BorderRadius.circular(6)),
                  child: Text('${item.price.toInt()} ₽', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.location_on, color: Color(0xFFCB11AB), size: 30),
              ],
            ),
          ),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _searchNearby() {
    if (_myLocation == null) return;
    final distance = Distance();
    final nearby = <Item>[];
    for (final item in widget.items) {
      final itemLat = _center.latitude + (item.id.hashCode % 100 - 50) * 0.002;
      final itemLng = _center.longitude + ((item.id.hashCode >> 8) % 100 - 50) * 0.002;
      final km = distance.as(LengthUnit.Kilometer, _myLocation!, LatLng(itemLat, itemLng));
      if (km <= _radiusKm) nearby.add(item);
    }
    setState(() { _nearbyItems = nearby; _searchMode = true; });
    _updateMarkers();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Найдено ${nearby.length} товаров в радиусе ${_radiusKm.toStringAsFixed(0)} км')));
  }

  void _clearSearch() {
    setState(() { _nearbyItems = []; _searchMode = false; });
    _updateMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта объявлений'), backgroundColor: const Color(0xFFCB11AB), actions: [
        IconButton(icon: Icon(_searchMode ? Icons.close : Icons.search), onPressed: _searchMode ? _clearSearch : _showRadiusDialog),
      ]),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _center, initialZoom: 12.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.second_hand_market'),
            MarkerLayer(markers: _markers),
          ],
        ),
        if (_searchMode)
          Positioned(bottom: 80, left: 16, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Радиус: ${_radiusKm.toStringAsFixed(0)} км', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Товаров: ${_nearbyItems.length}', style: const TextStyle(color: Color(0xFFCB11AB))),
            TextButton(onPressed: _showRadiusDialog, child: const Text('Изменить радиус')),
          ]))),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCB11AB), child: const Icon(Icons.my_location),
        onPressed: () async {
          try {
            final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            setState(() { _center = LatLng(pos.latitude, pos.longitude); _myLocation = _center; });
            _mapController.move(_center, 14.0);
            _updateMarkers();
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось определить местоположение')));
          }
        },
      ),
    );
  }

  void _showRadiusDialog() {
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: const Text('Радиус поиска'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${_radiusKm.toStringAsFixed(0)} км'),
        Slider(value: _radiusKm, min: 0.5, max: 20, divisions: 39, activeColor: const Color(0xFFCB11AB), label: '${_radiusKm.toStringAsFixed(0)} км', onChanged: (v) => setDialogState(() => _radiusKm = v)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); _searchNearby(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCB11AB), foregroundColor: Colors.white), child: const Text('Поиск')),
      ],
    )));
  }
}