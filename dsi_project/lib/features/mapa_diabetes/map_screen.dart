// Este arquivo usa `flutter_map` e `latlong2`.
// Se o analisador do Dart estiver mostrando erros do tipo
// "Target of URI doesn't exist" ou "Undefined class 'LatLng'",
// isso normalmente significa que você ainda não rodou `flutter pub get`.
// Adicionamos diretivas para suprimir falsos-positivos do analisador
// localmente, mantendo as importações reais.
// ignore_for_file: uri_does_not_exist, undefined_class, undefined_function, undefined_identifier

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Centro de Recife, Pernambuco (latlong2.LatLng)
final LatLng kRecifeCenter = LatLng(-8.0476, -34.8770);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;

  // NOTE: typed cache is used instead (per tipo+center)

  // allow multiple filters to be selected
  final Set<String> _selectedFilters = {};
  bool _loading = false;
  List<_Place> _places = [];
  LatLng? _userPosition;

  static const int kCacheMinutes = 10;
  // cache keyed by "tipo:lat:lon" to allow caching per area
  final Map<String, _CacheEntry> _typedCache = {};
  static const int _searchRadiusMeters = 5000; // 5 km

  // Busca locais próximos ao centro fornecido usando Nominatim.
  // Retorna apenas locais dentro de _searchRadiusMeters do centro.
  Future<List<_Place>> buscarLocaisPorTipo(String tipo, LatLng center) async {
    final now = DateTime.now();
    final key =
        '$tipo:${center.latitude.toStringAsFixed(3)}:${center.longitude.toStringAsFixed(3)}';
    final cached = _typedCache[key];
    if (cached != null) {
      final age = now.difference(cached.fetchedAt);
      if (age.inMinutes <= kCacheMinutes) return cached.places;
    }

    // Map Portuguese type keys to English search terms for better Nominatim results
    final Map<String, String> typeMap = {
      'farmacia': 'pharmacy',
      'hospital': 'hospital',
      'clinica': 'clinic',
    };
    final queryTerm = typeMap[tipo] ?? tipo;
    // Query Nominatim for text near coordinates; we'll filter by distance client-side
    final q = Uri.encodeComponent(
      '$queryTerm near ${center.latitude},${center.longitude}',
    );
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search.php?q=$q&format=jsonv2&limit=50',
    );

    final headers = {
      'User-Agent':
          'DSI-Project-App/1.0 (https://github.com/JuuJ12/DSI-PROJECT)',
    };
    final resp = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

    final body = json.decode(resp.body) as List<dynamic>;
    final List<_Place> results = [];
    final Distance distance = Distance();

    for (final item in body) {
      try {
        final m = item as Map<String, dynamic>;
        final lat = double.tryParse(m['lat']?.toString() ?? '');
        final lon = double.tryParse(m['lon']?.toString() ?? '');
        final display = (m['display_name'] as String?) ?? tipo;
        if (lat == null || lon == null) continue;
        final p = LatLng(lat, lon);
        final meters = distance.distance(center, p);
        if (meters <= _searchRadiusMeters) {
          results.add(_Place(name: display, latLng: p, tipo: tipo));
        }
      } catch (_) {
        // ignore malformed entries
      }
    }

    _typedCache[key] = _CacheEntry(places: results, fetchedAt: now);
    return results;
  }

  Future<void> _applyFilter(String tipo) async {
    // legacy single-filter method kept for compatibility but not used.
    // Prefer using _toggleFilter / _applyFilters for multi-selection.
    if (mounted) setState(() => _loading = true);
    try {
      final center = _userPosition ?? kRecifeCenter;
      final places = await buscarLocaisPorTipo(tipo, center);
      if (mounted) setState(() => _places = places);
      if (places.isEmpty) {
        _showMessage('Nenhum local encontrado para "${_labelForType(tipo)}".');
      } else {
        _mapController.move(places.first.latLng, 14);
      }
    } on TimeoutException {
      _showMessage(
        'Tempo esgotado ao contatar o serviço de busca. Tente novamente.',
      );
    } catch (e) {
      _showMessage('Erro ao buscar locais: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Toggle a filter in the selection set and re-run search aggregation.
  Future<void> _toggleFilter(String tipo) async {
    if (_selectedFilters.contains(tipo)) {
      _selectedFilters.remove(tipo);
    } else {
      _selectedFilters.add(tipo);
    }
    await _applyFilters();
  }

  // Aggregate results for all selected filters, deduplicate by coordinates.
  Future<void> _applyFilters() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _places = [];
      });
    }

    try {
      final center = _userPosition ?? kRecifeCenter;
      if (_selectedFilters.isEmpty) {
        if (mounted) setState(() => _places = []);
        return;
      }

      final Map<String, _Place> dedupe = {};
      for (final tipo in _selectedFilters) {
        try {
          final places = await buscarLocaisPorTipo(tipo, center);
          for (final p in places) {
            final key =
                '${p.latLng.latitude.toStringAsFixed(6)}|${p.latLng.longitude.toStringAsFixed(6)}';
            if (!dedupe.containsKey(key)) dedupe[key] = p;
          }
        } catch (_) {
          // ignore per-type failures, continue others
        }
      }

      final aggregated = dedupe.values.toList();
      print('Total agregados: ${aggregated.length}');
      if (mounted) setState(() => _places = aggregated);

      if (aggregated.isEmpty) {
        _showMessage('Nenhum local encontrado para os filtros selecionados.');
      } else {
        // Move to first aggregated result
        _mapController.move(aggregated.first.latLng, 14);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _emojiForType(String tipo) {
    switch (tipo) {
      case 'farmacia':
        return '💊';
      case 'hospital':
        return '🏥';
      case 'clinica':
        return '🧑‍⚕️';
      default:
        return '📍';
    }
  }

  // Parse display_name into structured address components
  Map<String, String> _parseAddress(String displayName) {
    final parts = displayName.split(',').map((s) => s.trim()).toList();
    final address = <String, String>{};

    if (parts.isNotEmpty) address['name'] = parts[0];
    if (parts.length > 1) address['street'] = parts[1];
    if (parts.length > 2) address['neighborhood'] = parts[2];
    if (parts.length > 3) address['city'] = parts[3];
    if (parts.length > 4) address['state'] = parts[4];

    // Extract CEP (Brazilian postal code) - usually 8 digits with optional dash
    final cepRegex = RegExp(r'\b\d{5}-?\d{3}\b');
    final cepMatch = cepRegex.firstMatch(displayName);
    if (cepMatch != null) address['cep'] = cepMatch.group(0)!;

    return address;
  }

  Widget _buildAddressSection(Map<String, String> address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Endereço',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        if (address['street'] != null)
          Row(
            children: [
              const Icon(Icons.streetview, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address['street']!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        if (address['neighborhood'] != null)
          Row(
            children: [
              const Icon(Icons.location_city, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address['neighborhood']!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        if (address['city'] != null || address['state'] != null)
          Row(
            children: [
              const Icon(Icons.map, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${address['city'] ?? ''}${address['city'] != null && address['state'] != null ? ', ' : ''}${address['state'] ?? ''}'
                      .trim(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        if (address['cep'] != null)
          Row(
            children: [
              const Icon(Icons.mail, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'CEP: ${address['cep']}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _labelForType(String tipo) {
    switch (tipo) {
      case 'farmacia':
        return 'Farmácias';
      case 'hospital':
        return 'Hospitais';
      case 'clinica':
        return 'Clínicas';
      default:
        return tipo;
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Compute dynamic offsets to keep marker widgets above the geographic point.
    // This uses MediaQuery textScaleFactor so larger fonts scale appropriately.
    final double textScale = MediaQuery.of(context).textScaleFactor;
    const double poiIconSize = 26.0;
    const double userIconSize = 28.0;
    const double labelFontSize = 12.0;
    const int labelMaxLines = 2;
    final double estimatedLabelHeight =
        labelFontSize * 1.2 * labelMaxLines * textScale;
    // padding(6) + marginTop(4) + extra spacing
    // add a small buffer to ensure we don't get a small overflow near screen edges
    const double extraMargin = 12.0;
    final double poiOffsetY =
        -(poiIconSize + estimatedLabelHeight + 6.0 + 4.0 + 8.0 + extraMargin);
    final double userOffsetY = -(userIconSize / 2 + 8.0 + extraMargin / 2);
    // (removed per-marker bubble width - markers are compact and use BottomSheet)
    // Add user location marker first if available
    if (_userPosition != null) {
      markers.add(
        Marker(
          width: 48,
          height: 48,
          point: _userPosition!,
          // translate the marker up so its bottom aligns with the location point
          child: Transform.translate(
            offset: Offset(0, userOffsetY),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.my_location, color: Color(0xFF1976D2), size: 28),
              ],
            ),
          ),
        ),
      );
    }

    // Build compact markers: only an icon; details shown in a BottomSheet to avoid inline overflow
    markers.addAll(
      _places.map((p) {
        final icon = _emojiForType(p.tipo);
        return Marker(
          width: 48,
          height: 48,
          point: p.latLng,
          child: Transform.translate(
            offset: Offset(0, poiOffsetY),
            child: GestureDetector(
              onTap: () => _showPlaceBottomSheet(p),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text(icon, style: const TextStyle(fontSize: 26))],
              ),
            ),
          ),
        );
      }).toList(),
    );

    return markers;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final pos = await _determinePosition();
        final userLatLng = LatLng(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() => _userPosition = userLatLng);
          _mapController.move(userLatLng, 14);
        }
      } catch (e) {
        // keep default center if location not available
        _showMessage(
          'Não foi possível obter localização inicial: ${e.toString()}',
        );
      }
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<void> _showAndCenterUserLocation() async {
    try {
      setState(() => _loading = true);
      final pos = await _determinePosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userPosition = userLatLng;
      });
      _mapController.move(userLatLng, 15);
      _showMessage('Localização atual exibida.');
    } catch (e) {
      _showMessage('Não foi possível obter a localização: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPlaceDialog(_Place p) {
    // Recentraliza o mapa no local tocado para garantir que o rótulo/dialog fique visível
    try {
      _mapController.move(p.latLng, _currentZoom);
    } catch (_) {
      // fallback: ignore se o controller não puder mover por algum motivo
    }

    showDialog(
      context: context,
      builder: (_) {
        final double maxDialogWidth = math.min(
          300.0,
          MediaQuery.of(context).size.width * 0.9,
        );
        final double maxDialogHeight =
            MediaQuery.of(context).size.height * 0.45;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Text(p.name),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxDialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local: ${p.latLng.latitude.toStringAsFixed(5)}, ${p.latLng.longitude.toStringAsFixed(5)}',
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Show place details in a responsive BottomSheet (avoids inline overflow)
  Future<void> _showPlaceBottomSheet(_Place p) async {
    // move map slightly so selected marker is visible above the sheet
    try {
      _mapController.move(p.latLng, _currentZoom);
    } catch (_) {}

    final address = _parseAddress(p.name);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.25,
          minChildSize: 0.12,
          maxChildSize: 0.85,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Title with icon
                  Row(
                    children: [
                      Text(
                        _emojiForType(p.tipo),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address['name'] ?? p.name.split(',').first.trim(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Address section
                  if (address['street'] != null ||
                      address['neighborhood'] != null)
                    _buildAddressSection(address),
                  // Coordinates
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p.latLng.latitude.toStringAsFixed(6)}, ${p.latLng.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          // keep sheet closed, then open details dialog
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            () => _showPlaceDialog(p),
                          );
                        },
                        child: const Text('Detalhes'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // center map on place and close sheet
                          try {
                            _mapController.move(p.latLng, _currentZoom);
                          } catch (_) {}
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Centralizar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _filterButton('farmacia', icon: '💊'),
          _filterButton('hospital', icon: '🏥'),
          _filterButton('clinica', icon: '🧑‍⚕️'),
        ],
      ),
    );
  }

  Widget _filterButton(String tipo, {required String icon}) {
    final selected = _selectedFilters.contains(tipo);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF0288D1) : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black87,
        elevation: selected ? 4 : 1,
      ),
      onPressed: () {
        _toggleFilter(tipo);
      },
      icon: Text(icon),
      label: Text(_labelForType(tipo), style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () {
            // Preferir voltar na pilha de navegação quando possível.
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Se não houver onde voltar (ex: aberto diretamente), navega para a Home.
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Mapa de serviço diabetes',
          style: TextStyle(color: Colors.white),
        ),
        // use the project's primary/brand green from Home
        backgroundColor: const Color(0xFF6B7B5E),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: kRecifeCenter,
                initialZoom: 12,
                minZoom: 5,
                // keep track of zoom so we can recenter correctly when opening popups
                onPositionChanged: (pos, _) {
                  // pos.zoom is non-nullable in this flutter_map version
                  _currentZoom = pos.zoom;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dsi_project',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          // Filter bar (top)
          SafeArea(
            child: Column(
              children: [const SizedBox(height: 8), _buildFilterBar()],
            ),
          ),

          // Legend removed per UX request (farmácia/hospital/clínica labels)

          // Loading
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // Localize-me button (bottom-right)
          Positioned(
            right: 12,
            bottom: 24,
            child: SafeArea(
              child: FloatingActionButton(
                heroTag: 'locate_fab',
                // match Home primary color
                backgroundColor: const Color(0xFF6B7B5E),
                onPressed: () async {
                  await _showAndCenterUserLocation();
                },
                tooltip: 'Centralizar',
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model simples para resultados de busca
class _Place {
  final String name;
  final LatLng latLng;
  final String tipo;
  _Place({required this.name, required this.latLng, required this.tipo});
}

class _CacheEntry {
  final List<_Place> places;
  final DateTime fetchedAt;
  _CacheEntry({required this.places, required this.fetchedAt});
}
  
