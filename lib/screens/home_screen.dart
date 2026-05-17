import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/crisis_provider.dart';
import '../theme/app_theme.dart';
import '../models/crisis_models.dart';
import '../widgets/common_widgets.dart';

const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#0d1117"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#94a3b8"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#0d1117"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e2a40"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#7f1d1d"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0f1e"}]},{"featureType":"poi","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0f1624"}]}]';

const String _lightMapStyle = '[{"featureType":"poi","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ef4444"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#1e293b"}]}]';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _radarSpinCtrl;
  late Animation<double> _radarRot;
  late AnimationController _resultAnimCtrl;
  AnimationController? _blinkController;
  late Animation<double> _blinkAnimation;
  GoogleMapController? _mapController;
  String? _lastStatus;
  bool _isDarkMap = true;

  void _toggleMapTheme() async {
    final newValue = !_isDarkMap;
    setState(() => _isDarkMap = newValue);
    
    if (_mapController == null) return;
    
    try {
      await _mapController!.setMapStyle(
        newValue ? _darkMapStyle : _lightMapStyle
      );
    } catch (e) {
      debugPrint('Map style error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _radarSpinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _radarRot = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _radarSpinCtrl, curve: Curves.linear));
    _resultAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
    );
    _blinkController!.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _radarSpinCtrl.dispose();
    _resultAnimCtrl.dispose();
    _blinkController?.dispose();
    super.dispose();
  }

  // ══════════ LOCATION LOOKUP ══════════
  LatLng _getLocationCoords(String location) {
    final lower = location.toLowerCase();
    final map = {
      'g-10': const LatLng(33.6751, 73.0479),
      'g-11': const LatLng(33.6844, 73.0350),
      'g-9': const LatLng(33.6800, 73.0550),
      'g-8': const LatLng(33.6900, 73.0600),
      'f-8': const LatLng(33.7100, 73.0479),
      'f-7': const LatLng(33.7200, 73.0400),
      'f-6': const LatLng(33.7300, 73.0600),
      'f-10': const LatLng(33.7050, 73.0200),
      'f-11': const LatLng(33.7150, 73.0100),
      'i-8': const LatLng(33.6700, 73.0900),
      'i-9': const LatLng(33.6600, 73.0950),
      'faizabad': const LatLng(33.7008, 73.0679),
      'blue area': const LatLng(33.7294, 73.0931),
      'saddar': const LatLng(33.5973, 73.0479),
      'murree road': const LatLng(33.6200, 73.1000),
      'committee chowk': const LatLng(33.5950, 73.0550),
      'margalla': const LatLng(33.7500, 73.0700),
      'rawalpindi': const LatLng(33.5973, 73.0479),
    };

    for (final entry in map.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return const LatLng(33.6844, 73.0479);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrisisProvider>(
      builder: (context, provider, child) {
        final hasCrisis = provider.result?.crisisEvent != null;
        final crisis = provider.result?.crisisEvent;

        // Trigger result slide-in when status transitions to 'done'
        if (provider.status == 'done' && _lastStatus != 'done') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resultAnimCtrl.forward(from: 0);
            if (_mapController != null && provider.result?.crisisEvent != null) {
              _blinkController?.repeat(reverse: true);
            }
          });
        }
        _lastStatus = provider.status;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              _buildAppBar(),
              
              // ══════════ MAP AND OVERLAYS ══════════
              Expanded(
                child: Stack(
                  children: [
                    // Google Map filling available space
                    Positioned.fill(
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(33.6844, 73.0479),
                          zoom: 12.0,
                        ),
                        onMapCreated: (GoogleMapController controller) async {
                          _mapController = controller;
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (_isDarkMap) {
                            try {
                              await controller.setMapStyle(_darkMapStyle);
                            } catch (e) {
                              debugPrint('Initial style error: $e');
                            }
                          }
                        },
                        markers: _buildMarkers(provider),
                        circles: _buildCircles(provider),
                        mapType: MapType.normal,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        trafficEnabled: false,
                        buildingsEnabled: false,
                        indoorViewEnabled: false,
                        rotateGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                      ),
                    ),

                    // Map Theme Toggle Button
                    Positioned(
                      top: 12, right: 12,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _toggleMapTheme,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isDarkMap ? const Color(0xFF1E2A40) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isDarkMap ? const Color(0xFFDC2626) : Colors.grey,
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 8)
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDarkMap ? Icons.light_mode : Icons.dark_mode,
                                  size: 14,
                                  color: _isDarkMap ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isDarkMap ? 'LIGHT' : 'DARK',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMap ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Result action buttons (slide in when done)
                    if (hasCrisis)
                      Positioned(
                        bottom: 16, left: 16, right: 16,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero).animate(
                            CurvedAnimation(parent: _resultAnimCtrl, curve: Curves.easeOutCubic),
                          ),
                          child: _buildResultBanner(provider, context),
                        ),
                      ),

                    // FABs section
                    Positioned(
                      right: 16,
                      bottom: 200, // above bottom panel
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // NEW SCAN button — only show when result exists
                          if (provider.result != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FloatingActionButton.small(
                                heroTag: 'reset',
                                onPressed: () => provider.reset(),
                                backgroundColor: const Color(0xFF1E2A40),
                                child: const Icon(Icons.refresh, 
                                  color: Colors.white, size: 18),
                              ),
                            ),
                          
                          // Auto Scan — ALWAYS visible
                          FloatingActionButton.extended(
                            heroTag: 'autoscan',
                            onPressed: provider.isLoading 
                              ? null 
                              : () => provider.autoScan(),
                            backgroundColor: const Color(0xFF3B82F6),
                            icon: const Icon(Icons.radar, color: Colors.white),
                            label: const Text('Auto Scan',
                              style: TextStyle(color: Colors.white)),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Report Crisis — ALWAYS visible
                          FloatingActionButton.extended(
                            heroTag: 'report',
                            onPressed: provider.isLoading 
                              ? null 
                              : () => Navigator.pushNamed(context, '/input'),
                            backgroundColor: const Color(0xFFDC2626),
                            icon: const Icon(Icons.warning, color: Colors.white),
                            label: const Text('Report Crisis',
                              style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),

                    // Scanning overlay
                    if (provider.isLoading) _buildScanOverlay(provider),
                  ],
                ),
              ),

              // ══════════ BOTTOM PANEL ══════════
              hasCrisis ? _buildCrisisPanel(crisis!) : _buildMonitoringPanel(),
            ],
          ),
        );
      },
    );
  }

  // ══════════ MARKERS ══════════
  Set<Marker> _buildMarkers(CrisisProvider provider) {
    if (provider.result?.crisisEvent == null) return {};

    final coords = _getLocationCoords(
      provider.result!.crisisEvent!.location,
    );

    return {
      Marker(
        markerId: const MarkerId('crisis'),
        position: coords,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        alpha: _blinkAnimation.value,
        infoWindow: InfoWindow(
          title: '🚨 ${provider.result!.crisisEvent!.crisisType.toUpperCase()}',
          snippet: '${provider.result!.crisisEvent!.severity} • '
              '${provider.result!.crisisEvent!.confidence.toInt()}% confidence',
        ),
      ),
    };
  }

  // ══════════ CIRCLES ══════════
  Set<Circle> _buildCircles(CrisisProvider provider) {
    if (provider.result?.crisisEvent == null) return {};

    final coords = _getLocationCoords(
      provider.result!.crisisEvent!.location,
    );

    return {
      Circle(
        circleId: const CircleId('threat_zone'),
        center: coords,
        radius: 2000,
        fillColor: const Color(0xFFDC2626).withOpacity(0.08),
        strokeColor: const Color(0xFFDC2626).withOpacity(0.5),
        strokeWidth: 2,
      ),
    };
  }

  // ══════════ APPBAR ══════════
  Widget _buildAppBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RAHAT', style: TextStyle(color: AppTheme.crimson, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                SizedBox(height: 2),
                Text('Crisis Intelligence System', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
              ],
            ),
            Row(children: [
              PulsingDot(color: AppTheme.emerald, size: 8),
              SizedBox(width: 8),
              Text('SYSTEM ACTIVE', style: TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
          ],
        ),
      ),
    );
  }

  // ══════════ SCAN OVERLAY ══════════
  Widget _buildScanOverlay(CrisisProvider provider) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radar rings
            SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _radarSpinCtrl,
                    builder: (context, child) {
                      final progress = ((_radarSpinCtrl.value + i * 0.33) % 1.0);
                      final scale = 0.3 + progress * 0.7;
                      final opacity = (1.0 - progress).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.crimson, width: 2),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                provider.scanMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Terminal log
            Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF060911),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: ListView(
                shrinkWrap: true,
                children: provider.scanLog.map((msg) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('› $msg', style: const TextStyle(color: AppTheme.terminalGreen, fontSize: 11, fontFamily: 'monospace')),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════ RESULT BANNER ══════════
  Widget _buildResultBanner(CrisisProvider provider, BuildContext ctx) {
    final crisis = provider.result?.crisisEvent;
    if (crisis == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.crimson.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.crimson, width: 1),
          ),
          child: Row(
            children: [
              const Text('🚨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crisis.crisisType.toUpperCase(), style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(crisis.location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(12)),
                child: Text('${crisis.confidence.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(ctx, '/trace'),
                icon: const Icon(Icons.psychology, color: Colors.white, size: 16),
                label: const Text('Agent Reasoning', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceElevated,
                  side: const BorderSide(color: AppTheme.electric),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(ctx, '/outcome'),
                icon: const Icon(Icons.assessment, color: Colors.white, size: 16),
                label: const Text('View Report', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimson,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                provider.reset();
              },
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
              label: const Text('New Scan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2A40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Colors.white24),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════ MONITORING PANEL ══════════
  Widget _buildMonitoringPanel() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(animation: _radarRot, builder: (c, ch) => Transform.rotate(angle: _radarRot.value, child: ch), child: const Icon(Icons.radar, color: AppTheme.electric, size: 28)),
              const SizedBox(width: 12),
              const Text('No Active Crisis Detected', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_feedPill('● Social Feed'), const SizedBox(width: 12), _feedPill('● Weather API'), const SizedBox(width: 12), _feedPill('● Traffic Feed')],
          ),
          const SizedBox(height: 12),
          Text('All data feeds operational. Monitoring Islamabad sector grid.', style: TextStyle(color: AppTheme.textMuted.withOpacity(0.7), fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _feedPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppTheme.emeraldGlow, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.emerald.withOpacity(0.3))),
    child: Text(label, style: const TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  // ══════════ CRISIS PANEL ══════════
  Widget _buildCrisisPanel(CrisisEvent crisis) {
    final emoji = AppTheme.crisisEmoji(crisis.crisisType);
    final coords = _getLocationCoords(crisis.location);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [BoxShadow(color: AppTheme.crimson.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Text(crisis.crisisType.toUpperCase(), style: const TextStyle(color: AppTheme.crimson, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1))),
            SeverityBadge(severity: crisis.severity),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Expanded(child: Text(crisis.location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${coords.latitude.toStringAsFixed(4)}°N', style: TextStyle(fontFamily: 'monospace', color: AppTheme.textMuted.withOpacity(0.6), fontSize: 9)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Confidence:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: crisis.confidence / 100, backgroundColor: AppTheme.border, valueColor: const AlwaysStoppedAnimation(AppTheme.crimson), minHeight: 6))),
            const SizedBox(width: 8),
            Text('${crisis.confidence.toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.crimson, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: Text(crisis.situationSummary, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
