  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_database/firebase_database.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_rating_bar/flutter_rating_bar.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'Model/cartmodel.dart';
  import 'admin/loginpage.dart';
  import 'cartitems.dart';
  import 'components.dart';
  import 'homepage.dart';

  class ItemSelectPage extends StatefulWidget {
    final String itemId;
    final String adminId;
    final String item_name;
    final String imageUrl;
    final String category;
    final String rate;
    final String description;

    const ItemSelectPage({
      Key? key,
      required this.imageUrl,
      required this.category,
      required this.rate,
      required this.description,
      required this.itemId,
      required this.adminId,
      required this.item_name,
    }) : super(key: key);

    @override
    _ItemSelectPageState createState() => _ItemSelectPageState();
  }

  class _ItemSelectPageState extends State<ItemSelectPage> {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DatabaseReference cartRef = FirebaseDatabase.instance.ref("cart");
    final DatabaseReference _ratingRef = FirebaseDatabase.instance.ref("Feedback");
    final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
    final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
    final DatabaseReference _ridersRef = FirebaseDatabase.instance.ref("riders");
    bool _isAddingToCart = false;
    List<dynamic> feedback = [];
    Map<String, dynamic> userData = {};
    int quantity = 1;
    int _cartItemCount = 0;



    @override
    void initState() {
      super.initState();
      fetchCartItemCount();
    }


    Future<double> fetchRating(String itemId) async {
      try {
        double addrating = 0;
        final snapshot = await _ratingRef.orderByChild('itemId').equalTo(itemId).get();
        if (snapshot.exists) {
          final dataSnapshot = snapshot.value as Map;
          List<dynamic> itemList = dataSnapshot.values.toList();

          feedback.clear();
          for (int i = 0; i < itemList.length; i++) {
            addrating += double.parse(itemList[i]['rating'].toString());
            feedback.add({
              'userId': itemList[i]['userId'],
              'feedback': itemList[i]['feedback'],
              'timestamp': itemList[i]['timestamp']
            });
          }

          return addrating / itemList.length;
        } else {
          return 0;
        }
      } catch (e) {
        // print('Error fetching data: $e');
        return 0;
      }
    }

    Future<void> loadUserDetails() async {
      Map<String, dynamic> fetchedUserData = {};
      if (feedback.isNotEmpty) {
        for (var node in feedback) {
          final userId = node['userId'];

          // Fetch from 'admin' node
          final adminSnapshot = await _adminRef.child(userId).get();
          if (adminSnapshot.exists) {
            final adminData = adminSnapshot.value;
            if (adminData is Map<Object?, Object?>) {
              fetchedUserData[userId] = Map<String, dynamic>.from(adminData);
              continue;
            }
          }

          // Fetch from 'users' node
          final userSnapshot = await _usersRef.child(userId).get();
          if (userSnapshot.exists) {
            final userDataMap = userSnapshot.value;
            if (userDataMap is Map<Object?, Object?>) {
              fetchedUserData[userId] = Map<String, dynamic>.from(userDataMap);
              continue;
            }
          }

          // Fetch from 'riders' node
          final riderSnapshot = await _ridersRef.child(userId).get();
          if (riderSnapshot.exists) {
            final riderData = riderSnapshot.value;
            if (riderData is Map<Object?, Object?>) {
              fetchedUserData[userId] = Map<String, dynamic>.from(riderData);
              continue;
            }
          }
        }

        setState(() {
          userData = fetchedUserData;
        });
      }
    }


    // void addToCart() async {
    //   if (_isAddingToCart) return; // Prevent multiple presses
    //   _isAddingToCart = true;
    //
    //   try {
    //     if (currentUser == null) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text("Please login to add items to the cart.")),
    //       );
    //       _isAddingToCart = false;
    //       return;
    //     }
    //
    //     String userId = currentUser!.uid;
    //     DatabaseReference userCartRef = cartRef;
    //
    //     final snapshot = await userCartRef.get();
    //     Map<String, dynamic> existingItems = snapshot.value != null
    //         ? Map<String, dynamic>.from(snapshot.value as Map)
    //         : {};
    //
    //     bool itemExists = false;
    //     String cartItemId = '';
    //
    //     for (var entry in existingItems.entries) {
    //       if (entry.value['itemId'] == widget.itemId) {
    //         itemExists = true;
    //         cartItemId = entry.key;
    //         int existingQuantity = entry.value['quantity'];
    //         int newQuantity = existingQuantity + quantity;
    //
    //         await userCartRef.child(cartItemId).update({'quantity': newQuantity});
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           SnackBar(content: Text("Item quantity updated in cart!")),
    //         );
    //         break;
    //       }
    //     }
    //
    //     if (!itemExists) {
    //       cartItemId = userCartRef.push().key.toString();
    //       CartItem cartItem = CartItem(
    //         adminId: widget.adminId,
    //         itemId: widget.itemId,
    //         name: widget.item_name,
    //         imageUrl: widget.imageUrl,
    //         category: widget.category,
    //         rate: widget.rate,
    //         description: widget.description,
    //         quantity: quantity,
    //         uid: userId,
    //       );
    //
    //       await userCartRef.child(cartItemId).set(cartItem.toMap());
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text("Item added to cart!")),
    //       );
    //     }
    //
    //     fetchCartItemCount(); // Update cart item count
    //   } catch (error) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text("Failed to add/update item in cart: $error")),
    //     );
    //   } finally {
    //     _isAddingToCart = false; // Re-enable button
    //   }
    // }


    void addToCart() async {
      if (_isAddingToCart) return; // Prevent multiple presses
      _isAddingToCart = true;

      try {
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to add items to the cart.")),
          );
          _isAddingToCart = false;
          return;
        }

        String userId = currentUser!.uid;
        DatabaseReference userCartRef = cartRef.child(userId); // Reference to user's cart

        final snapshot = await userCartRef.get();
        Map<String, dynamic> existingItems = snapshot.exists
            ? Map<String, dynamic>.from(snapshot.value as Map)
            : {};

        bool itemExists = false;
        String cartItemId = '';

        for (var entry in existingItems.entries) {
          if (entry.value['itemId'] == widget.itemId) {
            itemExists = true;
            cartItemId = entry.key;
            int existingQuantity = entry.value['quantity'];
            int newQuantity = existingQuantity + quantity;

            await userCartRef.child(cartItemId).update({'quantity': newQuantity});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item quantity updated in cart!")),
            );
            break;
          }
        }

        if (!itemExists) {
          cartItemId = userCartRef.push().key ?? '';
          CartItem cartItem = CartItem(
            adminId: widget.adminId,
            itemId: widget.itemId,
            name: widget.item_name,
            imageUrl: widget.imageUrl,
            category: widget.category,
            rate: widget.rate,
            description: widget.description,
            quantity: quantity,
            uid: userId,
          );

          await userCartRef.child(cartItemId).set(cartItem.toMap());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item added to cart!")),
          );
        }

        fetchCartItemCount(); // Update cart item count
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add/update item in cart: $error")),
        );
      } finally {
        _isAddingToCart = false; // Re-enable button
      }
    }



    // Future<void> fetchCartItemCount() async {
    //   if (currentUser != null) {
    //     try {
    //       String userId = currentUser!.uid;
    //       final userCartRef = cartRef;
    //       final snapshot = await userCartRef.child(userId).orderByChild('uid').equalTo(currentUser!.uid).once();
    //       if (snapshot.snapshot.exists) {
    //         final cartItems = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
    //         setState(() {
    //           _cartItemCount = cartItems.length;
    //         });
    //       } else {
    //         setState(() {
    //           _cartItemCount = 0;
    //         });
    //       }
    //     } catch (e) {
    //       print('Error fetching cart item count: $e');
    //     }
    //   }
    // }

    Future<void> fetchCartItemCount() async {
      if (currentUser != null) {
        try {
          String userId = currentUser!.uid;
          final userCartRef = cartRef.child(userId); // Reference to the current user's cart
          final snapshot = await userCartRef.once(); // Get all cart items for the user

          if (snapshot.snapshot.exists) {
            final cartItems = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
            setState(() {
              _cartItemCount = cartItems.length; // Number of items in the cart
            });
          } else {
            setState(() {
              _cartItemCount = 0; // No items in the cart
            });
          }
        } catch (e) {
          // print('Error fetching cart item count: $e');
        }
      }
    }


    void incrementQuantity() {
      setState(() {
        quantity++;
      });
    }

    void decrementQuantity() {
      setState(() {
        if (quantity > 1) {
          quantity--;
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      double rating = 3.0; // Default rating

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.item_name, style: GoogleFonts.lora(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,)),
          backgroundColor:const Color(0xFFe6b67e),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FrontPage()));
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_basket),
                    onPressed: () {
                      if (currentUser == null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
                      }
                    },
                  ),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: 5,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8.0,
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        child: Text(
                          _cartItemCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      image: DecorationImage(image: NetworkImage(widget.imageUrl),
                      fit: BoxFit.fitHeight,
                      ),

                    ),
                  ),
                  Text(widget.item_name,style: GoogleFonts.lora(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    ),
                  ),const SizedBox(height: 10),
                  Text("Rs: ${widget.rate}",style: GoogleFonts.lora(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                  ),const SizedBox(height: 10),
                  Text("${widget.category} Item",style: GoogleFonts.lora(
                    fontSize: 25,
                  ),
                  ),const SizedBox(height: 10),
                  Text(widget.description,style: GoogleFonts.lora(
                    fontSize: 20,
                  ),
                  ),const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: decrementQuantity,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        "$quantity",
                        style: GoogleFonts.lora(fontSize: 22),
                      ),
                      IconButton(
                        onPressed: incrementQuantity,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe6b67e),
                        padding: const EdgeInsets.all(10),
                      ),
                      child: const Text('Add to Cart', style: NewCustomTextStyles.newcustomTextStyle),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<double>(
                    future: fetchRating(widget.itemId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        rating = snapshot.data ?? 0.0;
                        if(feedback.isNotEmpty){
                          loadUserDetails();
                        }
                        return Column(
                          children: [
                            Text("Rating Stars",style: GoogleFonts.lora(fontSize: 30,fontWeight: FontWeight.bold,color:const Color(0xFFE0A45E) )),
                            Card(
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: const BorderSide(
                                  color: Color(0xFFE0A45E),
                                  width: 1.0,
                                ),
                              ),
                              elevation: 10,
                              child: ListTile(

                                title: Center(
                                  child: RatingBar.builder(
                                    ignoreGestures: true,
                                    initialRating: rating,
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                    onRatingUpdate: (rating) {},
                                  ),
                                ),
                              ),
                            ),
                            Text("Feed Back",style: GoogleFonts.lora(fontSize: 30,fontWeight: FontWeight.bold,color:const Color(0xFFE0A45E) )),
                            if (feedback.isNotEmpty)
                              Column(
                                children: feedback.map((feedbackItem) {
                                  final userId = feedbackItem['userId'];
                                  final user = userData[userId];
                                  return Card(
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      side: const BorderSide(
                                        color: Color(0xFFE0A45E),
                                        width: 2.0,
                                      ),
                                    ),
                                    elevation: 10,
                                    child: ListTile(
                                      title: Text("Feedback: ${feedbackItem['feedback'] ?? 'No feedback'}",style: const TextStyle(fontSize: 20),),
                                      subtitle: user != null
                                          ? Text("User: ${user['name'] ?? 'Unknown User'}\nDate & Time: ${feedbackItem['timestamp']}", style: const TextStyle(fontSize: 15))
                                          : Text("Date & Time: ${feedbackItem['timestamp']}"),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
