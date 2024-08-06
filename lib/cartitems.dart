import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/userprofile.dart';
import 'checkoutpage.dart';
import 'components.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  late User currentUser;
  Map<String, dynamic>? cartItems;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    checkIfAdminAndFetchCartItems();
  }

  Future<void> checkIfAdminAndFetchCartItems() async {
    try {
      final adminSnapshot = await _adminRef.child(currentUser.uid).once();
      final userSnapshot = await _userRef.child(currentUser.uid).once();

      if (adminSnapshot.snapshot.value != null) {
        setState(() {
          isAdmin = true;
        });
      }

      // Fetch cart items after determining if user is an admin
      fetchCartItems();
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> fetchCartItems() async {
    try {
      final userCartRef = _cartRef.child(currentUser.uid);
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
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  Future<void> deleteCartItem(String itemId) async {
    if (currentUser != null) {
      String adminId = currentUser.uid;
      DatabaseReference userCartRef = _cartRef.child(adminId).child(itemId);

      try {
        await userCartRef.remove();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item removed from cart!")));

        setState(() {
          cartItems!.remove(itemId); // Refresh UI
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
      }
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

  Future<bool> isProfileComplete() async {
    DatabaseReference profileRef = isAdmin ? _adminRef.child(currentUser.uid) : _userRef.child(currentUser.uid);
    final snapshot = await profileRef.once();
    if (snapshot.snapshot.value != null) {
      final profileData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

      // Check if all required fields are filled
      return profileData['name'] != null &&
          profileData['email'] != null &&
          profileData['address'] != null &&
          profileData['zip_code'] != null &&
          profileData['phone'] != null &&
          profileData['name'].toString().isNotEmpty &&
          profileData['email'].toString().isNotEmpty &&
          profileData['address'].toString().isNotEmpty &&
          profileData['zip_code'].toString().isNotEmpty &&
          profileData['phone'].toString().isNotEmpty;
    }
    return false;
  }

  void checkAndProceedToCheckout() async {
    bool isComplete = await isProfileComplete();
    if (isComplete) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(), // Pass uid to CheckoutPage
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please complete your profile before proceeding to checkout."),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfile(), // Navigate to profile page to complete details
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Cart Items"),
      body: cartItems != null
          ? cartItems!.isEmpty
          ? Center(
        child: Text(
          'No items found in cart',
          style: GoogleFonts.lora(fontSize: 18, color: Colors.black54),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems!.length,
              itemBuilder: (context, index) {
                final item = cartItems!.values.elementAt(index);
                final itemId = cartItems!.keys.elementAt(index);
                final quantity = item['quantity'];
                final name = item['name'] as String? ?? 'No Name';
                final imageUrl = item['imageUrl'] as String? ?? '';
                final category = item['category'] as String? ?? 'No Category';
                final rate = item['rate'] as String? ?? 'No Rate';
                final description = item['description'] as String? ?? 'No description';

                return ListTile(
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
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteCartItem(itemId),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  color: Color(0xFFe6b67e),
                  child: InkWell(
                    child: Container(
                      width: 150.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFe6b67e),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Center(
                        child: Text(
                          "TOTAL BALANCE",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  'Rs. ${calculateTotalBalance().toStringAsFixed(2)}',
                  style: GoogleFonts.lora(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Color(0xFFe6b67e),
              child: InkWell(
                onTap: checkAndProceedToCheckout,
                child: Container(
                  width: double.infinity,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Color(0xFFe6b67e),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                      "Proceed to Checkout",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
