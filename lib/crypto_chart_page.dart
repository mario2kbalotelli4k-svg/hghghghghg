import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';

class CryptoChartPage extends StatefulWidget {
  final String id;
  final String name;
  final String symbol;

  const CryptoChartPage({
    super.key,
    required this.id,
    required this.name,
    required this.symbol,
  });

  @override
  State<CryptoChartPage> createState() => _CryptoChartPageState();
}

class _CryptoChartPageState extends State<CryptoChartPage> {
  List<CandleChartData> chartData = [];
  bool isLoading = true;
  String selectedInterval = '3m';

  final Map<String, String> intervalLabels = {
    '1m': '1 دقيقة',
    '3m': '3 دقائق',
    '5m': '5 دقائق',
    '15m': '15 دقيقة',
    '30m': '30 دقيقة',
    '1h': '1 ساعة',
    '4h': '4 ساعات',
    '1d': '1 يوم',
    '7d': '7 أيام',
  };

  ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
    enablePanning: true,
    enablePinching: true,
    zoomMode: ZoomMode.x,
  );

  TrackballBehavior _trackballBehavior = TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
    tooltipSettings: InteractiveTooltip(
      enable: true,
      color: Colors.black87,
      borderWidth: 0,
      borderColor: Colors.transparent,
      format:
          'التاريخ: point.x\nالإغلاق: point.close\nالفتح: point.open\nالأعلى: point.high\nالأدنى: point.low\nالحجم: point.volume',
      textStyle: TextStyle(color: Colors.white),
    ),
    lineType: TrackballLineType.vertical,
    lineColor: Colors.amber,
    lineWidth: 1,
  );

  double? lastPrice;
  double? firstPrice;

  // For screenshot
  final GlobalKey chartKey = GlobalKey();

  // For dynamic Y-Axis
  double? minY;
  double? maxY;

  @override
  void initState() {
    super.initState();
    fetchChartData(selectedInterval);
  }

  Future<void> fetchChartData(String interval) async {
    setState(() {
      isLoading = true;
    });

    final symbol = widget.symbol.toUpperCase() + 'USDT';
    final url =
        'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=500';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<CandleChartData> candles = data.map<CandleChartData>((item) {
        return CandleChartData(
          x: DateTime.fromMillisecondsSinceEpoch(item[0]),
          open: double.parse(item[1]),
          high: double.parse(item[2]),
          low: double.parse(item[3]),
          close: double.parse(item[4]),
          volume: double.parse(item[5]), // volume
        );
      }).toList();

      // Calculate dynamic Y-Axis range
      if (candles.isNotEmpty) {
        double minLow =
            candles.map((e) => e.low).reduce((a, b) => a < b ? a : b);
        double maxHigh =
            candles.map((e) => e.high).reduce((a, b) => a > b ? a : b);

        // Add margin for better view
        double margin = (maxHigh - minLow) * 0.15;
        if (margin == 0) margin = maxHigh * 0.05;
        minY = (minLow - margin).clamp(0, double.infinity);
        maxY = maxHigh + margin;
      } else {
        minY = null;
        maxY = null;
      }

      setState(() {
        chartData = candles;
        isLoading = false;
        if (candles.isNotEmpty) {
          lastPrice = candles.last.close;
          firstPrice = candles.first.open;
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _shareChartImage() async {
    try {
      RenderRepaintBoundary boundary =
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temp file and share
      final tempDir = await Future.sync(() => Directory.systemTemp);
      final file = await File('${tempDir.path}/chart.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'شاهد مخطط ${widget.name}\n'
            '📱 تابع الأسعار أول بأول من تطبيق "العملة الذكية":\n'
            'https://play.google.com/store/apps/details?id=com.yourapp.id',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء مشاركة الصورة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceChange = (lastPrice != null && firstPrice != null)
        ? (((lastPrice! - firstPrice!) / firstPrice!) * 100)
        : 0.0;
    final priceColor = priceChange >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
        elevation: 0,
        title: Text(
          '${widget.name} (${widget.symbol.toUpperCase()})',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة تعيين الزوم',
            onPressed: () {
              _zoomPanBehavior.reset();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة صورة الشارت',
            onPressed: _shareChartImage,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: selectedInterval,
              dropdownColor: isDark ? Colors.grey[900] : Colors.white,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down,
                  color: isDark ? Colors.white : Colors.black),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedInterval = value;
                  });
                  fetchChartData(value);
                }
              },
              items: intervalLabels.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 18.0, left: 16, right: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: priceColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              lastPrice != null
                                  ? lastPrice!.toStringAsFixed(4)
                                  : '--',
                              style: TextStyle(
                                color: priceColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              priceChange > 0
                                  ? Icons.arrow_upward
                                  : priceChange < 0
                                      ? Icons.arrow_downward
                                      : Icons.remove,
                              color: priceColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              priceChange >= 0
                                  ? '+${priceChange.toStringAsFixed(2)}%'
                                  : '${priceChange.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: priceColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RepaintBoundary(
                    key: chartKey,
                    child: Card(
                      margin: const EdgeInsets.all(12),
                      color: isDark ? const Color(0xFF23262F) : Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SfCartesianChart(
                          backgroundColor: Colors.transparent,
                          zoomPanBehavior: _zoomPanBehavior,
                          trackballBehavior: _trackballBehavior,
                          primaryXAxis: DateTimeAxis(
                            majorGridLines: const MajorGridLines(
                                width: 0.5, color: Colors.grey),
                            axisLine:
                                const AxisLine(width: 0.5, color: Colors.grey),
                            intervalType: DateTimeIntervalType.auto,
                            autoScrollingMode: AutoScrollingMode.end,
                            autoScrollingDelta: 60,
                            rangePadding: ChartRangePadding.none,
                          ),
                          primaryYAxis: NumericAxis(
                            opposedPosition: true,
                            majorGridLines: const MajorGridLines(
                                width: 0.5, color: Colors.grey),
                            axisLine:
                                const AxisLine(width: 0.5, color: Colors.grey),
                            minimum: minY,
                            maximum: maxY,
                            interval: (minY != null && maxY != null)
                                ? ((maxY! - minY!) / 5)
                                    .clamp(0.01, double.infinity)
                                : null,
                          ),
                          series: <CartesianSeries>[
                            CandleSeries<CandleChartData, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (CandleChartData data, _) => data.x,
                              highValueMapper: (CandleChartData data, _) =>
                                  data.high,
                              lowValueMapper: (CandleChartData data, _) =>
                                  data.low,
                              openValueMapper: (CandleChartData data, _) =>
                                  data.open,
                              closeValueMapper: (CandleChartData data, _) =>
                                  data.close,
                              bullColor:
                                  isDark ? Colors.greenAccent : Colors.green,
                              bearColor: isDark ? Colors.redAccent : Colors.red,
                              enableTooltip: true,
                              spacing: 0.1,
                            ),
                            ColumnSeries<CandleChartData, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (CandleChartData data, _) => data.x,
                              yValueMapper: (CandleChartData data, _) =>
                                  data.volume,
                              color: Colors.blueGrey.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CandleChartData {
  final DateTime x;
  final double high;
  final double low;
  final double open;
  final double close;
  final double volume;

  CandleChartData({
    required this.x,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });
}
