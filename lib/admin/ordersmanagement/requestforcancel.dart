import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:myfirstmainproject/components.dart';
import '../ordermanagement.dart';

class CancellationRequestsPage extends StatefulWidget {
  final String orderId;

  CancellationRequestsPage({required this.orderId});

  @override
  _CancellationRequestsPageState createState() => _CancellationRequestsPageState();
}

class _CancellationRequestsPageState extends State<CancellationRequestsPage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  List<Map<String, dynamic>> cancellationRequests = [];

  @override
  void initState() {
    super.initState();
    fetchCancellationRequests();
  }

  Future<void> fetchCancellationRequests() async {
    try {
      final snapshot = await _ordersRef.once();
      if (snapshot.snapshot.value != null) {
        final Map ordersMap = snapshot.snapshot.value as Map;
        cancellationRequests = ordersMap.entries
            .map((entry) => Map<String, dynamic>.from(entry.value))
            .where((order) =>
        order.containsKey('cancellationRequest') &&
            order['orderId'] == widget.orderId) // Filter based on passed orderId
            .toList();
        setState(() {});
      }
    } catch (e) {
      print('Error fetching cancellation requests: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final cancellationTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await _ordersRef.child(orderId).update({
        'status': 'Cancelled',
      });
      fetchCancellationRequests();
      showCancellationConfirmation(orderId, cancellationTimestamp);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error canceling order: $e")));
    }
  }

  Future<void> approveCancellationRequest(String orderId) async {
    try {
      final orderRef = _ordersRef.child(orderId);
      final cancellationRequestRef = orderRef.child('cancellationRequest');

      await cancellationRequestRef.update({
        'status': 'Approved',
        'approvedAt': DateTime.now().toIso8601String(),
      });

      fetchCancellationRequests();
    } catch (e) {
      // print('Error approving cancellation request: $e');
    }
  }

  Future<void> rejectCancellationRequest(String orderId) async {
    try {
      final orderRef = _ordersRef.child(orderId);
      final cancellationRequestRef = orderRef.child('cancellationRequest');

      await cancellationRequestRef.update({
        'status': 'Rejected',
        'rejectedAt': DateTime.now().toIso8601String(), // Optional: record when it was rejected
      });

      fetchCancellationRequests();
    } catch (e) {
      // print('Error rejecting cancellation request: $e');
    }
  }

  void showCancellationConfirmation(String orderId, String cancellationTimestamp) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Canceled'),
          content: Text('Order ID: $orderId\nCancelled At: $cancellationTimestamp'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => OrderManagementPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Cancellation Requests"),
      body: cancellationRequests.isNotEmpty
          ? ListView.builder(
        itemCount: cancellationRequests.length,
        itemBuilder: (context, index) {
          final order = cancellationRequests[index];
          final request = order['cancellationRequest'];
          final requestAcceptedAt = request.containsKey('approvedAt')
              ? request['approvedAt']
              : 'Not Accepted Yet';
          final requestRejectedAt = request.containsKey('rejectedAt')
              ? request['rejectedAt']
              : 'Not Rejected Yet';
          final reason = request['reason'] ?? 'No reason provided';

          return ListTile(
            title: Text('Order ID: ${order['orderId']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requested At: ${request['requestedAt']}', style: const TextStyle(fontSize: 16)),
                Text('Accepted At: $requestAcceptedAt', style: const TextStyle(fontSize: 16, color: Colors.red)),
                Text('Rejected At: $requestRejectedAt', style: const TextStyle(fontSize: 16, color: Colors.red)),
                const SizedBox(height: 8),
                Text('Reason: $reason', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: requestAcceptedAt == 'Not Accepted Yet' && requestRejectedAt == 'Not Rejected Yet'
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    cancelOrder(order['orderId']);
                    approveCancellationRequest(order['orderId']);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    rejectCancellationRequest(order['orderId']);
                  },
                ),
              ],
            )
                : null,
          );
        },
      )
          : const Center(child: Text("No Cancellation Requests")),
    );
  }
}
