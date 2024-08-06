import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/orderslist.dart';

import 'components.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  late User currentUser;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? cartItems;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    determineUserRole();
  }

  Future<void> determineUserRole() async {
    try {
      final adminSnapshot = await _adminRef.child(currentUser.uid).once();
      if (adminSnapshot.snapshot.value != null) {
        setState(() {
          isAdmin = true;
        });
      } else {
        setState(() {
          isAdmin = false;
        });
      }
      fetchUserData();
      fetchCartItems();
    } catch (e) {
      print('Error determining user role: $e');
    }
  }

  Future<void> fetchUserData() async {
    final userRef = isAdmin ? _adminRef : _userRef;
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
    final userCartRef = FirebaseDatabase.instance.ref("cart").child(currentUser.uid);
    final snapshot = await userCartRef.once();
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

  Future<void> placeOrder() async {
    if (cartItems != null) {
      try {
        String orderId = _ordersRef.push().key.toString(); // Generate a new orderId
        final orderRef = _ordersRef.child(orderId);

        final orderData = {
          'orderId': orderId,
          'items': cartItems,
          'userId': currentUser.uid,
          'total': calculateTotalBalance(),
          'status': 'Pending',
          'timestamp': DateTime.now().toIso8601String(),
        };

        await orderRef.set(orderData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order placed successfully!")));

        // Optionally, clear the cart after placing the order
        await FirebaseDatabase.instance.ref("cart").child(currentUser.uid).remove();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: true)),
              (route) => false, // This will remove all previous routes
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error placing order: $error")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Checkout"),
      body: userData != null && cartItems != null
          ? Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Information',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Role: ${isAdmin ? 'Admin' : 'Buyer'}'), // Display Role
              Text('Name: ${userData!['name']}'),
              Text('Email: ${userData!['email']}'),
              Text('Phone: ${userData!['phone']}'),
              Text('Address: ${userData!['address']}'),
              Text('Zip Code: ${userData!['zip_code']}'),
              SizedBox(height: 20),
              Text(
                'Cart Items',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...cartItems!.entries.map((entry) {
                final item = entry.value;
                final name = item['name'] as String? ?? 'No Name';
                final imageUrl = item['imageUrl'] as String? ?? '';
                final category = item['category'] as String? ?? 'No Category';
                final rate = item['rate'] as String? ?? 'No Rate';
                final quantity = item['quantity'] as int? ?? 0;
                final description = item['description'] as String? ?? 'No description';

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    title: Text("Name: $name", style: GoogleFonts.lora(fontSize: 18,fontWeight: FontWeight.bold)),
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs. ${calculateTotalBalance().toStringAsFixed(2)}',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    placeOrder(); // Trigger order placement
                  },
                  child: Text("Complete Checkout",style: NewCustomTextStyles.newcustomTextStyle),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color(0xFFe6b67e),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
