import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myfirstmainproject/rider/returnedorderspage.dart';
import 'package:myfirstmainproject/rider/riderdrawer.dart';
import 'package:myfirstmainproject/rider/riderpage.dart';
import '../Model/ridermodel.dart';

  class SpecificRiderPage extends StatefulWidget {
    final String riderNumber;

    const SpecificRiderPage({super.key, required this.riderNumber});

    @override
    State<SpecificRiderPage> createState() => _SpecificRiderPageState();
  }

  class _SpecificRiderPageState extends State<SpecificRiderPage> {
    final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
    String _selectedStatus = 'PickedUp'; // Initial filter to show only "PickedUp" orders
    Order? order;



    Future<Map<String, dynamic>> fetchUserData(String userId) async {
      final databaseReference = FirebaseDatabase.instance.ref();

      DatabaseEvent event = await databaseReference.child('users/$userId').once();
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }

      event = await databaseReference.child('admin/$userId').once();
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }

      event = await databaseReference.child('riders/$userId').once();
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }

      throw Exception('User not found');
    }

    Future<List<Map<Order, User>>> fetchOrders(String riderNumber, {String statusFilter = 'PickedUp'}) async {
      final databaseReference = FirebaseDatabase.instance.ref();
      DatabaseEvent event = await databaseReference.child('orders')
          .orderByChild('riderNumber')
          .equalTo(riderNumber)
          .once();

      final ordersMap = event.snapshot.value as Map<dynamic, dynamic>?;

      List<Map<Order, User>> ordersWithUserData = [];

      if (ordersMap != null) {
        List<MapEntry> orderEntries = ordersMap.entries.toList();

        orderEntries.sort((a, b) {
          final orderA = Map<String, dynamic>.from(a.value as Map);
          final orderB = Map<String, dynamic>.from(b.value as Map);
          final timestampA = DateTime.parse(orderA['timestamp'] as String? ?? '1970-01-01T00:00:00Z');
          final timestampB = DateTime.parse(orderB['timestamp'] as String? ?? '1970-01-01T00:00:00Z');
          return timestampB.compareTo(timestampA);
        });

        for (var entry in orderEntries) {
          final orderId = entry.key;
          final orderDataMap = Map<String, dynamic>.from(entry.value as Map);
          final userId = orderDataMap['userId'] as String?;
          final orderStatus = orderDataMap['status'] as String?;

          // Filter orders based on status
          if (statusFilter == 'All' || orderStatus == statusFilter) {
            if (userId != null) {
              Order order = Order.fromMap(orderDataMap, orderId);
              User user = User.fromMap(await fetchUserData(userId));
              ordersWithUserData.add({order: user});
            }
          }
        }
      }

      return ordersWithUserData;
    }

    Future<void> updateOrderStatus(String orderId, String status) async {
      try {
        await _ordersRef.child(orderId).update({'status': status});
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Order status updated!"))
        );
        // Trigger a rebuild to reflect the updated status
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating order status: $e"))
        );
      }
    }

    void _showLocation(User user) async {
      try {
        final latitude = user.latitude;
        final longitude = user.longitude;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching location: ${e.toString()}'),
        ));
      }
    }


    Future<void> sendReturnRequest(String orderId, String reason) async {
      try {
        await _ordersRef.child(orderId).update({
          'returnRequest': {
            'returnedAt': DateTime.now().toIso8601String(),
            'reason': reason,
            'status': 'Returned',
          },
          'status': 'Returned'
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Return request sent!"))
        );
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error sending return request: $e"))
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        drawer: riderdrawerpage(),
        appBar: AppBar(
          title: SizedBox(
              width: 100,
              height: 70,
              child: Image.asset("images/logomain.png")),
          centerTitle: true,
          actions: [
            IconButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReturnedOrdersPage(riderNumber: widget.riderNumber),
                ),
              );
            }, icon: Icon(Icons.refresh))
          ],
        ),
        body: FutureBuilder<List<Map<Order, User>>>(
          future: fetchOrders(widget.riderNumber, statusFilter: _selectedStatus),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No orders available'));
            } else {
              final ordersWithUserData = snapshot.data!;
              return ListView.builder(
                itemCount: ordersWithUserData.length,
                itemBuilder: (context, index) {
                  final orderUserPair = ordersWithUserData[index];
                  final order = orderUserPair.keys.first;
                  final user = orderUserPair.values.first;
                  return Card(
                    elevation: 10,
                    child: ListTile(
                      title: Text('Order ID: ${order.orderId}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${user.name}'),
                          Text('Phone: ${user.phone}'),
                          Text('Address: ${user.address}'),
                          Text('Zip Code: ${user.zipCode}'),
                          Text('Email: ${user.email}'),
                          SizedBox(height: 10),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(item.imageUrl),
                                  ),
                                  title: Text('Item: ${item.name}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Category: ${item.category}'),
                                      Text('Description: ${item.description}'),
                                      Text('Quantity: ${item.quantity}'),
                                      Text('Rate: ${item.rate}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                          SizedBox(height: 10),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total: ${order.total.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  if (order.status != 'Delivered') // Only show dropdown if not delivered
                                    DropdownButton<String>(
                                      value: ['PickedUp', 'In Transit', 'Delivered'].contains(order.status)
                                          ? order.status
                                          : 'PickedUp', // Default to 'PickedUp' if the status is unrecognized
                                      items: <String>['PickedUp', 'In Transit', 'Delivered']
                                          .map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Container(
                                            color: _getStatusColor(value),
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(value),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null && newValue != order.status) {
                                          updateOrderStatus(order.orderId, newValue);
                                        }
                                      },
                                    ),
                                ],
                              ),
                              if (order.status == 'In Transit' &&
                                  (order.returnRequest == null || order.returnRequest!['status'] != 'Pending'))
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final reason = await showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            String returnReason = '';
                                            return AlertDialog(
                                              title: Text('Return Order Request'),
                                              content: TextField(
                                                onChanged: (value) {
                                                  returnReason = value;
                                                },
                                                decoration: InputDecoration(hintText: "Enter the reason for return"),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('Cancel'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('Submit'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop(returnReason);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (reason != null && reason.isNotEmpty) {
                                          sendReturnRequest(order.orderId, reason);
                                        }
                                      },
                                      child: Text('Make Order Return',style: TextStyle(color: Colors.red),),
                                    ),
                                    ElevatedButton(
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.zero,
                                                  side: BorderSide(color: Colors.blue)
                                              )
                                          )
                                      ),
                                      onPressed: () => _showLocation(user),
                                      child: Text('Show Location'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (order.status == 'Delivered')
                            Container(
                              color: Colors.green[100],
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Delivered',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          if (order.returnRequest != null && order.returnRequest!['status'] == 'Pending')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Return order application submitted (Status: Pending)',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (order.returnRequest != null && order.returnRequest!['status'] == 'Approved')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Return order application approved',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedStatus == 'Delivered'
              ? 2
              : _selectedStatus == 'In Transit'
              ? 1
              : 0,
          onTap: (index) {
            setState(() {
              if (index == 0) {
                _selectedStatus = 'PickedUp';
              } else if (index == 1) {
                _selectedStatus = 'In Transit';
              } else {
                _selectedStatus = 'Delivered';
              }
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'New Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping),
              label: 'In Transit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Delivered',
            ),
          ],
        ),
      );
    }

    Color _getStatusColor(String status) {
      switch (status) {
        case 'PickedUp':
          return Colors.blue;
        case 'In Transit':
          return Colors.orange;
        case 'Delivered':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

  }

