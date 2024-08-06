import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/drawerfrontside.dart';
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
  final DatabaseReference _dataRef = FirebaseDatabase.instance.ref("items");
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
          // If the role is not found in the users node, check in the admin node
          final adminRef = FirebaseDatabase.instance.ref("admin/${currentUser.uid}");
          final adminSnapshot = await adminRef.child("role").get();

          if (adminSnapshot.exists) {
            final int role = int.parse(adminSnapshot.value.toString());
            setState(() {
              _isAdmin = (role == 0); // Assuming 0 indicates admin
            });
          } else {
            // Handle case where role is not found in either node
            print("User role not found in both nodes.");
          }
        }
      } catch (e) {
        print('Error fetching user role: $e');
      }
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final Map<String, dynamic> itemsMap = {};
    try {
      final snapshot = await _dataRef.get();
      if (snapshot.exists) {
        final admins = snapshot.value as Map<dynamic, dynamic>;
        for (var adminId in admins.keys) {
          final adminItemsRef = _dataRef.child(adminId);
          final adminItemsSnapshot = await adminItemsRef.get();
          if (adminItemsSnapshot.exists) {
            final adminItems = adminItemsSnapshot.value as Map<dynamic, dynamic>;
            for (var itemId in adminItems.keys) {
              final itemData = adminItems[itemId] as Map<dynamic, dynamic>;
              // Ensure all values are converted to strings if needed
              final itemDataString = {
                'item_name': itemData['item_name']?.toString() ?? 'No Name',
                'category': itemData['category']?.toString() ?? 'No Category',
                'rate': itemData['rate']?.toString() ?? 'No Rate',
                'description': itemData['description']?.toString() ?? 'No description',
                'image': itemData['image']?.toString() ?? '',
              };
              itemsMap['$adminId/$itemId'] = itemDataString;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
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
      print('Error fetching slider images: $e');
    } finally {
      _checkIfLoadingComplete();
    }
  }

  Future<void> fetchCartItemCount() async {
    if (currentUser != null) {
      try {
        final userCartRef = _cartRef.child(currentUser!.uid);
        final snapshot = await userCartRef.get();
        if (snapshot.exists) {
          final cartItems = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _cartItemCount = cartItems.length;
          });
        } else {
          setState(() {
            _cartItemCount = 0;
          });
        }
      } catch (e) {
        print('Error fetching cart item count: $e');
      } finally {
        _checkIfLoadingComplete();
      }
    }
  }

  void _checkIfLoadingComplete() {
    Future.delayed(Duration(seconds: 5), () { // Adjust the duration here
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> signOut() async {
    await auth.signOut().then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = searchQuery.isNotEmpty;

    return SafeArea(
      child: Scaffold(
        key: _globalKey,
        drawer: Drawerfrontside(),
        appBar: AppBar(
          backgroundColor:  Color(0xFFe6b67e),
          title: SizedBox(
              width: 100,
              height: 70,
              child: Image.asset("images/logomain.png")
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton(
              icon: currentUser == null ? Icon(Icons.login) : Icon(Icons.person_rounded),
              itemBuilder: (BuildContext context) {
                return [
                  if (currentUser != null)
                    PopupMenuItem(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()));
                      },
                      child: Row(
                        children: [
                          Icon(Icons.person),
                          Text("       Profile"),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () {
                      if (currentUser == null) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: false)));
                      },
                      child: Row(
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
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_basket,),
                    onPressed: () {
                      if (currentUser == null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
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
          child: Column(
            children: [
              SizedBox(height: 6,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Search items...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear(); // Clears the text field
                        _filterItems(''); // Optionally clear the filter
                      },
                    )
                        : null,
                    contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  controller: _controller,
                  onChanged: _filterItems,
                ),
              ),

              // Conditionally display the slider and other data
              Visibility(
                visible: !isSearching,
                child: Column(
                  children: [
                    SizedBox(height: 10),
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
                                return Icon(Icons.image_not_supported, size: 300);
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
                                  width: _currentIndex == entry.key ? 17 : 7,
                                  height: 7.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
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
                    SizedBox(height: 10),
                    Text(
                      "We Provide Fresh Items",
                      style: GoogleFonts.berkshireSwash(
                        fontSize: 30,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCategoryIcon(Icons.cookie, "Sweets", "sweets"),
                              SizedBox(width: 15),
                              _buildCategoryIcon(Icons.local_pizza, "Pizza", "pizza"),
                              SizedBox(width: 15),
                              _buildCategoryIcon(Icons.icecream, "Icecream", "icecream"),
                              SizedBox(width: 15),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Available Items",
                      style: GoogleFonts.berkshireSwash(
                        fontSize: 24,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),

              // Display filtered items
              FutureBuilder<Map<String, dynamic>>(
                future: fetchData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final adminItems = snapshot.data!;
                  final filteredAdminItems = adminItems.entries.where((entry) {
                    final item = entry.value;
                    final item_name = item['item_name']?.toLowerCase() ?? '';
                    final category = item['category']?.toLowerCase() ?? '';
                    return item_name.contains(searchQuery) || category.contains(searchQuery);
                  }).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.5,
                    ),
                    itemCount: filteredAdminItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredAdminItems[index].value;
                      final imageUrl = item['image'] as String?;
                      final item_name = item['item_name'] as String? ?? 'No Name';
                      final category = item['category'] as String? ?? 'No Category';
                      final rate = item['rate'] as String? ?? 'No Rate';
                      final description = item['description'] as String? ?? 'No description';
                      final itemId = filteredAdminItems[index].key;
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
                                rate: rate,
                                description: description,
                                itemId: itemId,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 150,
                                width: 120,
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundImage: NetworkImage(imageUrl),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(item_name, style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 20, color: Colors.brown))),
                              Text(category, style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 14, color: Colors.brown))),
                              Text("Rs $rate", style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 14, color: Colors.brown))),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemSelectPage(
                                        imageUrl: imageUrl,
                                        category: category,
                                        rate: rate,
                                        description: description,
                                        itemId: itemId,
                                        item_name: item_name,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 150,
                                  height: 40,
                                  decoration: BoxDecoration(color: Color(0xFFE0A45E), borderRadius: BorderRadius.circular(20)),
                                  child: Center(
                                    child: Text(
                                      "ADD TO CART",
                                      style: GoogleFonts.lora(
                                        textStyle: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          : SizedBox.shrink();
                    },
                  );
                },
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryIcon(IconData icon, String label, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemListPage(uid: 'uid')));
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFe6b67e),
            radius: 30,
            child: Icon(icon, size: 30, color: Colors.brown),
          ),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Color(0xFFe6b67e),
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Alsaeed Sweets & Bakers",
            style: GoogleFonts.lora(
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 100,
            child: Image.asset('images/logomain.png'), // Replace with your logo asset
          ),
          SizedBox(height: 10),
          Text(
            "We offer a variety of fresh and delicious sweets and bakery items. Our commitment to quality and customer satisfaction is our top priority. Visit us for a delightful experience!",
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              textStyle: TextStyle(fontSize: 16, color: Colors.brown),
            ),
          ),
          SizedBox(height: 10),
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
          icon: Icon(FontAwesomeIcons.facebook, color: Colors.blue),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(FontAwesomeIcons.instagram, color: Colors.pink),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(FontAwesomeIcons.twitter, color: Colors.blue),
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
            Positioned(
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 8.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

