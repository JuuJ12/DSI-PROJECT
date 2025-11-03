// Mapa com filtros usando Google Maps + Places API
// Coloque este arquivo em: lib/features/mapa_diabetes/widgets/mapa_google_filters.dart
// Requisitos no pubspec.yaml:
//   google_maps_flutter: ^2.x
//   http: ^1.x
//   geolocator: ^14.x
// IMPORTANTE: A chave abaixo foi fornecida por você. Por segurança, prefira carregar a
// chave a partir de `local.properties` ou de variáveis de ambiente em produção.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// A chave API será carregada via MethodChannel a partir da configuração
/// nativa (Android meta-data MAPS_API_KEY ou iOS Info.plist GMSApiKey).
/// Não mantenha chaves sensíveis no código-fonte.
String? _kGoogleApiKey;

/// Centro aproximado de Pernambuco (Recife)
/// Note: LatLng constructor is not const, so keep this as `final` to avoid
/// a compile-time error when the Google Maps types are available.
final LatLng kPernambucoCenter = LatLng(-8.0476, -34.8770);

/// Raio de busca padrão em metros (ajuste para reduzir custos)
const int kDefaultRadius = 25000; // 25 km

/// TTL do cache em minutos
const int kCacheMinutes = 10;

class GooglePlacesFilterMap extends StatefulWidget {
  const GooglePlacesFilterMap({super.key});

  @override
  State<GooglePlacesFilterMap> createState() => _GooglePlacesFilterMapState();
}

class _GooglePlacesFilterMapState extends State<GooglePlacesFilterMap> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final LatLng _mapCenter = kPernambucoCenter;
  bool _loading = false;
  String? _selectedFilter;
  DateTime? _lastRequestAt;
  bool _isMobilePlatform = true;

  // Cache simples: tipo -> entry
  final Map<String, _CacheEntry> _cache = {};

  @override
  void initState() {
    super.initState();
    // Detect platform early: Google Maps / native MethodChannel only available on Android/iOS
    _isMobilePlatform = io.Platform.isAndroid || io.Platform.isIOS;
    _initApiKey();
  }

  Future<void> _initApiKey() async {
    try {
      const channel = MethodChannel('dsi_project/maps');
      final key = await channel.invokeMethod<String>('getMapsApiKey');
      if (key != null && key.isNotEmpty) {
        _kGoogleApiKey = key;
      } else {
        // leave null -> UI will show message when attempting requests
      }
    } catch (_) {
      // ignore: avoid_print
      print('Could not load MAPS API key from platform.');
    }
  }

  // Função principal solicitada: busca locais por tipo usando Places Nearby Search
  // Retorna uma lista de Marker pronta para adicionar ao mapa.
  Future<List<Marker>> buscarLocaisPorTipo(String tipo) async {
    // 1) retorno via cache se válido
    final cached = _cache[tipo];
    if (cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age.inMinutes <= kCacheMinutes) return cached.markers;
    }

    // 2) montar requisição para Nearby Search
    final location = '${_mapCenter.latitude},${_mapCenter.longitude}';
    if (_kGoogleApiKey == null || _kGoogleApiKey!.isEmpty) {
      throw Exception(
        'API key do Google Maps não encontrada. Adicione MAPS_API_KEY em local.properties/Info.plist.',
      );
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': location,
        'radius': kDefaultRadius.toString(),
        'type': tipo, // pharmacy, hospital, doctor
        'key': _kGoogleApiKey!,
      },
    );

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

      final body = json.decode(resp.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw Exception('Places API error: $status');
      }

      final results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
      final List<Marker> markers = [];

      for (final r in results) {
        try {
          final place = r as Map<String, dynamic>;
          final geometry = place['geometry'] as Map<String, dynamic>? ?? {};
          final loc = (geometry['location'] ?? {}) as Map<String, dynamic>;
          final lat = (loc['lat'] as num?)?.toDouble();
          final lng = (loc['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final placeId =
              place['place_id'] as String? ?? UniqueKey().toString();
          final name = place['name'] as String? ?? 'Local';
          final vicinity = place['vicinity'] as String? ?? '';

          markers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name, snippet: vicinity),
              icon: _iconForType(tipo),
              onTap: () {
                // Aqui você pode abrir um bottom sheet com Place Details (cuidado com custo)
              },
            ),
          );
        } catch (_) {
          // ignora elementos mal-formados
        }
      }

      // salvar cache
      _cache[tipo] = _CacheEntry(markers: markers, fetchedAt: DateTime.now());
      return markers;
    } on TimeoutException {
      throw Exception('Tempo esgotado ao contatar Places API');
    } catch (e) {
      rethrow;
    }
  }

  BitmapDescriptor _iconForType(String tipo) {
    switch (tipo) {
      case 'pharmacy':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'hospital':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'doctor':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _applyFilter(String tipo) async {
    if (!_isMobilePlatform) {
      _showMessage(
        'Filtros do Google Maps só funcionam em Android/iOS. Execute o app em um dispositivo ou emulador Android/iOS.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _selectedFilter = tipo;
    });

    try {
      // rate-limit básico
      if (_lastRequestAt != null) {
        final diff = DateTime.now().difference(_lastRequestAt!);
        if (diff.inSeconds < 3)
          await Future.delayed(const Duration(seconds: 1));
      }

      final markers = await buscarLocaisPorTipo(tipo);
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
        _lastRequestAt = DateTime.now();
      });

      if (markers.isEmpty)
        _showMessage('Nenhum local encontrado para este filtro.');
    } catch (e) {
      _showMessage('Erro ao buscar locais: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _localizarUsuario() async {
    setState(() => _loading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Ative os serviços de localização no dispositivo.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Permissão negada permanentemente. Habilite nas configurações.',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final ctrl = await _controller.future;
      await ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('meu_local'),
            position: LatLng(pos.latitude, pos.longitude),
            infoWindow: const InfoWindow(title: 'Você está aqui'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      });
    } catch (e) {
      _showMessage('Erro ao obter localização: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildFilterBar() {
    final ButtonStyle chipStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1976D2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );

    Widget button(String label, String tipo, IconData icon) {
      final selected = _selectedFilter == tipo;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton.icon(
          style: chipStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(
              selected ? const Color(0xFFE3F2FD) : Colors.white,
            ),
            foregroundColor: WidgetStateProperty.all(
              selected ? const Color(0xFF0D47A1) : const Color(0xFF1976D2),
            ),
          ),
          onPressed: () => _applyFilter(tipo),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          button('Farmácias', 'pharmacy', Icons.local_pharmacy),
          button('Hospitais', 'hospital', Icons.local_hospital),
          button('Clínicas', 'doctor', Icons.medical_services),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          item(Colors.cyan, 'Farmácia'),
          const SizedBox(width: 8),
          item(Colors.red, 'Hospital'),
          const SizedBox(width: 8),
          item(Colors.purple, 'Clínica'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Serviços - Diabetes'),
        backgroundColor: const Color(0xFF0288D1),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mapCenter,
              zoom: 8.5,
            ),
            onMapCreated: (ctrl) {
              if (!_controller.isCompleted) _controller.complete(ctrl);
            },
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Column(
                children: [_buildFilterBar(), const SizedBox(height: 8)],
              ),
            ),
          ),
          Positioned(left: 12, bottom: 80, child: _buildLegend()),
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.extended(
              onPressed: _localizarUsuario,
              backgroundColor: const Color(0xFF0288D1),
              icon: const Icon(Icons.my_location),
              label: const Text('Localizar-me'),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.12),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _CacheEntry {
  final List<Marker> markers;
  final DateTime fetchedAt;
  _CacheEntry({required this.markers, required this.fetchedAt});
}
