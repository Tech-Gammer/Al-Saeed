import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:myfirstmainproject/POS/pos_panel.dart';
import '../components.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class pos_Orders extends StatefulWidget {
  const pos_Orders({super.key});

  @override
  _pos_OrdersState createState() => _pos_OrdersState();
}

class _pos_OrdersState extends State<pos_Orders> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref('POS_Orders');
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  int _currentIndex = 0; // Index of the current order

  DateTime? _startDate;
  DateTime? _endDate;
  bool _showAllOrders = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final snapshot = await _ordersRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final orders = data.values
            .map((order) => Map<String, dynamic>.from(order as Map))
            .toList();

        setState(() {
          _orders = orders;
          _filteredOrders = orders;
          if (_filteredOrders.isNotEmpty) {
            _currentIndex = _filteredOrders.length - 1; // Show latest order by default
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No orders found')),
        );
      }
    } catch (e) {
      // print('Error loading orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load orders.')),
      );
    }
  }

  void _showPreviousOrder() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _showNextOrder() {
    if (_currentIndex < _filteredOrders.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else {
      return 0.0;
    }
  }

  void _selectStartDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _startDate = selectedDate;
        _filterOrdersByDate();
      });
    }
  }

  void _selectEndDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _endDate = selectedDate;
        _filterOrdersByDate();  // Filter orders based on the new end date
        _showAllOrders = true;  // Ensure all orders are shown on one page
      });
    }
  }

  void _filterOrdersByDate() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _filteredOrders = _orders.where((order) {
          final createdAt = DateTime.tryParse(order['createdAt'] ?? '');
          return createdAt != null &&
              createdAt.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              createdAt.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
        _showAllOrders = true; // Always show all orders on one page after filtering
      });
    }
  }

  Future<void> _removeOrder() async {
    if (_filteredOrders.isNotEmpty) {
      final orderId = _filteredOrders[_currentIndex]['orderId']; // Assuming you have an 'id' field in your orders

      if (orderId != null) {
        try {
          await _ordersRef.child(orderId).remove();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order removed successfully')),
          );
          // Refresh the orders list after removal
          await _loadOrders();
          Navigator.push(context, MaterialPageRoute(builder: (context)=>const pos_Orders()));
          if (_filteredOrders.isEmpty) {
            setState(() {
              _currentIndex = 0; // Reset current index if no orders are left
            });
          } else {
            // Update the current index to ensure it's within bounds
            setState(() {
              _currentIndex = (_currentIndex >= _filteredOrders.length) ? _filteredOrders.length - 1 : _currentIndex;
            });
          }
        } catch (e) {
          // print('Error removing order: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove order.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order ID is missing')),
        );
      }
    }
  }

  void _showAllOrdersOnOnePage() {
    setState(() {
      _showAllOrders = true;
    });
  }

  Future<void> _printOrder() async {
    final order = _filteredOrders[_currentIndex];
    final items = (order['items'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final totalAmount = _toDouble(order['totalAmount']);
    final createdAt = order['createdAt'] ?? 'Unknown Date';

    // Total GST calculation by summing the item-level GST multiplied by quantity
    final totalGST = items.fold(0.0, (sum, item) {
      final gstPerUnit = _toDouble(item['tax_amount']);
      final quantity = _toDouble(item['quantity']);
      return sum + (gstPerUnit * quantity);
    });

    final pdf = pw.Document();
    final logoImage = await _loadImage('images/logomain.png'); // Load logo image

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
            marginBottom: 10, marginLeft: 10, marginRight: 10, marginTop: 10
        ),
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Logo and Store Info
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Image(logoImage, width: 60), // Display smaller logo
                    pw.Text(
                      'AL-SAEED SWEETS & BAKERS',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Gap Chowk, Near Muslim Road, Gujranwala',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text('Ph: 055-4226968', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Text('NTN: 3537483-7   STRN: 3277876143974',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Cashier and Date Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier: Admin', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Date: $createdAt', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text('Invoice No: ${order['orderId'] ?? 'Unknown'}',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),

              // Item table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.5),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    children: [
                      _buildTableCell('Item', fontWeight: pw.FontWeight.bold),
                      _buildTableCell('Qty', fontWeight: pw.FontWeight.bold),
                      _buildTableCell('Rate', fontWeight: pw.FontWeight.bold),
                      _buildTableCell('GST 18%', fontWeight: pw.FontWeight.bold),
                      _buildTableCell('Amount', fontWeight: pw.FontWeight.bold),
                    ],
                  ),
                  ...items.map((item) {
                    final rate = _toDouble(item['sale_rate']);
                    final gstPerUnit = _toDouble(item['tax_amount']);
                    final quantity = _toDouble(item['quantity']);
                    final totalGSTForItem = gstPerUnit * quantity; // Calculate GST for each item
                    final totalAmountForItem = (rate * quantity) + totalGSTForItem; // Total amount per item including GST

                    return pw.TableRow(
                      children: [
                        _buildTableCell(item['item_name'] ?? 'Unknown'),
                        _buildTableCell(quantity.toStringAsFixed(0)),
                        _buildTableCell(rate.toStringAsFixed(0)),
                        _buildTableCell(totalGSTForItem.toStringAsFixed(0)), // Show calculated GST for each item
                        _buildTableCell(totalAmountForItem.toStringAsFixed(0)), // Total with GST
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 5),

              // Summary of GST and Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total GST:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(totalGST.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(totalAmount.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 5),

              // Footer with Balance and POS Info
              pw.Text('POS Charges: 1.00', style: const pw.TextStyle(fontSize: 8)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Net:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text((totalAmount + 1).toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text('Received: ${order['receivedAmount'] ?? 'Unknown'}',
                  style: const pw.TextStyle(fontSize: 8)),
              // pw.Text(
              //     'Balance: ${(order['receivedAmount'] ?? 0) - (totalAmount + 1)}',
              //     style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'Balance: ${((order['receivedAmount'] ?? 0) - (totalAmount +
                    1)).toStringAsFixed(0)}',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              // Thank You and FBR Invoice
              pw.Center(
                child: pw.Text('Thank You', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text('We wish to see you again', style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('FBR Invoice Number: ${order['fbrInvoiceNumber'] ?? 'Unknown'}',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Center(
                child: pw.Text(
                  order['fbrInvoiceHash'] ?? 'Unknown',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      // print('PDF printed successfully');
    } catch (e) {
      // print('Error printing PDF: $e');
    }
  }



  pw.Widget _buildTableCell(String text, {pw.FontWeight fontWeight = pw.FontWeight.normal}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: fontWeight),
      ),
    );
  }


  Future<pw.ImageProvider> _loadImage(String path) async {
    final byteData = await rootBundle.load(path);
    final image = pw.MemoryImage(byteData.buffer.asUint8List());
    return image;
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    if (_filteredOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor:const Color(0xFFe6b67e),
          leading: IconButton(onPressed: (){
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const POSPage()),
                  (Route<dynamic> route) => false, // This removes all previous routes
            );

          }, icon: const Icon(Icons.arrow_back)),
          title: const Text('Point of Sale'),
          titleTextStyle: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),


        body: const Center(child: Text('No orders available')),
        floatingActionButton: FloatingActionButton(
          onPressed: _selectStartDate,
          child: const Icon(Icons.filter_list),
        ),
      );
    }

    if (_showAllOrders) {
      return Scaffold(
        appBar: CustomAppBar.customAppBar("POS ORDERS"),
        body: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 12.0),
          child: ListView(
            children: _filteredOrders.map((order) {
              final items = (order['items'] as List<dynamic>)
                  .map((item) => Map<String, dynamic>.from(item as Map))
                  .toList();
              final totalAmount = _toDouble(order['totalAmount']);
              final createdAt = order['createdAt'] ?? 'Unknown Date';

              return Card(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Date: $createdAt', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      ...items.map((item) {
                        final netRate = _toDouble(item['net_rate']);
                        final total = _toDouble(item['total']);
                        final quantity = item['quantity'] ?? 0;
                        return ListTile(
                          title: Text(item['item_name'] ?? 'Unknown'),
                          subtitle: Text('Rate: ${netRate.toStringAsFixed(0)} | Quantity: $quantity'),
                          trailing: Text('Total: ${total.toStringAsFixed(0)}',style: const TextStyle(fontSize: 13),),
                        );
                      }),
                      const SizedBox(height: 8.0),
                      Text('Order Total: ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _showAllOrders = false; // Return to showing one order at a time
            });
          },
          child: const Icon(Icons.list),
        ),
      );
    }

    final order = _filteredOrders[_currentIndex];
    final items = (order['items'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final totalAmount = _toDouble(order['totalAmount']);
    final createdAt = order['createdAt'] ?? 'Unknown Date';

    return Scaffold(
      appBar: CustomAppBar.customAppBar("POS ORDERS"),
      body: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 24.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: _showAllOrdersOnOnePage,
                child: const Text('All Orders'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectStartDate,
                    child: Text('Start Date: ${_startDate?.toLocal().toString().split(' ')[0] ?? 'Select'}'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectEndDate,
                    child: Text('End Date: ${_endDate?.toLocal().toString().split(' ')[0] ?? 'Select'}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Date: $createdAt', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8.0),
                          ...items.map((item) {
                            final netRate = _toDouble(item['net_rate']);
                            final total = _toDouble(item['total']);
                            final quantity = item['quantity'] ?? 0;
                            return ListTile(
                              title: Text(item['item_name'] ?? 'Unknown'),
                              subtitle: Text('Rate: ${netRate.toStringAsFixed(0)} | Quantity: $quantity'),
                              trailing: Text('Total: ${total.toStringAsFixed(0)}',style: const TextStyle(fontSize: 13),),
                            );
                          }),
                          const SizedBox(height: 8.0),
                          Text('Order Total: ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                 onPressed: _printOrder,
                child: const Text('Print Bill'),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _showPreviousOrder,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _removeOrder, // Add this line to call the remove method
                  child: const Text('Remove Order'),
                ),

                ElevatedButton(
                  onPressed: _showNextOrder,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
