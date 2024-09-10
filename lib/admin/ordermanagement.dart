// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../components.dart';
// import 'ordersmanagement/requestforcancel.dart';
//
// class OrderManagementPage extends StatefulWidget {
//   @override
//   _OrderManagementPageState createState() => _OrderManagementPageState();
// }
//
// class _OrderManagementPageState extends State<OrderManagementPage> {
//   final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
//   List<Map<String, dynamic>> orders = [];
//   String _selectedStatus = 'All'; // Default filter option
//   String _selectedRequestFilter = 'All'; // New filter option for requests
//   final List<String> statusOptions = ['All', 'Pending', 'Processing' ];
//   final List<String> requestFilterOptions = ['All', 'With Request', 'Without Request'];
//   final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
//   final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
//   final DatabaseReference _riderRef = FirebaseDatabase.instance.ref("riders");
//
//   @override
//   void initState() {
//     super.initState();
//     fetchOrders();
//   }
//
//   Future<void> fetchOrders() async {
//     try {
//       final snapshot = await _ordersRef.once();
//       if (snapshot.snapshot.value != null) {
//         final Map ordersMap = snapshot.snapshot.value as Map;
//         List<Map<String, dynamic>> fetchedOrders = ordersMap.entries
//             .map((entry) => Map<String, dynamic>.from(entry.value))
//             .toList();
//
//         fetchedOrders.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
//
//         // Filter orders based on selected status
//         if (_selectedStatus != 'All') {
//           fetchedOrders = fetchedOrders.where((order) => order['status'] == _selectedStatus).toList();
//         }
//
//         // Filter orders based on selected request filter
//         if (_selectedRequestFilter == 'With Request') {
//           fetchedOrders = fetchedOrders.where((order) => order.containsKey('cancellationRequest') && order['cancellationRequest'] != null).toList();
//         } else if (_selectedRequestFilter == 'Without Request') {
//           fetchedOrders = fetchedOrders.where((order) => !(order.containsKey('cancellationRequest') && order['cancellationRequest'] != null)).toList();
//         }
//
//         setState(() {
//           orders = fetchedOrders;
//         });
//       }
//     } catch (e) {
//       print('Error fetching orders: $e');
//     }
//   }
//
//   Future<void> updateOrderStatus(String orderId, String status) async {
//     try {
//       await _ordersRef.child(orderId).update({'status': status});
//       fetchOrders(); // Refresh the order list
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order status updated!")));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating order status: $e")));
//     }
//   }
//
//   Future<void> cancelOrder(String orderId) async {
//     try {
//       await _ordersRef.child(orderId).update({
//         'status': 'Cancelled',
//         'cancelledBy': 'Admin' // or 'Buyer' depending on the context
//       });
//       fetchOrders(); // Refresh the order list
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order canceled!")));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error canceling order: $e")));
//     }
//   }
//
//   Color getStatusColor(String status) {
//     switch (status) {
//       case 'Pending':
//         return Colors.grey;
//       case 'Processing':
//         return Colors.amber;
//       case 'Shipped':
//         return Colors.purple;
//       case 'Picked Up':
//         return Colors.blue; // Set color for Picked Up
//       case 'In Transit':
//         return Colors.orange; // Set color for In Transit
//       case 'Delivered':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   Future<Map<String, dynamic>> fetchUserData(String userId) async {
//     final databaseReference = FirebaseDatabase.instance.ref();
//
//     DatabaseEvent adminEvent = await databaseReference.child('admin/$userId').once();
//     if (adminEvent.snapshot.exists) {
//       return Map<String, dynamic>.from(adminEvent.snapshot.value as Map);
//     }
//
//     DatabaseEvent userEvent = await databaseReference.child('users/$userId').once();
//     if (userEvent.snapshot.exists) {
//       return Map<String, dynamic>.from(userEvent.snapshot.value as Map);
//     }
//
//     DatabaseEvent riderEvent = await databaseReference.child('riders/$userId').once();
//     if (riderEvent.snapshot.exists) {
//       return Map<String, dynamic>.from(riderEvent.snapshot.value as Map);
//     }
//
//     throw Exception('User not found');
//   }
//
//   void _showOrderDetails(Map<String, dynamic> order) async {
//     final userDetails = await fetchUserData(order['userId']);
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Colors.brown[50],
//           title: Text(
//             "Order ID: ${order['orderId']}",
//             style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (userDetails != null) ...[
//                   Text("Name: ${userDetails['name'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
//                   Text("Address: ${userDetails['address'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
//                   Text("Phone No: ${userDetails['phone'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
//                   Text("Zip Code: ${userDetails['zip_code'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
//                   SizedBox(height: 10),
//                 ],
//                 Text("Total: Rs. ${order['total']?.toStringAsFixed(2) ?? '0.00'}", style: GoogleFonts.lora(fontSize: 16)),
//                 Text("Date: ${order['timestamp'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
//                 Text("Status: ${order['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16)),
//                 if (order.containsKey('cancellationRequest') && order['cancellationRequest'] != null)
//                   Text("Cancellation Request Status: ${order['cancellationRequest']['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16, color: Colors.red)),
//                 SizedBox(height: 10),
//                 Text("Cart Items:", style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
//                 SizedBox(height: 10),
//                 ...Map<String, dynamic>.from(order['items'] ?? {}).entries.map((entry) {
//                   final item = entry.value;
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 4.0),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: EdgeInsets.all(8.0),
//                       leading: item['imageUrl'] != null
//                           ? Image.network(
//                         item['imageUrl'],
//                         width: 60,
//                         height: 60,
//                         fit: BoxFit.cover,
//                       )
//                           : Icon(Icons.image_not_supported, size: 60, color: Colors.brown[300]),
//                       title: Text(item['name'] ?? 'N/A', style: GoogleFonts.lora(fontSize: 16, color: Colors.brown[800])),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Category: ${item['category'] ?? 'N/A'}", style: TextStyle(color: Colors.brown[600])),
//                           Text("Price: Rs. ${item['rate'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
//                           Text("Quantity: ${item['quantity'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ],
//             ),
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context); // Close the dialog
//               },
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.brown,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//               ),
//               child: Text('Close', style: GoogleFonts.lora(fontSize: 16)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   String getBannerMessage(String status, Map<String, dynamic>? cancellationRequest) {
//     switch (status) {
//       case 'Cancelled':
//         return 'Cancelled';
//       case 'Picked Up':
//         return 'Picked Up';
//       case 'In Transit':
//         return 'In Transit';
//       default:
//         if (cancellationRequest != null && cancellationRequest['status'] == 'Rejected') {
//           return 'Request Rejected';
//         }
//         return '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar.customAppBar("Order Management"),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: DropdownButton<String>(
//                     value: _selectedStatus,
//                     items: statusOptions.map((String status) {
//                       return DropdownMenuItem<String>(
//                         value: status,
//                         child: Text(
//                           status,
//                           style: TextStyle(color: getStatusColor(status)),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (String? newStatus) {
//                       if (newStatus != null) {
//                         setState(() {
//                           _selectedStatus = newStatus;
//                           fetchOrders(); // Fetch orders based on selected status
//                         });
//                       }
//                     },
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: DropdownButton<String>(
//                     value: _selectedRequestFilter,
//                     items: requestFilterOptions.map((String filter) {
//                       return DropdownMenuItem<String>(
//                         value: filter,
//                         child: Text(
//                           filter,
//                           style: TextStyle(color: Colors.black),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (String? newFilter) {
//                       if (newFilter != null) {
//                         setState(() {
//                           _selectedRequestFilter = newFilter;
//                           fetchOrders();
//                         });
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: orders.isNotEmpty
//                 ? ListView.builder(
//               padding: EdgeInsets.all(16.0),
//               itemCount: orders.length,
//               itemBuilder: (context, index) {
//                 final order = orders[index];
//                 final hasCancellationRequest = order.containsKey('cancellationRequest') && order['cancellationRequest'] != null;
//                 final cancellationRequestStatus = hasCancellationRequest
//                     ? order['cancellationRequest']['status']
//                     : null;
//                 return Stack(
//                   children: [
//                     Banner(
//                       message: order['status'] == 'Cancelled'
//                           ? 'Cancelled'
//                           : cancellationRequestStatus == 'Rejected'
//                           ? 'Request Rejected'
//                           : order['status'] == 'In Transit'
//                           ? 'In Transit'
//                           : order['status'] == 'PickedUp'
//                           ? 'Picked UP'
//                           : order['status'] == 'Delivered'
//                           ? 'Delivered'
//                           : '',
//                       color: order['status'] == 'Cancelled'
//                           ? Colors.red
//                           : cancellationRequestStatus == 'Rejected'
//                           ? Colors.yellow
//                           : order['status'] == 'In Transit'
//                           ? Colors.orange
//                           : order['status'] == 'PickedUp'
//                           ? Colors.blue
//                           : order['status'] == 'Delivered'
//                           ? Colors.green
//                           : Colors.transparent,
//                       location: BannerLocation.topEnd,
//                       child: Card(
//                         margin: EdgeInsets.symmetric(vertical: 8.0),
//                         child: ListTile(
//                           onTap: () {
//                             _showOrderDetails(order);
//                           },
//                           title: Text(
//                             "Order ID: ${order['orderId']}",
//                             style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("User ID: ${order['userId']}", style: GoogleFonts.lora(fontSize: 14)),
//                               Text("Total: Rs. ${order['total']}", style: GoogleFonts.lora(fontSize: 14)),
//                               Text("Timestamp: ${order['timestamp']}", style: GoogleFonts.lora(fontSize: 14)),
//                               if (['Pending', 'Processing'].contains(order['status']))
//                               Row(
//                                 children: [
//                                   Text("Status: ", style: GoogleFonts.lora(fontSize: 14)),
//                                   DropdownButton<String>(
//                                     value: statusOptions.contains(order['status']) ? order['status'] : statusOptions.first,
//                                     items: statusOptions.map((String status) {
//                                       return DropdownMenuItem<String>(
//                                         value: status,
//                                         child: Text(
//                                           status,
//                                           style: TextStyle(color: getStatusColor(status)),
//                                         ),
//                                       );
//                                     }).toList(),
//                                     onChanged: (String? newStatus) {
//                                       if (newStatus != null) {
//                                         updateOrderStatus(order['orderId'], newStatus);
//                                       }
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           trailing: IconButton(
//                             icon: Icon(Icons.cancel, color: Colors.red),
//                             onPressed: order['status'] != 'Cancelled'
//                                 ? () => cancelOrder(order['orderId'])
//                                 : null,
//                           ),
//                         ),
//                       ),
//                     ),
//                     if (hasCancellationRequest)
//                       Positioned(
//                         bottom: 16,
//                         right: 16,
//                         child: TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => CancellationRequestsPage(orderId: order['orderId']),
//                               ),
//                             );
//                           },
//                           child: Text("Cancel Request Page", style: TextStyle(color: Colors.red)),
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             )
//                 : Center(child: CircularProgressIndicator()),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components.dart';
import 'ordersmanagement/requestforcancel.dart';
import 'ordersmanagement/requestforreturn.dart';

class OrderManagementPage extends StatefulWidget {
  @override
  _OrderManagementPageState createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  List<Map<String, dynamic>> orders = [];
  String _selectedStatus = 'All'; // Default filter option
  String _selectedRequestFilter = 'All'; // New filter option for requests
  final List<String> statusOptions = ['All', 'Pending', 'Processing'];
  final List<String> requestFilterOptions = ['All', 'With Request', 'Without Request'];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final snapshot = await _ordersRef.once();
      if (snapshot.snapshot.value != null) {
        final Map ordersMap = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> fetchedOrders = ordersMap.entries
            .map((entry) => Map<String, dynamic>.from(entry.value))
            .toList();

        fetchedOrders.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        // Filter orders based on selected status
        if (_selectedStatus != 'All') {
          fetchedOrders = fetchedOrders.where((order) => order['status'] == _selectedStatus).toList();
        }

        // Filter orders based on selected request filter
        if (_selectedRequestFilter == 'With Request') {
          fetchedOrders = fetchedOrders.where((order) => order.containsKey('cancellationRequest') || order.containsKey('returnRequest')).toList();
        } else if (_selectedRequestFilter == 'Without Request') {
          fetchedOrders = fetchedOrders.where((order) => !(order.containsKey('cancellationRequest') || order.containsKey('returnRequest'))).toList();
        }

        setState(() {
          orders = fetchedOrders;
        });
      }
    } catch (e) {
      // print('Error fetching orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersRef.child(orderId).update({'status': status});
      fetchOrders(); // Refresh the order list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order status updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating order status: $e")));
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _ordersRef.child(orderId).update({
        'status': 'Cancelled',
        'cancelledBy': 'Admin' // or 'Buyer' depending on the context
      });
      fetchOrders(); // Refresh the order list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order canceled!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error canceling order: $e")));
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
      case 'Picked Up':
        return Colors.blue; // Set color for Picked Up
      case 'In Transit':
        return Colors.orange; // Set color for In Transit
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    final databaseReference = FirebaseDatabase.instance.ref();

    DatabaseEvent adminEvent = await databaseReference.child('admin/$userId').once();
    if (adminEvent.snapshot.exists) {
      return Map<String, dynamic>.from(adminEvent.snapshot.value as Map);
    }

    DatabaseEvent userEvent = await databaseReference.child('users/$userId').once();
    if (userEvent.snapshot.exists) {
      return Map<String, dynamic>.from(userEvent.snapshot.value as Map);
    }

    DatabaseEvent riderEvent = await databaseReference.child('riders/$userId').once();
    if (riderEvent.snapshot.exists) {
      return Map<String, dynamic>.from(riderEvent.snapshot.value as Map);
    }

    throw Exception('User not found');
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    final userDetails = await fetchUserData(order['userId']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown[50],
          title: Text(
            "Order ID: ${order['orderId']}",
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userDetails != null) ...[
                  Text("Name: ${userDetails['name'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  Text("Address: ${userDetails['address'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  Text("Phone No: ${userDetails['phone'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  Text("Zip Code: ${userDetails['zip_code'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  const SizedBox(height: 10),
                ],
                Text("Total: Rs. ${order['total']?.toStringAsFixed(2) ?? '0.00'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Date: ${order['timestamp'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Status: ${order['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16)),
                if (order.containsKey('cancellationRequest') && order['cancellationRequest'] != null)
                  Text("Cancellation Request Status: ${order['cancellationRequest']['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16, color: Colors.red)),
                const SizedBox(height: 10),
                Text("Cart Items:", style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...Map<String, dynamic>.from(order['items'] ?? {}).entries.map((entry) {
                  final item = entry.value;
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
                }).toList(),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Close', style: GoogleFonts.lora(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  String getBannerMessage(String status, Map<String, dynamic>? cancellationRequest) {
    switch (status) {
      case 'Cancelled':
        return 'Cancelled';
      case 'Picked Up':
        return 'Picked Up';
      case 'In Transit':
        return 'In Transit';
      default:
        if (cancellationRequest != null && cancellationRequest['status'] == 'Rejected') {
          return 'Request Rejected';
        }
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Order Management"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    items: statusOptions.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(color: getStatusColor(status)),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newStatus) {
                      if (newStatus != null) {
                        setState(() {
                          _selectedStatus = newStatus;
                          fetchOrders(); // Fetch orders based on selected status
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedRequestFilter,
                    items: requestFilterOptions.map((String filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(
                          filter,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newFilter) {
                      if (newFilter != null) {
                        setState(() {
                          _selectedRequestFilter = newFilter;
                          fetchOrders();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isNotEmpty
                ? ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final hasCancellationRequest = order.containsKey('cancellationRequest') && order['cancellationRequest'] != null;
                final hasReturnRequest = order.containsKey('returnRequest') && order['returnRequest'] != null;
                final cancellationRequestStatus = hasCancellationRequest ? order['cancellationRequest']['status'] : null;

                return Stack(
                  children: [
                    Banner(
                      message: order['status'] == 'Cancelled'
                          ? 'Cancelled'
                          : cancellationRequestStatus == 'Rejected'
                          ? 'Request Rejected'
                          : order['status'] == 'In Transit'
                          ? 'In Transit'
                          : order['status'] == 'Picked Up'
                          ? 'Picked UP'
                          : order['status'] == 'Delivered'
                          ? 'Delivered'
                          : order['status'] == 'Returned'
                          ? 'Returned'
                          : '',
                      color: order['status'] == 'Cancelled'
                          ? Colors.red
                          : cancellationRequestStatus == 'Rejected'
                          ? Colors.yellow
                          : order['status'] == 'In Transit'
                          ? Colors.orange
                          : order['status'] == 'Picked Up'
                          ? Colors.blue
                          : order['status'] == 'Delivered'
                          ? Colors.green
                          : order['status'] == 'Returned'
                          ? Colors.red
                          : Colors.transparent,
                      location: BannerLocation.topEnd,
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          onTap: () {
                            _showOrderDetails(order);
                          },
                          title: Text(
                            "Order ID: ${order['orderId']}",
                            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("User ID: ${order['userId']}", style: GoogleFonts.lora(fontSize: 14)),
                              Text("Total: Rs. ${order['total']}", style: GoogleFonts.lora(fontSize: 14)),
                              Text("Timestamp: ${order['timestamp']}", style: GoogleFonts.lora(fontSize: 14)),
                              Text("Payment Status: ${order['payment_status']}", style: GoogleFonts.lora(fontSize: 18, color: Colors.green)),

                              if (['Pending', 'Processing'].contains(order['status']))
                                Row(
                                  children: [
                                    Text("Status: ", style: GoogleFonts.lora(fontSize: 14)),
                                    DropdownButton<String>(
                                      value: statusOptions.contains(order['status']) ? order['status'] : statusOptions.first,
                                      items: statusOptions.map((String status) {
                                        return DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(
                                            status,
                                            style: TextStyle(color: getStatusColor(status)),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newStatus) {
                                        if (newStatus != null) {
                                          updateOrderStatus(order['orderId'], newStatus);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: order['status'] != 'Cancelled'
                                ? () => cancelOrder(order['orderId'])
                                : null,
                          ),
                        ),
                      ),
                    ),
                    if (hasCancellationRequest)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CancellationRequestsPage(orderId: order['orderId']),
                              ),
                            );
                          },
                          child: const Text("Cancel Request Page", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    if (hasReturnRequest)
                      Positioned(
                        bottom: 16,
                        right: 20,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReturnRequestsPage(orderId: order['orderId']),
                              ),
                            );
                          },
                          child: const Text("Return Request Page", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                  ],
                );
              },
            )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
