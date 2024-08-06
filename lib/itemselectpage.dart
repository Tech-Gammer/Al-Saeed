import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/components.dart';

import 'Model/cartmodel.dart';
import 'cartitems.dart';
import 'homepage.dart';



class ItemSelectPage extends StatefulWidget {
  final String itemId;
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
    required this.item_name,

  }) : super(key: key);

  @override
  _ItemSelectPageState createState() => _ItemSelectPageState();
}

class _ItemSelectPageState extends State<ItemSelectPage> {

  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference cartRef = FirebaseDatabase.instance.ref("cart");
  int quantity = 1;

  void addToCart() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login to add items to the cart.")),
      );
    } else {
      String adminId = currentUser!.uid;
      DatabaseReference userCartRef = cartRef.child(adminId);

      userCartRef.once().then((snapshot) {
        Map<String, dynamic> existingItems = snapshot.snapshot.value != null
            ? Map<String, dynamic>.from(snapshot.snapshot.value as Map)
            : {};

        bool itemExists = false;
        String itemId = widget.itemId.toString();

        existingItems.forEach((key, value) {
          if (value['itemId'] == itemId) {
            itemExists = true;
            int existingQuantity = value['quantity'];
            int newQuantity = existingQuantity + quantity;

            userCartRef.child(key).update({'quantity': newQuantity}).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Item quantity updated in cart!")),
              );
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to update item quantity: $error")),
              );
            });
          }
        });

        if (!itemExists) {
          String cartItemId = userCartRef.push().key.toString();
          CartItem cartItem = CartItem(
            itemId: itemId,
            name: widget.item_name,
            imageUrl: widget.imageUrl,
            category: widget.category,
            rate: widget.rate,
            description: widget.description,
            quantity: quantity,
            uid: adminId,
          );

          userCartRef.child(cartItemId).set(cartItem.toMap()).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Item added to cart!")),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to add item to cart: $error")),
            );
          });
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching cart data: $error")),
        );
      });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item_name,style: GoogleFonts.lora(),),
        titleTextStyle: TextStyle(
          fontSize: 25,
          color: Colors.white,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context)=>FrontPage())); }, icon: Icon(Icons.arrow_back),
        ),
        actions: <Widget>[
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>CartPage()));
          }, icon: Icon(Icons.shopping_basket))
        ],
        backgroundColor:  Color(0xFFE0A45E),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 150,
                  backgroundImage: NetworkImage(widget.imageUrl),
                ),
                SizedBox(height: 20),
                Text(widget.item_name, style: GoogleFonts.lora(fontSize: 24)),
                SizedBox(height: 20),
                Text(widget.category, style: GoogleFonts.lora(fontSize: 18)),
                SizedBox(height: 20),
                Text("Rs. ${widget.rate}", style: GoogleFonts.lora(fontSize: 18)),
                SizedBox(height: 20),
                Text(widget.description, style: GoogleFonts.lora(fontSize: 18)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: decrementQuantity,
                      icon: Icon(Icons.remove),
                    ),
                    Text(
                      '$quantity',
                      style: TextStyle(fontSize: 20),
                    ),
                    IconButton(
                      onPressed: incrementQuantity,
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: addToCart,
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      color:  Color(0xFFE0A45E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        "ADD TO CART",
                        style: NewCustomTextStyles.newcustomTextStyle
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
