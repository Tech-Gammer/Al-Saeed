import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'drawerfrontside.dart';
import 'itemslistpage.dart';
import 'userprofile.dart';
import 'admin/loginpage.dart';
import 'cartitems.dart';
import 'itemselectpage.dart';
import 'orderslist.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  final DatabaseReference _ratingRef = FirebaseDatabase.instance.ref("Feedback");
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _sliderRef = FirebaseDatabase.instance.ref("slider images");
  final FirebaseAuth auth = FirebaseAuth.instance;
  final CarouselController _carouselController = CarouselController();
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? data;
  int _cartItemCount = 0;
  User? currentUser;
  List<String> sliderImages = [];
  bool _isLoading = true;
  bool? _isAdmin;
  String searchQuery = '';
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchSliderImages();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchCartItemCount();
    fetchUserRole();
  }

  Future<double> fetchRating(String itemId) async {
    try {
      double addrating = 0;
      double? avgRating;
      final snapshot = await _ratingRef.orderByChild('itemId').equalTo(itemId).get();
      if (snapshot.exists) {
        final Map<String, dynamic> allData = {};
        final dataSnapshot = snapshot.value as Map;
        List<dynamic> itemList = [];
        itemList = dataSnapshot.values.toList();

        for (int i = 0; i < itemList.length; i++) {
          addrating += double.parse(itemList[i]['rating'].toString());
        }

        avgRating = (addrating / itemList.length);

        // print(avgRating);
        return avgRating;
      } else {
        return 0;
      }
    } catch (e) {
      // print('Error fetching data: $e');
      return 0;
    }
  }

  Future<void> fetchUserRole() async {
    final currentUser = this.currentUser;
    if (currentUser != null) {
      try {
        final userRef = FirebaseDatabase.instance.ref("users/${currentUser.uid}");
        final snapshot = await userRef.child("role").get();

        if (snapshot.exists) {
          final int role = int.parse(snapshot.value.toString());
          setState(() {
            _isAdmin = (role == 0); // Assuming 0 indicates admin
          });
        } else {
          final adminRef = FirebaseDatabase.instance.ref("admin/${currentUser.uid}");
          final adminSnapshot = await adminRef.child("role").get();

          if (adminSnapshot.exists) {
            final int role = int.parse(adminSnapshot.value.toString());
            setState(() {
              _isAdmin = (role == 0); // Assuming 0 indicates admin
            });
          } else {
            // print("User role not found in both nodes.");
          }
        }
      } catch (e) {
        // print('Error fetching user role: $e');
      }
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final Map<String, dynamic> itemsMap = {};
    final DatabaseReference itemsRef = FirebaseDatabase.instance.ref('items');

    try {
      final snapshot = await itemsRef.get();
      if (snapshot.exists) {
        final items = snapshot.value as Map<dynamic, dynamic>;
        for (var itemId in items.keys) {
          final itemData = items[itemId] as Map<dynamic, dynamic>;
          final itemDataString = {
            'item_name': itemData['item_name']?.toString() ?? 'No Name',
            'category': itemData['category']?.toString() ?? 'No Category',
            'net_rate': itemData['net_rate']?.toString() ?? 'No Rate',
            'item_qty': itemData['item_qty']?.toString() ?? 'No Quantity',
            'unit': itemData['unit']?.toString() ?? 'No unit',

            'ptc_code': itemData['ptc_code']?.toString() ?? 'No Rate',
            'barcode': itemData['barcode']?.toString() ?? 'No Rate',
            'description': itemData['description']?.toString() ?? 'No description',
            'image': itemData['image']?.toString() ?? '',
            'adminId': itemData['adminId']?.toString() ?? '',
          };
          itemsMap[itemId] = itemDataString;
        }
      }
    } catch (e) {
      // print('Error fetching data: $e');
    }

    return itemsMap;
  }

  Future<void> fetchSliderImages() async {
    try {
      final snapshot = await _sliderRef.get();
      if (snapshot.exists) {
        final images = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          sliderImages = images.values.map((value) => value['image'] as String).toList();
        });
      }
    } catch (e) {
      // print('Error fetching slider images: $e');
    } finally {
      _checkIfLoadingComplete();
    }
  }

  Future<void> fetchCartItemCount() async {
    if (currentUser != null) {
      try {
        String userId = currentUser!.uid;
        final userCartRef = _cartRef.child(userId); // Reference to the current user's cart
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

  void _checkIfLoadingComplete() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> signOut() async {
    await auth.signOut().then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  // Widget build(BuildContext context) {
  //   final isSearching = searchQuery.isNotEmpty;
  //   double rating;
  //
  //   return SafeArea(
  //     child: Scaffold(
  //       key: _globalKey,
  //       drawer: const Drawerfrontside(),
  //       appBar: AppBar(
  //         flexibleSpace: Image(
  //           image: const AssetImage('images/art.jpg'),
  //           color: Colors.white.withOpacity(0.5), colorBlendMode: BlendMode.modulate,
  //           fit: BoxFit.cover,
  //         ),
  //
  //         title: SizedBox(
  //           width: 100,
  //           height: 70,
  //           child: Image.asset("images/logomain.png"),
  //         ),
  //         centerTitle: true,
  //         actions: [
  //           PopupMenuButton(
  //             icon: currentUser == null ? const Icon(Icons.login) : const Icon(Icons.person_rounded),
  //             itemBuilder: (BuildContext context) {
  //               return [
  //                 if (currentUser != null)
  //                   PopupMenuItem(
  //                     onTap: () {
  //                       Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()));
  //                     },
  //                     child: const Row(
  //                       children: [
  //                         Icon(Icons.person),
  //                         Text("       Profile"),
  //                       ],
  //                     ),
  //                   ),
  //                 PopupMenuItem(
  //                   onTap: () {
  //                     if (currentUser == null) {
  //                       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  //                     } else {
  //                       signOut();
  //                     }
  //                   },
  //                   child: Row(
  //                     children: [
  //                       Icon(currentUser == null ? Icons.login : Icons.logout),
  //                       Text(currentUser == null ? "       Log In" : "       Log Out"),
  //                     ],
  //                   ),
  //                 ),
  //                 if (currentUser != null)
  //                   PopupMenuItem(
  //                     onTap: () {
  //                       Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: false)));
  //                     },
  //                     child: const Row(
  //                       children: [
  //                         Icon(Icons.shopping_cart),
  //                         Text("       Orders"),
  //                       ],
  //                     ),
  //                   ),
  //               ];
  //             },
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.only(right: 10),
  //             child: Stack(
  //               clipBehavior: Clip.none,
  //               children: [
  //                 IconButton(
  //                   icon: const Icon(Icons.shopping_basket),
  //                   onPressed: () {
  //                     if (currentUser == null) {
  //                       Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  //                     } else {
  //                       Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
  //                     }
  //                   },
  //                 ),
  //                 if (_cartItemCount > 0)
  //                   Positioned(
  //                     right: 5,
  //                     top: 8,
  //                     child: CircleAvatar(
  //                       radius: 8.0,
  //                       backgroundColor: Colors.red,
  //                       foregroundColor: Colors.white,
  //                       child: Text(
  //                         _cartItemCount.toString(),
  //                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       body: _isLoading
  //           ? CustomLoader()
  //           : SingleChildScrollView(
  //         child: Container(
  //           decoration: BoxDecoration(
  //             image: DecorationImage(
  //               image: const AssetImage("images/art.jpg"),
  //               fit: BoxFit.fitHeight,
  //               colorFilter: ColorFilter.mode(
  //                 Colors.black.withOpacity(0.2), // Adjust opacity here
  //                 BlendMode.dstATop,
  //               ),
  //             ),
  //           ),
  //           child: Column(
  //             children: [
  //               const SizedBox(height:6),
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 10),
  //                 child: SizedBox(
  //                   height: 50,
  //                   child: TextField(
  //                     controller: _controller,
  //                     decoration: InputDecoration(
  //                       suffixIcon: IconButton(
  //                         icon: const Icon(Icons.search),
  //                         onPressed: () {
  //                           _filterItems(_controller.text);
  //                         },
  //                       ),
  //                       hintText: 'Search',
  //                       filled: true,
  //                       fillColor: const Color(0xFFe6b67e).withOpacity(0.2),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: const BorderSide(color: Color(0xFFe6b67e)),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: const BorderSide(color: Color(0xFFe6b67e)),
  //                       ),
  //                     ),
  //                     onChanged: _filterItems,
  //                   ),
  //                 ),
  //               ),
  //               Visibility(
  //                 visible: !isSearching,
  //                 child: Column(
  //                   children: [
  //                     const SizedBox(height: 10),
  //                     Stack(
  //                       children: [
  //                         InkWell(
  //                           onTap: () {
  //                             print(_currentIndex);
  //                           },
  //                           child: CarouselSlider(
  //                             items: sliderImages
  //                                 .map((imageUrl) => Image.network(
  //                               imageUrl,
  //                               fit: BoxFit.fitHeight,
  //                               width: double.infinity,
  //                               errorBuilder: (context, error, stackTrace) {
  //                                 return const Icon(Icons.image_not_supported, size: 300);
  //                               },
  //                             ))
  //                                 .toList(),
  //                             carouselController: _carouselController,
  //                             options: CarouselOptions(
  //                               scrollPhysics: const BouncingScrollPhysics(),
  //                               autoPlay: true,
  //                               aspectRatio: 2,
  //                               viewportFraction: 1,
  //                               onPageChanged: (index, reason) {
  //                                 setState(() {
  //                                   _currentIndex = index;
  //                                 });
  //                               },
  //                             ),
  //                           ),
  //                         ),
  //                         Positioned(
  //                           bottom: 0,
  //                           left: 0,
  //                           right: 0,
  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: sliderImages.asMap().entries.map((entry) {
  //                               return GestureDetector(
  //                                 onTap: () => _carouselController.animateToPage(entry.key),
  //                                 child: Container(
  //                                   width: _currentIndex == entry.key ? 17 : 7,
  //                                   height: 7.0,
  //                                   margin: const EdgeInsets.symmetric(horizontal: 3.0),
  //                                   decoration: BoxDecoration(
  //                                     borderRadius: BorderRadius.circular(10),
  //                                     color: _currentIndex == entry.key ? Colors.brown : Colors.grey,
  //                                   ),
  //                                 ),
  //                               );
  //                             }).toList(),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 10),
  //                     Text(
  //                       "We Provide Fresh Items",
  //                       style: GoogleFonts.berkshireSwash(
  //                         fontSize: 30,
  //                         color: Colors.brown,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     Padding(
  //                       padding: const EdgeInsets.all(8.0),
  //                       child: Column(
  //                         children: [
  //                           Row(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               _buildCategoryIcon(Icons.cookie, "Sweets", "sweets"),
  //                               const SizedBox(width: 15),
  //                               _buildCategoryIcon(Icons.local_pizza, "Pizza", "pizza"),
  //                               const SizedBox(width: 15),
  //                               _buildCategoryIcon(Icons.icecream, "Icecream", "icecream"),
  //                               const SizedBox(width: 15),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     Text(
  //                       "Available Items",
  //                       style: GoogleFonts.berkshireSwash(
  //                         fontSize: 24,
  //                         color: Colors.brown,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                   ],
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: Column(
  //                   children: [
  //
  //                     const SizedBox(height: 16),
  //                     FutureBuilder<Map<String, dynamic>>(
  //                       future: fetchData(),
  //                       builder: (context, snapshot) {
  //                         if (snapshot.connectionState == ConnectionState.active) {
  //                           return const Center(child: CircularProgressIndicator());
  //                         } else if (snapshot.hasError) {
  //                           return Center(child: Text('Error fetching data: ${snapshot.error}'));
  //                         } else if (snapshot.hasData) {
  //                           final Map<String, dynamic> itemsMap = snapshot.data!;
  //                           final filteredItems = itemsMap.entries.where((entry) {
  //                             final item = entry.value;
  //                             return item['item_name'].toString().toLowerCase().contains(searchQuery);
  //                           }).toList();
  //
  //                           return GridView.builder(
  //                             shrinkWrap: true,
  //                             physics: const NeverScrollableScrollPhysics(),
  //                             padding: const EdgeInsets.all(8.0),
  //                             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                               crossAxisCount: 2,
  //                               crossAxisSpacing: 16.0,
  //                               mainAxisSpacing: 16.0,
  //                               childAspectRatio: 0.6,
  //                             ),
  //                             itemCount: filteredItems.length,
  //                             itemBuilder: (context, index) {
  //                               final item = filteredItems[index].value;
  //                               final imageUrl = item['image'] as String?;
  //                               final item_name = item['item_name'] as String? ?? 'No Name';
  //                               final category = item['category'] as String? ?? 'No Category';
  //                               final rate = item['rate'] as String? ?? 'No Rate';
  //                               final description = item['description'] as String? ?? 'No description';
  //                               final adminId = item['adminId'] as String? ?? 'No adminId';
  //                               final itemId = filteredItems[index].key;
  //
  //                               return FutureBuilder<double>(
  //                                 future: fetchRating(itemId),
  //                                 builder: (context, snapshot) {
  //                                   rating = snapshot.data ?? 3.0;
  //                                   return imageUrl != null && imageUrl.isNotEmpty
  //                                       ? GestureDetector(
  //                                     onTap: () {
  //                                       Navigator.push(
  //                                         context,
  //                                         MaterialPageRoute(
  //                                           builder: (context) => ItemSelectPage(
  //                                             item_name: item_name,
  //                                             imageUrl: imageUrl,
  //                                             category: category,
  //                                             rate: rate,
  //                                             description: description,
  //                                             itemId: itemId,
  //                                             adminId: adminId,
  //                                           ),
  //                                         ),
  //                                       );
  //                                     },
  //                                     child: Stack(
  //                                       children: [
  //                                         Card(
  //                                           elevation: 5,
  //                                           child: Column(
  //                                             mainAxisAlignment: MainAxisAlignment.center,
  //                                             children: [
  //                                               SizedBox(
  //                                                 height: 120,
  //                                                 width: 120,
  //                                                 child: CircleAvatar(
  //                                                   radius: 70,
  //                                                   backgroundImage: NetworkImage(imageUrl),
  //                                                 ),
  //                                               ),
  //                                               const SizedBox(height: 8),
  //                                               Center(
  //                                                 child: Padding(
  //                                                   padding: const EdgeInsets.symmetric(horizontal: 5),
  //                                                   child: Text(
  //                                                     item_name,
  //                                                     style: GoogleFonts.lora(
  //                                                       textStyle: const TextStyle(fontSize: 18, color: Colors.brown, fontWeight: FontWeight.bold),
  //                                                     ),
  //                                                     maxLines: 2,
  //                                                     textAlign: TextAlign.center,
  //                                                   ),
  //                                                 ),
  //                                               ),
  //                                               Text(
  //                                                 category,
  //                                                 style: GoogleFonts.lora(
  //                                                   textStyle: const TextStyle(fontSize: 14, color: Colors.brown),
  //                                                 ),
  //                                               ),
  //                                               Text(
  //                                                 "Rs $rate",
  //                                                 style: GoogleFonts.lora(
  //                                                   textStyle: const TextStyle(fontSize: 14, color: Colors.brown),
  //                                                 ),
  //                                               ),
  //                                               const SizedBox(height: 8),
  //                                               RatingBar.builder(
  //                                                 ignoreGestures: true,
  //                                                 itemSize: 25,
  //                                                 initialRating: rating,
  //                                                 minRating: 1,
  //                                                 direction: Axis.horizontal,
  //                                                 allowHalfRating: true,
  //                                                 itemCount: 5,
  //                                                 itemBuilder: (context, _) => const Icon(
  //                                                   Icons.star,
  //                                                   color: Colors.amber,
  //                                                 ),
  //                                                 onRatingUpdate: (newRating) {
  //                                                   // Optional: handle rating update if needed
  //                                                 },
  //                                               ),
  //                                               const SizedBox(height: 8),
  //                                             ],
  //                                           ),
  //                                         ),
  //                                         Positioned(
  //                                           top: 10,
  //                                           right: 10,
  //                                           child: GestureDetector(
  //                                             onTap: () {
  //                                               Navigator.push(
  //                                                 context,
  //                                                 MaterialPageRoute(
  //                                                   builder: (context) => ItemSelectPage(
  //                                                     item_name: item_name,
  //                                                     imageUrl: imageUrl,
  //                                                     category: category,
  //                                                     rate: rate,
  //                                                     description: description,
  //                                                     itemId: itemId,
  //                                                     adminId: adminId,
  //                                                   ),
  //                                                 ),
  //                                               );
  //                                             },
  //                                             child: Container(
  //                                               padding: const EdgeInsets.all(8),
  //                                               decoration: const BoxDecoration(
  //                                                 color: Colors.orange,
  //                                                 shape: BoxShape.circle,
  //                                                 boxShadow: [
  //                                                   BoxShadow(
  //                                                     color: Colors.black26,
  //                                                     offset: Offset(2, 2),
  //                                                     blurRadius: 4,
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                               child: const Icon(
  //                                                 Icons.shopping_basket,
  //                                                 color: Colors.white,
  //                                                 size: 24,
  //                                               ),
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //
  //                                   )
  //                                       : const SizedBox.shrink();
  //                                 },
  //                               );
  //                             },
  //                           );
  //                         } else {
  //                           return const CircularProgressIndicator();
  //                         }
  //                       },
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               _buildFooter(),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget build(BuildContext context) {
    final isSearching = searchQuery.isNotEmpty;
    double rating;

    // Use MediaQuery to get screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        key: _globalKey,
        drawer: const Drawerfrontside(),
        appBar: AppBar(
          flexibleSpace: Image(
            image: const AssetImage('images/art.jpg'),
            color: Colors.white.withOpacity(0.5),
            colorBlendMode: BlendMode.modulate,
            fit: BoxFit.cover,
          ),
          title: SizedBox(
            width: screenWidth * 0.25, // Adjusted width based on screen size
            height: screenHeight * 0.1, // Adjusted height based on screen size
            child: Image.asset("images/logomain.png"),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton(
              icon: currentUser == null
                  ? const Icon(Icons.login)
                  : const Icon(Icons.person_rounded),
              itemBuilder: (BuildContext context) {
                return [
                  if (currentUser != null)
                    PopupMenuItem(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()));
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.person),
                          Text("       Profile"),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () {
                      if (currentUser == null) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      } else {
                        signOut();
                      }
                    },
                    child: Row(
                      children: [
                        Icon(currentUser == null ? Icons.login : Icons.logout),
                        Text(currentUser == null ? "       Log In" : "       Log Out"),
                      ],
                    ),
                  ),
                  if (currentUser != null)
                    PopupMenuItem(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CustomerOrdersPage(
                                  comingFromCheckoutPage: false,
                                )));
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.shopping_cart),
                          Text("       Orders"),
                        ],
                      ),
                    ),
                ];
              },
            ),
            Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.025), // Responsive padding
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
                        radius: screenWidth * 0.02, // Responsive radius
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        child: Text(
                          _cartItemCount.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.03), // Responsive font size
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? CustomLoader()
            : SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("images/art.jpg"),
                fit: BoxFit.fitHeight,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2), // Adjust opacity here
                  BlendMode.dstATop,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025), // Responsive padding
                  child: SizedBox(
                    height: screenHeight * 0.06, // Responsive height
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _filterItems(_controller.text);
                          },
                        ),
                        hintText: 'Search',
                        filled: true,
                        fillColor: const Color(0xFFe6b67e).withOpacity(0.2),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFe6b67e)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFe6b67e)),
                        ),
                      ),
                      onChanged: _filterItems,
                    ),
                  ),
                ),
                Visibility(
                  visible: !isSearching,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          InkWell(
                            onTap: () {
                              print(_currentIndex);
                            },
                            child: CarouselSlider(
                              items: sliderImages
                                  .map((imageUrl) => Image.network(
                                imageUrl,
                                fit: BoxFit.fitHeight,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported, size: 300);
                                },
                              ))
                                  .toList(),
                              carouselController: _carouselController,
                              options: CarouselOptions(
                                scrollPhysics: const BouncingScrollPhysics(),
                                autoPlay: true,
                                aspectRatio: 2,
                                viewportFraction: 1,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: sliderImages.asMap().entries.map((entry) {
                                return GestureDetector(
                                  onTap: () => _carouselController.animateToPage(entry.key),
                                  child: Container(
                                    width: _currentIndex == entry.key ? screenWidth * 0.045 : screenWidth * 0.018, // Responsive width
                                    height: screenHeight * 0.01, // Responsive height
                                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.008), // Responsive margin
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: _currentIndex == entry.key ? Colors.brown : Colors.grey,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "We Provide Fresh Items",
                        style: GoogleFonts.berkshireSwash(
                          fontSize: screenWidth * 0.08, // Responsive font size
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02), // Responsive padding
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCategoryIcon(Icons.cookie, "Sweets", "sweets"),
                                SizedBox(width: screenWidth * 0.04), // Responsive spacing
                                _buildCategoryIcon(Icons.local_pizza, "Pizza", "pizza"),
                                SizedBox(width: screenWidth * 0.04),
                                _buildCategoryIcon(Icons.icecream, "Icecream", "icecream"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Available Items",
                        style: GoogleFonts.berkshireSwash(
                          fontSize: screenWidth * 0.06, // Responsive font size
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02), // Responsive padding
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, dynamic>>(
                        future: fetchData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.active) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error fetching data: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            final Map<String, dynamic> itemsMap = snapshot.data!;
                            final filteredItems = itemsMap.entries.where((entry) {
                              final item = entry.value;
                              return item['item_name'].toString().toLowerCase().contains(searchQuery);
                            }).toList();

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(screenWidth * 0.02), // Responsive padding
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: screenWidth * 0.04, // Responsive spacing
                                mainAxisSpacing: screenWidth * 0.04,
                                childAspectRatio: 0.6,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index].value;
                                final imageUrl = item['image'] as String?;
                                final item_name = item['item_name'] as String? ?? 'No Name';
                                final category = item['category'] as String? ?? 'No Category';
                                final net_rate = item['net_rate'] as String? ?? 'No Rate';
                                final item_qty = item['item_qty'] as String? ?? 'No item_qty';
                                final unit = item['unit'] as String? ?? 'No unit';

                                final barcode = item['barcode'] as String? ?? 'No barcode';
                                final ptc_code = item['ptc_code'] as String? ?? 'No barcode';
                                final description = item['description'] as String? ?? 'No description';
                                final adminId = item['adminId'] as String? ?? 'No adminId';
                                final itemId = filteredItems[index].key;

                                return FutureBuilder<double>(
                                  future: fetchRating(itemId),
                                  builder: (context, snapshot) {
                                    rating = snapshot.data ?? 3.0;
                                    return imageUrl != null && imageUrl.isNotEmpty
                                        ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ItemSelectPage(
                                              item_name: item_name,
                                              imageUrl: imageUrl,
                                              category: category,
                                                item_qty:item_qty,
                                                net_rate: net_rate,
                                              description: description,
                                              itemId: itemId,
                                              unit: unit,
                                              adminId: adminId,
                                              barcode: barcode,
                                              ptc_code: ptc_code
                                            ),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          Card(
                                            elevation: 5,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: screenHeight * 0.15, // Responsive height
                                                  width: screenWidth * 0.3, // Responsive width
                                                  child: CircleAvatar(
                                                    radius: screenWidth * 0.18, // Responsive radius
                                                    backgroundImage: NetworkImage(imageUrl),
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01), // Responsive padding
                                                    child: Text(
                                                      item_name,
                                                      style: GoogleFonts.lora(
                                                        textStyle: TextStyle(
                                                            fontSize: screenWidth * 0.045,
                                                            color: Colors.brown,
                                                            fontWeight: FontWeight.bold), // Responsive font size
                                                      ),
                                                      maxLines: 2,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  category,
                                                  style: GoogleFonts.lora(
                                                    textStyle: TextStyle(fontSize: screenWidth * 0.035, color: Colors.brown), // Responsive font size
                                                  ),
                                                ),
                                                Text(
                                                  "Rs $net_rate",
                                                  style: GoogleFonts.lora(
                                                    textStyle: TextStyle(fontSize: screenWidth * 0.035, color: Colors.brown), // Responsive font size
                                                  ),
                                                ),
                                                Text(
                                                  "Quantity $item_qty",
                                                  style: GoogleFonts.lora(
                                                    textStyle: TextStyle(fontSize: screenWidth * 0.035, color: Colors.brown), // Responsive font size
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                RatingBar.builder(
                                                  ignoreGestures: true,
                                                  itemSize: screenWidth * 0.065, // Responsive item size
                                                  initialRating: rating,
                                                  minRating: 1,
                                                  direction: Axis.horizontal,
                                                  allowHalfRating: true,
                                                  itemCount: 5,
                                                  itemBuilder: (context, _) => const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                  ),
                                                  onRatingUpdate: (newRating) {
                                                    // Optional: handle rating update if needed
                                                  },
                                                ),
                                                const SizedBox(height: 5),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: screenHeight * 0.01,
                                            right: screenWidth * 0.03,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ItemSelectPage(
                                                      item_name: item_name,
                                                      imageUrl: imageUrl,
                                                      category: category,
                                                        item_qty:item_qty,
                                                        unit: unit,
                                                        net_rate: net_rate,
                                                      description: description,
                                                      itemId: itemId,
                                                      adminId: adminId,
                                                        barcode: barcode,
                                                        ptc_code: ptc_code
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(screenWidth * 0.02), // Responsive padding
                                                decoration: const BoxDecoration(
                                                  color: Colors.orange,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      offset: Offset(2, 2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.shopping_basket,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : const SizedBox.shrink();
                                  },
                                );
                              },
                            );
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryIcon(IconData icon, String label, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemListPage(uid: 'uid')));
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFe6b67e),
            radius: 30,
            child: Icon(icon, size: 30, color: Colors.brown),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      // color: Color(0xFFe6b67e),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage("images/art.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5), // Adjust opacity here
            BlendMode.dstATop,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Alsaeed Sweets & Bakers",
            style: GoogleFonts.lora(
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 100,
            child: Image.asset('images/logomain.png'), // Replace with your logo asset
          ),
          const SizedBox(height: 10),
          Text(
            "We offer a variety of fresh and delicious sweets and bakery items. Our commitment to quality and customer satisfaction is our top priority. Visit us for a delightful experience!",
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              textStyle: const TextStyle(fontSize: 16, color: Colors.brown),
            ),
          ),
          const SizedBox(height: 10),
          _buildSocialMediaLinks(),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(FontAwesomeIcons.facebook, color: Colors.blue),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(FontAwesomeIcons.instagram, color: Colors.pink),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(FontAwesomeIcons.twitter, color: Colors.blue),
          onPressed: () {},
        ),
      ],
    );
  }

}

class CustomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 110,  // Adjust size as needed
        height: 110, // Adjust size as needed
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo image positioned above the loader
            Positioned(
              top: 0,
              child: Image.asset(
                'images/logomain.png', // Replace with your logo asset path
                width: 70,  // Adjust size as needed
                height: 70, // Adjust size as needed
              ),
            ),
            // Loader positioned below the logo
            const Positioned(
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 8.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
            ),
          ],
        ),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}


