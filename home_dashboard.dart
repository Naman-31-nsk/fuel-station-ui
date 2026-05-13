import 'dart:async';
import 'dart:ui';
import 'package:fl_sdp/fl_sdp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'models/fuel_data_model.dart';
import 'bloc/fuel_bloc.dart';
import 'bloc/fuel_event.dart';
import 'bloc/fuel_state.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/petrol_pump.dart';
import '../../core/services/pump_database_service.dart';
import '../../core/services/pump_seeder_service.dart';
import '../device_connection/repository/connection_repository.dart';
import '../../core/services/sound_service.dart';
import 'widgets/metric_card.dart';
import 'widgets/nearby_station_card.dart';

import 'widgets/blend_details_sheet.dart';
import 'widgets/parameters_drawer.dart';
import 'widgets/account_drawer.dart';
import 'widgets/dashboard_bottom_bar.dart';
import '../../core/widgets/top_notification_toast.dart';
// import 'station_list_screen.dart'; // ── Disabled: replaced by StaticPumpScreen
import 'static_pump_screen.dart';
import 'fuel_history_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../../core/utils/route_transitions.dart';
import '../../core/widgets/glass_action_button.dart';

// ─── Outer shell: loads device ID + provides BLoC ────────────────────────────

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await AuthService.getRegisteredDeviceId();
    debugPrint('🔑 HomeDashboard: Loaded registered device ID: $id');

    if (id != null && id.isNotEmpty) {
      final repo = ConnectionRepository();
      await repo.ensureAutoReconnectTarget(id);
      repo.tryAutoReconnect();
      debugPrint('🔄 HomeDashboard: Auto-reconnect triggered for $id');
    }

    if (mounted) setState(() => _deviceId = id ?? '');
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return BlocProvider(
      create: (context) => FuelBloc()..add(LoadFuelDataEvent(_deviceId!)),
      child: _HomeDashboardView(deviceId: _deviceId!),
    );
  }
}

// ─── Inner view: slim coordinator ────────────────────────────────────────────

class _HomeDashboardView extends StatefulWidget {
  final String deviceId;
  const _HomeDashboardView({required this.deviceId});

  @override
  State<_HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<_HomeDashboardView> {
  bool _hasShownContaminantSheet = false;
  bool _isSheetCurrentlyOpen = false;
  FuelData? _lastKnownData;
  bool _isAnalyzingInProgress = false;
  int _selectedIndex = 0;
  bool _isDeviceEnabled = true;

  List<PetrolPump> _nearbyPumps = [];
  Position? _userPosition;
  bool _seedRetryScheduled = false;
  bool _pumpsLoading = false;

  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;
  StreamSubscription<DeviceConnectionStatus>? _connectionStatusSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastLoadPosition;

  @override
  void initState() {
    super.initState();
    _loadNearbyPumps();
    _initBluetoothMonitoring();
    _initConnectionMonitoring();
    _initMovementTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<FuelBloc>().state;
        if (state is FuelLoaded) _lastKnownData = state.fuelData;
      }
    });
  }

  Future<void> _loadNearbyPumps() async {
    if (_pumpsLoading) return;
    _pumpsLoading = true;
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {}

    List<PetrolPump> pumps;
    if (pos != null) {
      debugPrint(
        '[Dashboard] 🗺️ Geohash query for (${pos.latitude}, ${pos.longitude})',
      );
      final candidates = await PumpDatabaseService.getPumpsByGeohashArea(
        pos.latitude,
        pos.longitude,
      );
      pumps = candidates.where((p) {
        final d = Geolocator.distanceBetween(
          pos!.latitude,
          pos.longitude,
          p.lat,
          p.lon,
        );
        return d <= 2000;
      }).toList();
      debugPrint(
        '[Dashboard] 🗺️ Geohash candidates: ${candidates.length}, within 2km: ${pumps.length}',
      );
    } else {
      pumps = await PumpDatabaseService.getAllPumps();
      debugPrint(
        '[Dashboard] 🗺️ No GPS fix — loaded ${pumps.length} pump(s) via full scan',
      );
    }

    _pumpsLoading = false;
    if (mounted) {
      setState(() {
        _nearbyPumps = pumps;
        _userPosition = pos;
      });
    }

    // If DB was empty (seeding still in progress), reload once seeding finishes.
    // Guard with a flag — seedingDone is already-completed after first seed,
    // so without this, registering .then() on an empty result would loop forever.
    if (pumps.isEmpty && !_seedRetryScheduled) {
      _seedRetryScheduled = true;
      PumpSeederService.seedingDone.then((_) {
        _seedRetryScheduled = false;
        if (mounted) _loadNearbyPumps();
      });
    }
  }

  void _initMovementTracking() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 50,
          ),
        ).listen(
          (position) {
            if (_lastLoadPosition == null) {
              _lastLoadPosition = position;
              return;
            }
            final moved = Geolocator.distanceBetween(
              _lastLoadPosition!.latitude,
              _lastLoadPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            if (moved >= 500) {
              debugPrint(
                '[Dashboard] 📍 Moved ${moved.toStringAsFixed(0)}m — reloading nearby pumps',
              );
              _lastLoadPosition = position;
              _loadNearbyPumps();
            }
          },
          onError: (e) {
            // Permission revoked or location services disabled at runtime — log and stop.
            debugPrint('[Dashboard] ⚠️ Position stream error: $e');
          },
        );
  }

  void _initBluetoothMonitoring() {
    _bluetoothStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothAdapterState.off) {
        TopNotificationToast.show(
          context,
          'Bluetooth is OFF: Please turn on Bluetooth to connect with device',
          backgroundColor: const Color(0xffFF0B08),
          icon: Icons.bluetooth_disabled_rounded,
        );
      }
    });
  }

  void _initConnectionMonitoring() {
    _connectionStatusSubscription = ConnectionRepository().statusStream.listen((
      status,
    ) {
      if (!mounted) return;
      if (status == DeviceConnectionStatus.connecting) {
        TopNotificationToast.show(
          context,
          'Connecting to device...',
          backgroundColor: const Color(0xff0018BE),
          icon: Icons.bluetooth_searching_rounded,
        );
      } else if (status == DeviceConnectionStatus.connected) {
        TopNotificationToast.show(
          context,
          'Device Connected Successfully',
          backgroundColor: const Color(0xff008000), // Pure Green
          icon: Icons.bluetooth_connected_rounded,
          duration: const Duration(seconds: 2),
        );
      } else if (status == DeviceConnectionStatus.error) {
        TopNotificationToast.show(
          context,
          'Connection Failed. Please try again.',
          backgroundColor: const Color(0xffFF0B08),
          icon: Icons.error_outline_rounded,
        );
      }
    });
  }

  @override
  void dispose() {
    _bluetoothStateSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _checkContaminationAndShow(FuelData data) {
    debugPrint(
      '🔍 Dashboard Check - Status: ${data.contaminationStatus}, HasShown: $_hasShownContaminantSheet, IsOpen: $_isSheetCurrentlyOpen',
    );
    if (data.contaminationStatus == 'contaminated' &&
        !_hasShownContaminantSheet &&
        !_isSheetCurrentlyOpen) {
      debugPrint('🚨 AUTO-OPENING BOTTOM SHEET TRIGGERED AFTER STABLE RESULT');
      _hasShownContaminantSheet = true;
      _autoShowContaminationSheet(context, data);
    } else if (data.contaminationStatus == 'clean' &&
        _hasShownContaminantSheet) {
      debugPrint('✅ Fuel Clean. Resetting Flag.');
      _hasShownContaminantSheet = false;
    }
  }

  void _autoShowContaminationSheet(BuildContext context, FuelData data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isSheetCurrentlyOpen) return;
      setState(() => _isSheetCurrentlyOpen = true);
      HapticFeedbackUtil.continuousAlert();
      showBlendDetailsBottomSheet(context, widget.deviceId)
          .then((_) {
            if (mounted) setState(() => _isSheetCurrentlyOpen = false);
          })
          .catchError((e) {
            debugPrint('❌ Error showing auto bottom sheet: $e');
            if (mounted) setState(() => _isSheetCurrentlyOpen = false);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FuelBloc, FuelState>(
      listener: (context, state) {
        // if (state is FuelAnalyzing) {
        //   _isAnalyzingInProgress = true;
        //   if (_isSheetCurrentlyOpen) Navigator.of(context).maybePop();
        // }
        if (state is FuelLoaded) {
          if (state.isLive) {
            _lastKnownData = state.fuelData;
          } else if (_lastKnownData == null) {
            // Show toast if we only have historical/stale data and no previous live data
            TopNotificationToast.show(
              context,
              'Waiting for Device: Please connect to start analysis',
              backgroundColor: const Color(0xff0018BE),
              icon: Icons.bluetooth_searching_rounded,
            );
          }

          // if (_isAnalyzingInProgress) {
          //   if (state.fuelData.contaminationStatus == 'clean') {
          //     SoundService().playSuccess();
          //   } else {
          //     SoundService().playWarning();
          //   }
          // }
          // if (_isAnalyzingInProgress ||
          //     (state.isLive && state.fuelData.contaminationStatus == 'contaminated' && !_hasShownContaminantSheet)) {
          //   _checkContaminationAndShow(state.fuelData);
          // }
          // _isAnalyzingInProgress = false;
        }
      },
      child: BlocBuilder<FuelBloc, FuelState>(
        builder: (context, state) {
          if (state is FuelLoaded && state.isLive) {
            _lastKnownData = state.fuelData;
          }
          final latestData = _lastKnownData;

          return Scaffold(
            backgroundColor: const Color(0xFF070707),
            extendBody: true,
            drawer: const ParametersDrawer(),
            endDrawer: const AccountDrawer(),
            body: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.4),
                  radius: 1.5,
                  colors: [
                    Color(0xFF381010), // Dark reddish glow
                    Color(0xFF0A0A0A), // Blackish background
                  ],
                ),
              ),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeContent(state, latestData),
                  FuelHistoryScreen(
                    onBack: () => setState(() => _selectedIndex = 0),
                  ),
                  // StationListScreen(onBack: () => setState(() => _selectedIndex = 0)), // ── Disabled
                  StaticPumpScreen(
                    onBack: () => setState(() => _selectedIndex = 0),
                  ),
                  ProfileScreen(
                    onBack: () => setState(() => _selectedIndex = 0),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: DashboardBottomBar(
              selectedIndex: _selectedIndex,
              onTap: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent(FuelState state, FuelData? latestData) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              SDP.sdp(20),
              SDP.sdp(20),
              SDP.sdp(20),
              SDP.sdp(120),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────
                Row(
                  children: [
                    GlassActionButton(
                      onTap: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      child: ClipOval(
                        child: Image.network(
                          'https://unsplash.com/photos/man-wearing-crew-neck-shirt-photograph-T0iTtJ7Gxrc',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                ),
                              ),
                        ),
                      ),
                    ),
                    SizedBox(width: SDP.sdp(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abhishek Singh',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: SDP.sdp(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: SDP.sdp(2)),
                        Text(
                          'Welcome Back !',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: SDP.sdp(12),
                            fontWeight: FontWeight.w400,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GlassActionButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRightPageRoute(
                            page: NotificationScreen(
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: SDP.sdp(24)),

                // ── Device Status ────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(SDP.sdp(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: Colors.white.withOpacity(0.6),
                        strokeWidth: 0.5,
                        radius: SDP.sdp(20),
                        dashPattern: [SDP.sdp(6), SDP.sdp(4)],
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SDP.sdp(16),
                          vertical: SDP.sdp(10),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(SDP.sdp(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Device Status',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: SDP.sdp(15),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: _isDeviceEnabled,
                                    activeColor: const Color(0xFFFF3B30),
                                    onChanged: (val) {
                                      setState(() => _isDeviceEnabled = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: SDP.sdp(6)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'MiloPure-X100',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: SDP.sdp(13),
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: SDP.sdp(8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SDP.sdp(10),
                                    vertical: SDP.sdp(6),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      SDP.sdp(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: SDP.sdp(8),
                                        height: SDP.sdp(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: SDP.sdp(6)),
                                      Text(
                                        'Connected',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: SDP.sdp(12),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SDP.sdp(16)),

                // ── Engine Risk Score ───────────────────────────────────
                CustomPaint(
                  foregroundPainter: _GradientBorderPainter(
                    radius: SDP.sdp(12),
                    strokeWidth: 1.5,
                    fullBorder: true,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.0),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SDP.sdp(12)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(SDP.sdp(20)),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Engine Risk Score',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: SDP.sdp(16),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: SDP.sdp(20),
                                ),
                              ],
                            ),
                            SizedBox(height: SDP.sdp(2)),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Based on recent fuel quality',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: SDP.sdp(12),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: SDP.sdp(24)),

                            // Central Gauge Chart Simulator (Group 35162)
                            SizedBox(
                              width: SDP.sdp(180),
                              height: SDP.sdp(180),
                              child: CustomPaint(
                                painter: _EngineGaugePainter(score: 0.95),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ShaderMask(
                                        blendMode: BlendMode.srcIn,
                                        shaderCallback: (rect) =>
                                            const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFFF7655),
                                                Color(0xFFFF0000),
                                              ],
                                              stops: [0.1688, 0.9348],
                                            ).createShader(rect),
                                        child: Text(
                                          '95',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: SDP.sdp(48),
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Quality Score',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: SDP.sdp(12),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.6),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: SDP.sdp(32)),

                            // Status pill row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SDP.sdp(8),
                                    vertical: SDP.sdp(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF05DF72,
                                    ).withOpacity(0.1),
                                    border: Border.all(
                                      color: const Color(0xFF05DF72),
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      SDP.sdp(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: SDP.sdp(8),
                                        height: SDP.sdp(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF05DF72,
                                          ).withOpacity(0.84),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: SDP.sdp(10)),
                                      Text(
                                        'Low Risk',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: SDP.sdp(12),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: SDP.sdp(12)),

                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    'Your engine is well protected',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: SDP.sdp(11),
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SDP.sdp(16)),

                // ── Last Scan Result ───────────────────────────────────
                CustomPaint(
                  foregroundPainter: _GradientBorderPainter(
                    radius: SDP.sdp(16),
                    strokeWidth: 1.5,
                    fullBorder: true,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.0),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(SDP.sdp(20)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF221716),
                      borderRadius: BorderRadius.circular(SDP.sdp(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Last Scan Result',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: SDP.sdp(15),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            CustomPaint(
                              foregroundPainter: _GradientBorderPainter(
                                radius: SDP.sdp(20),
                                strokeWidth: 1.5,
                                fullBorder: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.8),
                                  ],
                                  stops: const [0.0, 0.35, 0.65, 1.0],
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SDP.sdp(12),
                                  vertical: SDP.sdp(6),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(
                                    SDP.sdp(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View details',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: SDP.sdp(11),
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(width: SDP.sdp(4)),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white70,
                                      size: SDP.sdp(14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDP.sdp(16)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '95',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: SDP.sdp(42),
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: SDP.sdp(6),
                                left: SDP.sdp(4),
                              ),
                              child: Text(
                                '/100',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: SDP.sdp(24),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDP.sdp(12)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SDP.sdp(10),
                            vertical: SDP.sdp(6),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(SDP.sdp(20)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: SDP.sdp(8),
                                height: SDP.sdp(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: SDP.sdp(6)),
                              Text(
                                'Excellent Quality',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: SDP.sdp(11),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: SDP.sdp(20)),
                        Divider(
                          color: Colors.white.withOpacity(0.1),
                          thickness: 1,
                        ),
                        SizedBox(height: SDP.sdp(16)),
                        _buildScanRow('Station', 'Shell Downtown'),
                        SizedBox(height: SDP.sdp(12)),
                        _buildScanRow('Date', 'Apr 14, 2:30 PM'),
                        SizedBox(height: SDP.sdp(12)),
                        _buildScanRow('Confidence', '95%'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: SDP.sdp(13),
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: SDP.sdp(13),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final List<double> dashPattern;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final metric = path.computeMetrics().first;
    final dashedPath = Path();

    double distance = 0.0;
    bool draw = true;
    int index = 0;

    while (distance < metric.length) {
      final len = dashPattern[index % dashPattern.length];
      if (draw) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
      }
      distance += len;
      draw = !draw;
      index++;
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;
  final bool fullBorder;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
    this.fullBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (fullBorder) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = gradient.createShader(rect);
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
      canvas.drawPath(path, paint);
    } else {
      // === TOP EDGE (left to right, white → transparent) ===
      final topPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(rect);

      final topPath = Path()
        ..moveTo(radius, 0)
        ..lineTo(size.width * 0.8, 0);
      canvas.drawPath(topPath, topPaint);

      // === LEFT EDGE (top to bottom, white → transparent) ===
      final leftPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(rect);

      final leftPath = Path()
        ..moveTo(0, radius)
        ..lineTo(0, size.height * 0.8);
      canvas.drawPath(leftPath, leftPaint);

      // === TOP-LEFT CORNER ARC ===
      final topLeftPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white;

      final topLeftPath = Path()
        ..moveTo(0, radius)
        ..arcToPoint(
          Offset(radius, 0),
          radius: Radius.circular(radius),
          clockwise: false,
        );
      canvas.drawPath(topLeftPath, topLeftPaint);

      // === RIGHT EDGE (top to bottom, transparent → white) ===
      final rightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white],
          stops: [0.0, 1.0],
        ).createShader(rect);

      final rightPath = Path()
        ..moveTo(size.width, size.height * 0.2)
        ..lineTo(size.width, size.height - radius);
      canvas.drawPath(rightPath, rightPaint);

      // === BOTTOM EDGE (right to left, white → transparent) ===
      final bottomPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Colors.white, Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(rect);

      final bottomPath = Path()
        ..moveTo(size.width - radius, size.height)
        ..lineTo(size.width * 0.2, size.height);
      canvas.drawPath(bottomPath, bottomPaint);

      // === BOTTOM-RIGHT CORNER ARC ===
      final bottomRightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white;

      final bottomRightPath = Path()
        ..moveTo(size.width, size.height - radius)
        ..arcToPoint(
          Offset(size.width - radius, size.height),
          radius: Radius.circular(radius),
          clockwise: true,
        );
      canvas.drawPath(bottomRightPath, bottomRightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient ||
        oldDelegate.fullBorder != fullBorder;
  }
}

class _EngineGaugePainter extends CustomPainter {
  final double score;

  _EngineGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Based on the 180x180 gauge, the stroke is exactly ~12px relative.
    final strokeWidth = size.width * (12.0 / 180.0);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - strokeWidth;

    // 1. Draw inner dark background (Ellipse 825)
    final innerBgRect = Rect.fromCircle(center: center, radius: innerRadius);
    final innerBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight, // ~318 deg
        end: Alignment.topLeft,
        colors: [Color(0xFF101113), Color(0xFF2B2F33)],
      ).createShader(innerBgRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, innerBgPaint);

    // 2. Draw inactive track ring (Ellipse 824 eq.)
    final ringRadius = outerRadius - strokeWidth / 2;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
    final ringGradient = const LinearGradient(
      begin: Alignment.topLeft, // 131 deg
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF7655), Color(0xFFFF0000)],
    );

    // Dim inactive track by keeping the gradient but using opacity directly on colors
    final inactivePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x33FF7655), // 0.2 alpha (0x33)
          Color(0x33FF0000),
        ],
      ).createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, ringRadius, inactivePaint);

    // 3. Draw active track sweep (Ellipse 826)
    final activePaint = Paint()
      ..shader = ringGradient.createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Starts at top (-pi/2) and sweeps clockwise based on score.
    final sweepAngle = 2 * 3.141592653589793 * score;
    canvas.drawArc(
      ringRect,
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EngineGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
