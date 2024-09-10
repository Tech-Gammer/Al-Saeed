import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/components.dart';
import 'package:myfirstmainproject/homepage.dart';

class CustomerOrdersPage extends StatefulWidget {
  final bool comingFromCheckoutPage;

  CustomerOrdersPage({required this.comingFromCheckoutPage});

  @override
  _CustomerOrdersPageState createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  late User currentUser;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    fetchCustomerOrders();
  }

  Future<void> fetchCustomerOrders() async {
    try {
      final snapshot = await _ordersRef.once();
      if (snapshot.snapshot.value != null) {
        final allOrders = (snapshot.snapshot.value as Map<dynamic, dynamic>).values
            .map((order) => Map<String, dynamic>.from(order as Map))
            .toList();

        setState(() {
          orders = allOrders.where((order) {
            final userId = order['userId'] as String?;
            final adminId = order['adminId'] as String?;
            final riderId = order['riderId'] as String?;
            return userId == currentUser.uid || adminId == currentUser.uid || riderId == currentUser.uid;
          }).toList();

          orders.sort((a, b) {
            final timestampA = a['timestamp'] as String?;
            final timestampB = b['timestamp'] as String?;

            final dateTimeA = DateTime.tryParse(timestampA ?? '') ?? DateTime(1970);
            final dateTimeB = DateTime.tryParse(timestampB ?? '') ?? DateTime(1970);
            return dateTimeB.compareTo(dateTimeA); // Newest first
          });
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey;
      case 'Processing':
        return Colors.amber;
      case 'Shipped':
        return Colors.purple;
      case 'PickedUp':
        return Colors.blue;
      case 'In Transit':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showCancellationReasonDialog(String orderId) async {
    final TextEditingController reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Cancellation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for cancellation:'),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(hintText: 'Enter reason here'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reason is required')),
                  );
                } else {
                  Navigator.pop(context); // Close the dialog
                  await _requestOrderCancellation(orderId, reason);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red,
              ),
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestOrderCancellation(String orderId, String reason) async {
    try {
      final orderRef = _ordersRef.child(orderId);
      final cancellationRequestRef = orderRef.child('cancellationRequest');

      // Add cancellation request
      await cancellationRequestRef.set({
        'requestedAt': DateTime.now().toIso8601String(),
        'status': 'Pending',
        'reason': reason, // Save the reason
      });

      // Optionally, notify the user of successful request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancellation request for order $orderId has been sent to the admin')),
      );

      // Refresh the order list to reflect the changes
      fetchCustomerOrders();
    } catch (e) {
      print('Error requesting order cancellation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to request cancellation. Please try again later.')),
      );
    }
  }

  Widget buildOrderItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: item['imageUrl'] != null
            ? Image.network(
          item['imageUrl'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        )
            : Icon(Icons.image_not_supported, size: 60, color: Colors.brown[300]),
        title: Text(item['name'] ?? 'N/A', style: GoogleFonts.lora(fontSize: 16, color: Colors.brown[800])),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${item['category'] ?? 'N/A'}", style: TextStyle(color: Colors.brown[600])),
            Text("Price: Rs. ${item['rate'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
            Text("Quantity: ${item['quantity'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final hasCancellationRequest = order.containsKey('cancellationRequest') && order['cancellationRequest'] != null;
    final orderStatus = order['status'] as String? ?? 'Pending';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown[50],
          title: Text("Order Details:",style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total: Rs. ${order['total']?.toStringAsFixed(2) ?? '0.00'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Date: ${order['timestamp'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Status: ${order['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16)),
                if (hasCancellationRequest)
                  Text(
                    "Cancellation Request Status: ${order['cancellationRequest']['status']}",
                    style: GoogleFonts.lora(fontSize: 16, color: Colors.red),
                  ),
                const SizedBox(height: 10),
                Text("Cart Items:", style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...Map<String, dynamic>.from(order['items'] ?? {}).entries.map((entry) {
                  final item = entry.value;
                  return buildOrderItemCard(Map<String, dynamic>.from(item));
                }).toList(),
              ],
            ),
          ),
          actions: [
            if (['Pending', 'Processing'].contains(orderStatus) && !hasCancellationRequest) // Add cancel button only if order is in the correct status and no cancellation request exists
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog before showing the cancellation reason dialog
                  _showCancellationReasonDialog(order['orderId'] as String);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Text('Request Cancellation', style: GoogleFonts.lora(fontSize: 16)),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFe6b67e),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Simply close the dialog
                  },
                  child: Text('Close', style: GoogleFonts.lora(fontSize: 16, color: Colors.black)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: NewCustomTextStyles.newcustomTextStyle),
        backgroundColor: const Color(0xFFe6b67e),
        centerTitle: true,
        automaticallyImplyLeading: !widget.comingFromCheckoutPage,
        leading: widget.comingFromCheckoutPage
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
      ),
      body: orders.isNotEmpty
          ? ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final orderId = order['orderId'] as String? ?? 'Unknown';
          final total = (order['total'] is int)
              ? (order['total'] as int).toDouble()
              : order['total'] as double? ?? 0.0;
          final status = order['status'] as String? ?? 'Pending';
          final payment_status = order['payment_status'] as String? ?? 'Pending';

          final timestamp = order['timestamp'] as String? ?? '';
          final hasCancellationRequest = order.containsKey('cancellationRequest') && order['cancellationRequest'] != null;

          return Card(
            margin: const EdgeInsets.all(10.0),
            child: ListTile(
              title: Text("Order",style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total: Rs. ${total.toStringAsFixed(2)}', style: GoogleFonts.lora(fontSize: 16)),
                  Text('Status: $status', style: GoogleFonts.lora(fontSize: 16, color: getStatusColor(status))),
                  Text('Date: $timestamp', style: GoogleFonts.lora(fontSize: 16)),
                  Text('Payment Status: $payment_status', style: GoogleFonts.lora(fontSize: 16, color: Colors.green)),

                  if (hasCancellationRequest)
                    Text(
                      'Cancellation Request Sent',
                      style: GoogleFonts.lora(fontSize: 16, color: Colors.red),
                    ),
                  if (hasCancellationRequest)
                    Text(
                      "Cancellation Request Status: ${order['cancellationRequest']['status']}",
                      style: GoogleFonts.lora(fontSize: 16, color: Colors.red),
                    ),
                ],
              ),
              onTap: () {
                _showOrderDetails(order);
              },
            ),
          );
        },
      )
          : const Center(child: Text("No Orders Found")),
      floatingActionButton: widget.comingFromCheckoutPage
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const FrontPage()),
                (Route<dynamic> route) => false,
          );
        },
        backgroundColor: const Color(0xFFe6b67e),
        child: const Icon(Icons.home_sharp, color: Colors.white),
        tooltip: 'Go to Front Page',
      )
          : null,
    );
  }
}
