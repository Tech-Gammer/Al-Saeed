import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/homepage.dart';
import 'package:myfirstmainproject/userprofile.dart';
import 'checkoutpage.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  final DatabaseReference _riderRef = FirebaseDatabase.instance.ref("riders");
  late User currentUser;
  Map<String, dynamic>? cartItems;


  String userRole = '';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    checkUserRoleAndFetchCartItems();
  }

  Future<void> checkUserRoleAndFetchCartItems() async {
    try {
      final adminSnapshot = await _adminRef.child(currentUser.uid).once();
      final userSnapshot = await _userRef.child(currentUser.uid).once();
      final riderSnapshot = await _riderRef.child(currentUser.uid).once();

      if (adminSnapshot.snapshot.value != null) {
        setState(() {
          userRole = 'admin';
        });
      } else if (riderSnapshot.snapshot.value != null) {
        setState(() {
          userRole = 'riders';
        });
      } else {
        setState(() {
          userRole = 'users';
        });
      }

      // Fetch cart items after determining user role
      fetchCartItems();
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  Future<void> fetchCartItems() async {
    try {
      // final userCartRef = _cartRef; // Fetch cart for the current user
      // final snapshot = await userCartRef.orderByChild('uid').equalTo(currentUser.uid).once();
      String userId = currentUser!.uid;
      final userCartRef = _cartRef.child(userId); // Reference to the current user's cart
      final snapshot = await userCartRef.once(); // Get all cart items for the user

      if (snapshot.snapshot.exists) {
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
      Query cartQuery = _cartRef.orderByChild('itemId').equalTo(itemId);

      try {
        DatabaseEvent event = await cartQuery.once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists) {
          Map<dynamic, dynamic> items = snapshot.value as Map<dynamic, dynamic>;
          for (var key in items.keys) {
            await _cartRef.child(key).remove();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item removed from cart!")),
          );

          // Refresh cart items
          await fetchCartItems();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item not found in cart.")),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
        print(error);
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
    DatabaseReference profileRef;
    if (userRole == 'admin') {
      profileRef = _adminRef.child(currentUser.uid);
    } else if (userRole == 'riders') {
      profileRef = _riderRef.child(currentUser.uid);
    } else {
      profileRef = _userRef.child(currentUser.uid);
    }

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
        const SnackBar(
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
      appBar: AppBar(
        title: Text("Cart Items",style: GoogleFonts.lora(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold,),),
        centerTitle: true,
        backgroundColor:const Color(0xFFe6b67e),
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const FrontPage()),
                (Route<dynamic> route) => false,
          );  }, icon: const Icon(Icons.arrow_back),),
      ),
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
                final cartId = cartItems!.keys.elementAt(index);
                final itemId = item['itemId'];
                final quantity = item['quantity'];
                final name = item['name'] as String? ?? 'No Name';
                final imageUrl = item['imageUrl'] as String? ?? '';
                final category = item['category'] as String? ?? 'No Category';
                final rate = item['rate'] as String? ?? 'No Rate';
                final description = item['description'] as String? ?? 'No description';



                return ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  title: Text("Name: $name", style: GoogleFonts.lora(fontSize: 18,fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Category: $category", style: GoogleFonts.lora(fontSize: 14)),
                      Text("Rate: $rate", style: GoogleFonts.lora(fontSize: 14)),
                      Text("Quantity: $quantity", style: GoogleFonts.lora(fontSize: 14)),
                      // Text("Description: $description", style: GoogleFonts.lora(fontSize: 14)),
                      // Text("itemId: $itemId", style: GoogleFonts.lora(fontSize: 14)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
                  color: const Color(0xFFe6b67e),
                  child: InkWell(
                    child: Container(
                      width: 150.0,
                      height: 40.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFe6b67e),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "TOTAL BALANCE",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Without Delivery Charges",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                          ],
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
              color: const Color(0xFFe6b67e),
              child: InkWell(
                onTap: checkAndProceedToCheckout,
                child: Container(
                  width: double.infinity,
                  height: 50.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFe6b67e),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Center(
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
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
