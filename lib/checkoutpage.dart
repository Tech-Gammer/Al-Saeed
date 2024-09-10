import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:myfirstmainproject/orderslist.dart';
import 'package:myfirstmainproject/paymentfiles/firstpage.dart';
import 'package:myfirstmainproject/userprofile.dart';
import 'components.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with SingleTickerProviderStateMixin {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  final DatabaseReference _riderRef = FirebaseDatabase.instance.ref("riders");
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  final DatabaseReference _feedbackRef = FirebaseDatabase.instance.ref("Feedback");
  late User currentUser;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? cartItems;
  bool isAdmin = false;
  bool isRider = false;
  double? distanceToShop;
  double? deliveryCharges;
  late AnimationController _controller;
  late ScrollController _scrollController;
  late double _scrollPosition;
  final String _newsText = "Per Km delivery charges cost 50rs above a radius of 1km from the shop.";
  String selectedPaymentMethod = 'Cash on Delivery'; // Default selected method
  bool _isButtonDisabled = false; // Flag to disable the button after it's pressed
  bool  comingfromResponsePage = false;


  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    determineUserRole();
    _scrollController = ScrollController();
    _scrollPosition = 0.0;

    _controller = AnimationController(
      duration: const Duration(seconds: 10), // Duration for one full scroll
      vsync: this,
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _scrollPosition = _scrollController.offset + 1;
        if (_scrollPosition >= _scrollController.position.maxScrollExtent) {
          _scrollPosition = 0.0;
          _scrollController.jumpTo(_scrollPosition);
        } else {
          _scrollController.jumpTo(_scrollPosition);
        }
      });
    });

  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  Future<void> calculateDistanceToShop() async {
    const shopLatitude = 32.167226847995174;
    const shopLongitude = 74.2041711211677;
    // 32.15060904524294, 74.1875628697421
    // 32.167226847995174, 74.2041711211677
    double userLatitude = 0.0;
    double userLongitude = 0.0;

    try {
      final userRef = isAdmin ? _adminRef : isRider ? _riderRef : _userRef;
      final snapshot = await userRef.child(currentUser.uid).once();

      if (snapshot.snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        userLatitude = double.parse(userData['latitude'].toString());
        userLongitude = double.parse(userData['longitude'].toString());
      }

      double distanceInMeters = calculateDistance(userLatitude, userLongitude, shopLatitude, shopLongitude);

      setState(() {
        distanceToShop = distanceInMeters / 1000; // Convert meters to kilometers
      });

      print('Distance from shop: ${distanceToShop} km');
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  double calculateDeliveryCharges(){
    double subdistance = distanceToShop! - 1;
    return (subdistance * 50);
  }

  Future<void> determineUserRole() async {
    try {
      final adminSnapshot = await _adminRef.child(currentUser.uid).once();
      final riderSnapshot = await _riderRef.child(currentUser.uid).once();

      if (adminSnapshot.snapshot.value != null) {
        setState(() {
          isAdmin = true;
          isRider = false;
        });
      } else if (riderSnapshot.snapshot.value != null) {
        setState(() {
          isAdmin = false;
          isRider = true;
        });
      } else {
        setState(() {
          isAdmin = false;
          isRider = false;
        });
      }

      fetchUserData();
      fetchCartItems();
      await calculateDistanceToShop(); // Calculate the distance after fetching user data

    } catch (e) {
      print('Error determining user role: $e');
    }
  }

  Future<void> fetchUserData() async {
    final userRef = isAdmin
        ? _adminRef
        : isRider
        ? _riderRef
        : _userRef;

    try {
      final snapshot = await userRef.child(currentUser.uid).once();
      if (snapshot.snapshot.value != null) {
        setState(() {
          userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> fetchCartItems() async {
    String userId = currentUser.uid;
    final userCartRef = _cartRef.child(userId); // Reference to the current user's cart
    final snapshot = await userCartRef.once(); // Get all cart items for the user
    // final userCartRef = _cartRef;
    // final snapshot = await userCartRef.orderByChild('uid').equalTo(currentUser.uid).once();
    if (snapshot.snapshot.value != null) {
      setState(() {
        cartItems = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      });
    } else {
      setState(() {
        cartItems = {};
      });
    }
  }

  double calculateTotalBalance() {
    double total = 0.0;
    if (cartItems != null) {
      cartItems!.forEach((key, item) {
        final rate = double.tryParse(item['rate'] as String? ?? '0') ?? 0;
        final quantity = item['quantity'] as int? ?? 0;
        total += rate * quantity;
      });
    }
    return total;
  }

  Future<String> placeOrder() async {
    String newOrderId = _ordersRef.push().key.toString();
    try {
      // Calculate the total balance (subtotal) and delivery charges
      double subtotal = calculateTotalBalance();
      double charges = deliveryCharges ?? 0.0;
      double total = subtotal + charges;

      // Create a new order
      final newOrder = {
        'orderId': newOrderId,
        'items': cartItems,
        'userId': currentUser.uid,
        'subtotal': subtotal,
        'deliveryCharges': charges,
        'total': total,
        'status': 'Pending',
        'payment_status': selectedPaymentMethod == 'Cash on Delivery' ? 'Pending' : 'Paid', // Set payment status
        'timestamp': DateTime.now().toIso8601String(),
        'distance_from_shop': distanceToShop ?? 0.0, // Add distance information
      };

      // Add the new order to the list
      List<Map<String, dynamic>> existingOrders = await fetchExistingOrders();
      existingOrders.add(newOrder);
      List<Map<String, dynamic>> mergedOrders = mergeOrders(existingOrders);

      // Update Firebase with merged orders
      await updateMergedOrders(mergedOrders);

      // Optionally, clear the cart after placing the order
      await _cartRef.remove();

      if(selectedPaymentMethod == 'Cash on Delivery'){
        // Show feedback dialog only after placing the order
        await showFeedbackDialog(newOrderId);
      }
      // Return the newOrderId
      return newOrderId;
    } catch (error) {
      throw Exception("Error placing order: $error");
    }
  }

  Future<void> showFeedbackDialog(String orderId) async {
    showDialog(
      context: context,
      builder: (context) {
        double rating = 0.0;
        TextEditingController feedbackController = TextEditingController();

        return AlertDialog(
          title: const Text('Rate your items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(hintText: 'Leave your feedback'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: true)),
                      (route) => false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text;
                await saveFeedback(orderId, rating, feedback,currentUser.uid);
                Navigator.of(context).pop();

                // Navigate to CustomerOrdersPage after feedback
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: true)),
                      (route) => false,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveFeedback(String orderId, double rating, String feedback,String userId) async {
    if (cartItems != null) {
      cartItems!.forEach((key, item) async {
        final itemId = item['itemId'];
        final adminId = item['adminId'] as String? ?? 'unknownAdminId';
        final feedbackData = {
          'orderId': orderId,
          'itemId': itemId,
          'adminId': adminId,
          'rating': rating,
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': userId
        };

        await _feedbackRef.push().set(feedbackData);
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchExistingOrders() async {
    final snapshot = await _ordersRef.orderByChild('userId').equalTo(currentUser.uid).once();
    if (snapshot.snapshot.value != null) {
      List<Map<String, dynamic>> orders = [];
      snapshot.snapshot.children.forEach((doc) {
        orders.add(Map<String, dynamic>.from(doc.value as Map));
      });
      return orders;
    }
    return [];
  }

  Future<void> updateMergedOrders(List<Map<String, dynamic>> mergedOrders) async {
    try {
      // Clear existing orders for the user
      final existingOrders = await fetchExistingOrders();
      for (var order in existingOrders) {
        await _ordersRef.child(order['orderId']).remove();
      }

      // Add merged orders to Firebase
      for (var order in mergedOrders) {
        await _ordersRef.child(order['orderId']).set(order);
      }
    } catch (error) {
      print('Error updating merged orders: $error');
    }
  }


  List<Map<String, dynamic>> mergeOrders(List<Map<String, dynamic>> orders) {
    List<Map<String, dynamic>> mergedOrders = [];

    for (var order in orders) {
      if (mergedOrders.isEmpty) {
        mergedOrders.add(order);
      } else {
        DateTime currentOrderTime = DateTime.parse(order['timestamp']);
        double currentDistance = order['distance_from_shop'] as double; // Assuming you have this field

        bool merged = false;

        for (var mergedOrder in mergedOrders) {
          DateTime lastOrderTime = DateTime.parse(mergedOrder['timestamp']);
          double lastDistance = mergedOrder['distance_from_shop'] as double; // Assuming you have this field

          // Check if orders have the same payment status, are within the time window, and have the same distance
          if (currentOrderTime.difference(lastOrderTime).inMinutes < 5 &&
              order['payment_status'] == mergedOrder['payment_status'] &&
              currentDistance == lastDistance) {

            // Merge logic: Combine items and quantities
            mergedOrder['items'].addAll(order['items']);

            // Update totals
            double existingTotal = mergedOrder['total'] as double;
            double currentSubtotal = order['subtotal'] as double;

            mergedOrder['total'] = existingTotal + currentSubtotal; // Add subtotal to existing total
            mergedOrder['timestamp'] = DateTime.now().toIso8601String(); // Update timestamp

            merged = true;
            break;
          }
        }

        if (!merged) {
          mergedOrders.add(order);
        }
      }
    }

    return mergedOrders;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Checkout"),
      body: userData != null && cartItems != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 30.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Text(
                            _newsText,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20), // Space between repeats
                        ],
                      );
                    },
                  ),
                ),
              ),
              Text(
                'Profile Information:',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Role: ${isAdmin ? 'Admin' : isRider ? 'Rider' : 'Buyer'}'), // Display Role
              Text('Name: ${userData!['name']}'),
              Text('Email: ${userData!['email']}'),
              Text('Phone: ${userData!['phone']}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text('Address: ${userData!['address']}'),
                  IconButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>UserProfile()));
                  }, icon: const Icon(Icons.location_history))
                ],
              ),
              Text('Zip Code: ${userData!['zip_code']}'),
              if (distanceToShop != null)
                Text('Distance to Shop: ${distanceToShop!.toStringAsFixed(2)} km'), // Display distance
              const SizedBox(height: 20),
              Text(
                'Cart Items:',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...cartItems!.entries.map((entry) {
                final item = entry.value;
                final name = item['name'] as String? ?? 'No Name';
                final imageUrl = item['imageUrl'] as String? ?? '';
                final category = item['category'] as String? ?? 'No Category';
                final rate = item['rate'] as String? ?? 'No Rate';
                final quantity = item['quantity'] as int? ?? 0;
                final description = item['description'] as String? ?? 'No description';
                deliveryCharges = calculateDeliveryCharges();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    title: Text("Name: $name", style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Category: $category", style: GoogleFonts.lora(fontSize: 14)),
                        Text("Rate: $rate", style: GoogleFonts.lora(fontSize: 14)),
                        Text("Quantity: $quantity", style: GoogleFonts.lora(fontSize: 14)),
                        Text("Description: $description", style: GoogleFonts.lora(fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // Add radio buttons for payment options
              const SizedBox(height: 20),
              Text(
                'Payment Method:',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Cash on Delivery'),
                value: 'Cash on Delivery',
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Online Payment'),
                value: 'Online Payment',
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUB TOTAL',
                    style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs. ${calculateTotalBalance().toStringAsFixed(2)}',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DELIVERY CHARGES ',
                    style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs.${deliveryCharges?.toStringAsFixed(2)} ',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Existing Total Balance and Checkout Button
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs. ${(deliveryCharges! + calculateTotalBalance()).toStringAsFixed(2)}',
                    style: GoogleFonts.lora(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Center(
                child: ElevatedButton(
                  onPressed: _isButtonDisabled
                      ? null // Disable the button if `_isButtonDisabled` is true
                      : () async {
                    setState(() {
                      _isButtonDisabled = true; // Disable the button to prevent multiple presses
                    });

                    try {
                      double totalBalance = deliveryCharges! + calculateTotalBalance();
                      if (selectedPaymentMethod == 'Online Payment') {
                        // Generate the order and pass `newOrderId` to `firstpage`
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => firstpage(
                              totalBalance, // Pass newOrderId here
                              placeOrder: () async {
                                await placeOrder(); // Ensure `placeOrder` is awaited
                                  },
                            ),
                          ),
                        );
                      } else {
                        await placeOrder(); // Ensure `placeOrder` is awaited
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error processing order: $e")));
                    } finally {
                      setState(() {
                        _isButtonDisabled = false; // Re-enable the button if an error occurs or action completes
                      });
                    }
                  },
                  child: const Text("Complete Checkout", style: NewCustomTextStyles.newcustomTextStyle),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFe6b67e),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),



            ],
          ),
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

