import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';

class BatteryMonitorScreen extends ConsumerStatefulWidget {
  final String batteryId;
  final String batteryName;

  const BatteryMonitorScreen({
    super.key,
    required this.batteryId,
    required this.batteryName,
  });

  @override
  ConsumerState<BatteryMonitorScreen> createState() => _BatteryMonitorScreenState();
}

class _BatteryMonitorScreenState extends ConsumerState<BatteryMonitorScreen> {
  io.Socket? _socket;
  bool _connected = false;
  Map<String, dynamic>? _currentStats;
  final List<FlSpot> _voltageSpots = [];
  final List<FlSpot> _currentSpots = [];
  double _timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.emit('unsubscribeBattery', widget.batteryId);
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _initSocket() {
    final user = ref.read(currentUserProvider);
    
    _socket = io.io(
      '${AppConstants.baseUrl.replaceAll('/api', '')}/iot',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': user?.id})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      setState(() => _connected = true);
      _socket!.emit('subscribeBattery', widget.batteryId);
    });

    _socket!.on('battery:telemetry', (data) {
      if (mounted && data is Map) {
        setState(() {
          _currentStats = Map<String, dynamic>.from(data);
          
          _timeCounter += 1;
          final voltage = (data['voltage'] as num).toDouble();
          final current = (data['current'] as num).toDouble();
          
          _voltageSpots.add(FlSpot(_timeCounter, voltage));
          _currentSpots.add(FlSpot(_timeCounter, current));
          
          if (_voltageSpots.length > 20) {
            _voltageSpots.removeAt(0);
            _currentSpots.removeAt(0);
          }
        });
      }
    });

    _socket!.on('disconnect', (_) {
      setState(() => _connected = false);
    });

    _socket!.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.batteryName, style: const TextStyle(fontSize: 16)),
            Text(
              _connected ? 'Đang kết nối PLC' : 'Mất kết nối',
              style: TextStyle(
                fontSize: 11,
                color: _connected ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ),
      ),
      body: _currentStats == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Đang chờ dữ liệu từ PLC...', style: TextStyle(color: AppTheme.grey600)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Indicators Row
                  Row(
                    children: [
                      _buildGaugeCard(
                        'SOC',
                        '${(_currentStats!['soc'] as num).toInt()}%',
                        (_currentStats!['soc'] as num).toDouble() / 100,
                        AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoCard(
                        'Nhiệt độ',
                        '${_currentStats!['temperature']}°C',
                        Icons.thermostat_outlined,
                        AppTheme.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Charts
                  _buildChartCard(
                    'Biểu đồ Điện áp (V)',
                    _voltageSpots,
                    AppTheme.primaryGreen,
                    42, 58,
                  ),
                  const SizedBox(height: 20),
                  _buildChartCard(
                    'Biểu đồ Dòng điện (A)',
                    _currentSpots,
                    AppTheme.accentYellow,
                    0, 10,
                  ),
                  
                  const SizedBox(height: 20),
                  // Raw data table
                  _buildRawDataCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildGaugeCard(String label, String value, double percent, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 8.0,
              percent: percent,
              center: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              progressColor: color,
              backgroundColor: color.withOpacity(0.1),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppTheme.grey600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: AppTheme.grey600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, List<FlSpot> spots, Color color, double min, double max) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: min,
                maxY: max,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông số chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildDataRow('Điện áp (Voltage)', '${_currentStats!['voltage']} V'),
          _buildDataRow('Dòng điện (Current)', '${_currentStats!['current']} A'),
          _buildDataRow('Nhiệt độ (Temp)', '${_currentStats!['temperature']} °C'),
          _buildDataRow('Dung lượng (SOC)', '${_currentStats!['soc']}%'),
          _buildDataRow('Sức khỏe (SOH)', '${_currentStats!['soh']}%'),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.grey600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
