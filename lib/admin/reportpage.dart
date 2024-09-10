import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:printing/printing.dart';


class ReportSummaryPage extends StatefulWidget {
  @override
  _ReportSummaryPageState createState() => _ReportSummaryPageState();
}

class _ReportSummaryPageState extends State<ReportSummaryPage> {
  final DatabaseReference ordersRef = FirebaseDatabase.instance.ref('orders');

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _showReport = false;
  late Future<List<FlSpot>> _reportDataFuture;
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<Map<String, dynamic>> _cancelledOrders = []; // Declare this line

  int _totalDelivered = 0;
  int _totalCancelled = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  pw.Document? _generatedPdf;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
    _selectedEndDate = DateTime.now();
  }


  Future<List<FlSpot>> fetchReportData(DateTime startDate, DateTime endDate) async {
    final DatabaseReference ordersRef = FirebaseDatabase.instance.ref('orders');
    final ordersSnapshot = await ordersRef.get();
    final orders = ordersSnapshot.value as Map<dynamic, dynamic>?;

    List<FlSpot> spots = [];
    int index = 0;
    _totalDelivered = 0;
    _totalCancelled = 0;
    _deliveredOrders.clear();
    _cancelledOrders.clear(); // Clear the existing list

    orders?.forEach((key, value) {
      final orderDateStr = value['timestamp'] as String?;
      final amountStr = value['total'] as num?;
      final status = value['status'] as String?;
      final customerName = value['customer_name'] as String?;
      final quantity = value['quantity'] as int?;

      if (orderDateStr != null && amountStr != null && status != null) {
        final orderDate = DateTime.parse(orderDateStr);
        if (orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(const Duration(days: 1)))) {
          if (status == 'Delivered') {
            spots.add(FlSpot(index.toDouble(), amountStr.toDouble()));
            _deliveredOrders.add({
              'orderDate': orderDate,
              'total': amountStr,
              'orderId': key,
              'customerName': customerName ?? 'Unknown',
              'quantity': quantity ?? 0,
              'status': status,
            });
            _totalDelivered++;
          } else if (status == 'Cancelled') {
            _cancelledOrders.add({
              'orderDate': orderDate,
              'total': amountStr,
              'orderId': key,
              'customerName': customerName ?? 'Unknown',
              'quantity': quantity ?? 0,
              'status': status,
            });
            _totalCancelled++;
          }
          index++;
        }
      }
    });

    return spots;
  }


  void _fetchAndDisplayData() {
    setState(() {
      _showReport = true;
      _reportDataFuture = fetchReportData(_selectedStartDate!, _selectedEndDate!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Summary'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 10,
                  child: ListTile(
                    title: Text(
                      'Start Date: ${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Not selected'}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    trailing: const Icon(Icons.calendar_today, size:15),
                    onTap: () async {
                      DateTime? pickedDate = await _selectDate(context, _startDate, DateTime.now());
                      if (pickedDate != null && (_endDate == null || pickedDate.isBefore(_endDate!))) {
                        setState(() {
                          _startDate = pickedDate;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Start date cannot be after end date')),
                        );
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  elevation: 10,
                  child: ListTile(
                    title: Text(
                      'End Date: ${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Not selected'}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    trailing: const Icon(Icons.calendar_today, size:15),
                    onTap: () async {
                      DateTime? pickedDate = await _selectDate(context, _endDate, DateTime.now());
                      if (pickedDate != null && (_startDate == null || pickedDate.isAfter(_startDate!))) {
                        setState(() {
                          _endDate = pickedDate;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('End date cannot be before start date')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            // onPressed: _fetchAndDisplayData,
            onPressed: () {
              if (_startDate != null && _endDate != null) {
                _fetchAndDisplayData();

              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select both start and end dates')),
                );
              }
            },
            child: const Text('Generate Report'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_startDate != null && _endDate != null) {
                if (_totalDelivered > 0) {
                  _generatePdfReport(); // Call the PDF generation method
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No delivered orders to include in the report.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select both start and end dates')),
                );
              }

            },
            child: const Text('Generate PDF'),
          ),


          if (_showReport)
            Expanded(
              child: FutureBuilder<List<FlSpot>>(
                future: _reportDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available.'));
                  } else {
                    final spots = snapshot.data!;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Total Delivered Orders: $_totalDelivered',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Total Cancelled Orders: $_totalCancelled',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 300,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            '${_selectedStartDate!.add(Duration(days: value.toInt())).toString().split(' ')[0]}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 5,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                minX: 0,
                                maxX: spots.length.toDouble(),
                                minY: 0,
                                maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    belowBarData: BarAreaData(show: true),
                                    dotData: const FlDotData(show: true),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Delivered Orders:',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _deliveredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _deliveredOrders[index];
                              return ListTile(
                                title:Center(child: Text('Status: ${order['status']}', style: TextStyle(color: order['status'] == 'Delivered' ? Colors.green : Colors.red))),
                                titleTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order ID: ${order['orderId']}',),
                                    // Text('Customer: ${order['customerName']}'),
                                    // Text('Quantity: ${order['quantity']}'),
                                    Text('Order Date: ${order['orderDate'].toString().split(' ')[0]}'),
                                    Text('Total:  ${order['total']} Rs'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate, DateTime? maxDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: maxDate ?? DateTime(2101),
    );
    return picked;
  }


  Future<void> _generatePdfReport() async {
    if (_deliveredOrders.isEmpty && _totalCancelled == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders to generate a report.')),

      );
      return;
    }

    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('images/logomain.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageData);

    pdf.addPage(


      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Image(logoImage, width: 100, height: 100), // Adjust the width and height as needed
              pw.Text('Report Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Total Delivered Orders: $_totalDelivered'),
              pw.Text('Total Cancelled Orders: $_totalCancelled'),
              pw.SizedBox(height: 20),
              pw.Text('Delivered Orders:'),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['No.', 'Order ID', 'Order Date', 'Total (Rs)', 'Status'],
                data: List<List<String>>.generate(
                  _deliveredOrders.length,
                      (index) {
                    final order = _deliveredOrders[index];
                    return [
                      (index + 1).toString(),
                      order['orderId'].toString(),
                      order['orderDate'].toString().split(' ')[0],
                      order['total'].toString(),
                      order['status'],
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),  // No.
                  1: const pw.FixedColumnWidth(80),  // Order ID
                  2: const pw.FixedColumnWidth(80),  // Order Date
                  3: const pw.FixedColumnWidth(60),  // Total (Rs)
                  4: const pw.FixedColumnWidth(60),  // Status
                },
                border: pw.TableBorder.all(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Cancelled Orders:'),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['No.', 'Order ID', 'Order Date', 'Total (Rs)', 'Status'],
                data: List<List<String>>.generate(
                  _cancelledOrders.length,
                      (index) {
                    final order = _cancelledOrders[index];
                    return [
                      (index + 1).toString(),
                      order['orderId'].toString(),
                      order['orderDate'].toString().split(' ')[0],
                      order['total'].toString(),
                      order['status'],
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),  // No.
                  1: const pw.FixedColumnWidth(80),  // Order ID
                  2: const pw.FixedColumnWidth(80),  // Order Date
                  3: const pw.FixedColumnWidth(60),  // Total (Rs)
                  4: const pw.FixedColumnWidth(60),  // Status
                },
                border: pw.TableBorder.all(),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF file to a temporary directory
    final outputFile = File('${(await getTemporaryDirectory()).path}/report_summary.pdf');
    await outputFile.writeAsBytes(await pdf.save());

    // Open the PDF file
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(path: outputFile.path),
      ),
    );
  }


}

class DateRangePicker extends StatefulWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final ValueChanged<DateTimeRange?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  DateRangePicker({
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  _DateRangePickerState createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: widget.selectedStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: widget.selectedEndDate ?? DateTime.now(),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDateRange: _selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        widget.onChanged(_selectedDateRange);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Date Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}


class PDFViewerPage extends StatelessWidget {
  final String path;

  PDFViewerPage({required this.path});

  Future<void> _printPDF(BuildContext context) async {
    final bytes = await File(path).readAsBytes();

    // Save the PDF to local storage (Downloads folder or another directory)
    final outputFile = File('${(await getTemporaryDirectory()).path}/report_summary.pdf');
    await outputFile.writeAsBytes(bytes);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );

    // Optionally, show a Snackbar or a dialog to indicate the PDF has been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to ${outputFile.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Report'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: path,
            ),
          ),
          ElevatedButton(
            onPressed: () => _printPDF(context), // Pass the context
            child: const Text('Print PDF'),
          ),
        ],
      ),
    );
  }
}

