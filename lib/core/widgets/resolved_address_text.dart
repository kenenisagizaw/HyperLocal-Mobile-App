import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ResolvedAddressText extends StatefulWidget {
  const ResolvedAddressText({
    super.key,
    required this.fallback,
    this.lat,
    this.lng,
    this.style,
    this.placeholder = 'Resolving address...',
  });

  final double? lat;
  final double? lng;
  final String fallback;
  final TextStyle? style;
  final String placeholder;

  @override
  State<ResolvedAddressText> createState() => _ResolvedAddressTextState();
}

class _ResolvedAddressTextState extends State<ResolvedAddressText> {
  static final Map<String, String> _cache = {};
  String? _resolved;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _resolveIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ResolvedAddressText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _resolved = null;
      _resolveIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = widget.lat != null && widget.lng != null;
    final text = _isResolving && hasCoords
        ? widget.placeholder
        : _resolved ?? widget.fallback;
    return Text(text, style: widget.style);
  }

  void _resolveIfNeeded() {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == null || lng == null) {
      return;
    }
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    final cached = _cache[key];
    if (cached != null && cached.isNotEmpty) {
      setState(() => _resolved = cached);
      return;
    }
    _resolveAddress(lat: lat, lng: lng, cacheKey: key);
  }

  Future<void> _resolveAddress({
    required double lat,
    required double lng,
    required String cacheKey,
  }) async {
    if (_isResolving) {
      return;
    }
    setState(() => _isResolving = true);
    try {
      final dio = Dio(
        BaseOptions(
          headers: const {
            'User-Agent': 'my_first_app',
            'Accept': 'application/json',
          },
        ),
      );
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
      );
      if (!mounted) return;
      if (response.data is Map) {
        final data = response.data as Map;
        final displayName = data['display_name']?.toString();
        if (displayName != null && displayName.trim().isNotEmpty) {
          _cache[cacheKey] = displayName;
          setState(() => _resolved = displayName);
        }
      }
    } catch (_) {
      // Keep fallback text when reverse geocoding fails.
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }
}
