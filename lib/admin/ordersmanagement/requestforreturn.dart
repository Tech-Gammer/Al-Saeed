import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../ordermanagement.dart';

class ReturnRequestsPage extends StatefulWidget {
  final String orderId;

  ReturnRequestsPage({required this.orderId});

  @override
  _ReturnRequestsPageState createState() => _ReturnRequestsPageState();
}

class _ReturnRequestsPageState extends State<ReturnRequestsPage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  final DatabaseReference _ridersRef = FirebaseDatabase.instance.ref("riders");

  List<Map<String, dynamic>> returnRequests = [];
  Map<String, dynamic>? orderDetails;
  Map<String, dynamic>? riderDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReturnRequests();
    fetchOrderDetails();
  }
  Future<void> fetchOrderDetails() async {
    try {
      final snapshot = await _ordersRef.child(widget.orderId).once();
      if (snapshot.snapshot.value != null) {
        setState(() {
          orderDetails = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          fetchRiderDetails(orderDetails!['riderNumber']);
          // print(orderDetails!['riderNumber']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // print('Error fetching order details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchRiderDetails(String riderNumber) async {
    try {
      final query = _ridersRef.orderByChild('riderNumber').equalTo(riderNumber);
      final snapshot = await query.once();

      if (snapshot.snapshot.value != null) {
        final riderData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        if (riderData.isNotEmpty) {
          final firstRiderKey = riderData.keys.first;
          setState(() {
            riderDetails = Map<String, dynamic>.from(riderData[firstRiderKey] as Map);
          });
        }
      }
    } catch (e) {
      // print('Error fetching rider details: $e');
    }
  }

  Future<void> fetchReturnRequests() async {
    try {
      final snapshot = await _ordersRef.once();
      if (snapshot.snapshot.value != null) {
        final Map ordersMap = snapshot.snapshot.value as Map;
        returnRequests = ordersMap.entries
            .map((entry) => Map<String, dynamic>.from(entry.value))
            .where((order) =>
        order.containsKey('returnRequest') &&
            order['orderId'] == widget.orderId) // Filter based on passed orderId
            .toList();
        setState(() {});
      }
    } catch (e) {
      // print('Error fetching return requests: $e');
    }
  }

  Future<void> returnOrder(String orderId) async {
    try {
      final returnTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await _ordersRef.child(orderId).update({
        'status': 'returned',
      });
      fetchReturnRequests();
      showReturnConfirmation(orderId, returnTimestamp);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error returning order: $e")));
    }
  }

  Future<void> approveReturnRequest(String orderId) async {
    try {
      final orderRef = _ordersRef.child(orderId);
      final returnRequestRef = orderRef.child('returnRequest');

      await returnRequestRef.update({
        'status': 'Approved',
        'approvedAt': DateTime.now().toIso8601String(),
      });

      fetchReturnRequests();
    } catch (e) {
      // print('Error approving return request: $e');
    }
  }

  // Future<void> rejectReturnRequest(String orderId) async {
  //   try {
  //     final orderRef = _ordersRef.child(orderId);
  //     final returnRequestRef = orderRef.child('returnRequest');
  //
  //     await returnRequestRef.update({
  //       'status': 'Rejected',
  //       'rejectedAt': DateTime.now().toIso8601String(), // Optional: record when it was rejected
  //     });
  //
  //     fetchReturnRequests();
  //   } catch (e) {
  //     print('Error rejecting cancellation request: $e');
  //   }
  // }

  void showReturnConfirmation(String orderId, String returnTimestamp) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Returned'),
          content: Text('Order ID: $orderId\nReturned At: $returnTimestamp'),
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
      appBar: AppBar(
        title: const Text('Return Request Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${orderDetails!['orderId']}",
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Return Request Status: ${orderDetails!['returnRequest']['status'] ?? 'Not Requested'}",
              style: GoogleFonts.lora(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Return Request Reason: ${orderDetails!['returnRequest']['reason'] ?? 'N/A'}",
              style: GoogleFonts.lora(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "Rider Details:",
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            riderDetails != null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name: ${riderDetails!['name'] ?? 'N/A'}",
                  style: GoogleFonts.lora(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  "Email: ${riderDetails!['email'] ?? 'N/A'}",
                  style: GoogleFonts.lora(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  "Phone: ${riderDetails!['phone'] ?? 'N/A'}",
                  style: GoogleFonts.lora(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  "Address: ${riderDetails!['address'] ?? 'N/A'}",
                  style: GoogleFonts.lora(fontSize: 16),
                ),
              ],
            )
                : Text("Rider details not available", style: GoogleFonts.lora(fontSize: 16)),
            const SizedBox(height: 20),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     ElevatedButton(
            //       // onPressed: approveReturnRequest,
            //       onPressed: (){
            //         approveReturnRequest(widget.orderId);
            //         returnOrder(widget.orderId);
            //       },
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.green,
            //       ),
            //       child: Text('Approve Return'),
            //     ),
            //     ElevatedButton(
            //       onPressed: (){
            //         rejectReturnRequest(widget.orderId);
            //         returnOrder(widget.orderId);
            //       },
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.red,
            //       ),
            //       child: Text('Reject Return'),
            //     ),
            //   ],
            // ),
            // if (orderDetails!['returnRequest']['status'] == 'Pending') ...[
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       ElevatedButton(
            //         onPressed: () {
            //           approveReturnRequest(widget.orderId);
            //           returnOrder(widget.orderId);
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.green,
            //         ),
            //         child: Text('Approve Return'),
            //       ),
            //       ElevatedButton(
            //         onPressed: () {
            //           rejectReturnRequest(widget.orderId);
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.red,
            //         ),
            //         child: Text('Reject Return'),
            //       ),
            //     ],
            //   ),
            // ]
            // else ...[
            //   Text(
            //     "Return request has been ${orderDetails!['returnRequest']['status'].toLowerCase()}",
            //     style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold),
            //   ),
            // ],
            Text(
              "Item has been ${orderDetails!['returnRequest']['status'].toLowerCase()}",
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
          : const Center(child: Text('No return request details available')),
    );
  }
}
