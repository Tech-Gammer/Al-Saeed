import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myfirstmainproject/rider/riderdrawer.dart';
import 'package:myfirstmainproject/rider/riderpickeduppage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Model/ridermodel.dart';

class OrdersForRiders extends StatefulWidget {
  const OrdersForRiders({super.key});

  @override
  State<OrdersForRiders> createState() => _OrdersForRidersState();
}

class _OrdersForRidersState extends State<OrdersForRiders> {
  late String riderId;
  late String riderNumber;


  @override
  void initState() {
    super.initState();
    _initializeRiderData();
  }

  Future<void> _initializeRiderData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        riderId = user.uid; // Get the rider ID from Firebase Authentication
        riderNumber = await getRiderNumber(riderId);
        // print(riderId);
        // print(riderNumber);
        setState(() {}); // Refresh state once data is loaded
      }
    } catch (e) {
      // Handle errors
      // print('Error initializing rider data: $e');
    }
  }

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

  Future<List<Map<Order, User>>> fetchOrders() async {
    final databaseReference = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await databaseReference.child('orders')
        .orderByChild('status')
        .equalTo('Processing')
        .once();
    final ordersMap = event.snapshot.value as Map<dynamic, dynamic>?;

    List<Map<Order, User>> ordersWithUserData = [];

    if (ordersMap != null) {
      for (var orderId in ordersMap.keys) {
        final orderDataMap = Map<String, dynamic>.from(ordersMap[orderId] as Map);
        final userId = orderDataMap['userId'] as String?;

        if (userId != null) {
          Order order = Order.fromMap(orderDataMap, orderId as String);
          User user = User.fromMap(await fetchUserData(userId));
          ordersWithUserData.add({order: user});
        }
      }
    }

    return ordersWithUserData;
  }

  Future<void> pickupOrder(String orderId, String riderId, String riderNumber) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child('orders/$orderId').update({
      'status': 'PickedUp',
      'riderId': riderId,
      'riderNumber': riderNumber,
    });
  }

  Future<String> getRiderNumber(String riderId) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await databaseReference.child('riders/$riderId').once();
    if (event.snapshot.exists) {
      final riderData = Map<String, dynamic>.from(event.snapshot.value as Map);
      return riderData['riderNumber'] ?? ''; // Fetch rider number from the database
    }
    throw Exception('Rider not found');
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


  @override
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: const riderdrawerpage(),
      appBar: AppBar(
        title: SizedBox(
            width: 100,
            height: 70,
            child: Image.asset("images/logomain.png")),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecificRiderPage(riderNumber: riderNumber),
                ),
              );
            },
            icon: const Icon(Icons.directions_bike),
          )
        ],
      ),
      body: FutureBuilder<List<Map<Order, User>>>(
        future: fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders available'));
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
                        const SizedBox(height: 10),
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
                              )
                            ],
                          ),
                        )),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            Text('Total: ${order.total.toStringAsFixed(2)}',style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                            ElevatedButton(
                              onPressed: () => _showLocation(user),
                              child: const Text('Show Location'),
                            ),
                          ],
                        ), // Display total here
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await pickupOrder(order.orderId, riderId, riderNumber);
                        setState(() {}); // Refresh the list
                      },
                      child: const Text('Pickup'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class User {
  String name;
  String phone;
  String address;
  String zipCode;
  String email;
  double latitude; // Add latitude field
  double longitude; // Add longitude field

  User({
    required this.name,
    required this.phone,
    required this.address,
    required this.zipCode,
    required this.email,
    required this.latitude,
    required this.longitude,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      zipCode: map['zip_code'] ?? '',
      email: map['email'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(), // Ensure latitude is double
      longitude: (map['longitude'] ?? 0.0).toDouble(), // Ensure longitude is double
    );
  }
}
