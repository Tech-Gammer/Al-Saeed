import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/addcategory.dart';
import 'package:myfirstmainproject/admin/additems.dart';
import 'package:myfirstmainproject/admin/addslider.dart';
import 'package:myfirstmainproject/admin/drawer.dart';
import 'package:myfirstmainproject/admin/itemslistpage.dart';
import 'package:myfirstmainproject/admin/showcategory.dart';
import 'package:myfirstmainproject/admin/showslider.dart';
import 'package:myfirstmainproject/admin/superadminpanel.dart';
import '../homepage.dart';
import 'loginpage.dart';
import 'ordermanagement.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  List<String> categories = [];
  List<String> items = [];
  int totalOrders = 0;
  String userRole = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchItems();
    fetchOrders();
    fetchUserRole();
  }

  Future<void> fetchCategories() async {
    try {
      final categoryRef = FirebaseDatabase.instance.ref("category");
      final snapshot = await categoryRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> fetchedCategories = data.values.map((value) => value['name'].toString()).toList();

        setState(() {
          categories = fetchedCategories;
        });
      } else {
        setState(() {
          categories = [];
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchItems() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        setState(() {
          items = [];
        });
        return;
      }

      // Reference to the user's items
      final itemsRef = FirebaseDatabase.instance.ref("items/$userId");

      // Fetch items for the current user
      final snapshot = await itemsRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        print('Fetched items data: $data'); // Debugging line

        // Extract item names from the data
        List<String> fetchedItems = data.values
            .map((item) => (item as Map)['item_name'].toString())
            .toList();

        setState(() {
          items = fetchedItems;
        });
      } else {
        setState(() {
          items = [];
        });
      }
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        items = [];
      });
    }
  }

  Future<void> fetchOrders() async {
    try {
      final ordersRef = FirebaseDatabase.instance.ref("orders");
      final snapshot = await ordersRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          totalOrders = data.length;
        });
      } else {
        setState(() {
          totalOrders = 0;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Future<void> fetchUserRole() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          userRole = 'No User';
        });
        return;
      }

      final userRef = FirebaseDatabase.instance.ref('admin/$userId/role');
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final role = snapshot.value;
        if (role is String) {
          setState(() {
            userRole = role == '0' ? 'Admin' : 'User';
          });
        } else {
          setState(() {
            userRole = 'Role is not a String';
          });
        }
      } else {
        setState(() {
          userRole = 'No Role';
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
      setState(() {
        userRole = 'Error';
      });
    }
  }


  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _globalKey,
        drawer: DrawerContent(),
        appBar: AppBar(
          title: SizedBox(
              width: 100,
              height: 70,
              child: Image.asset("images/logomain.png")
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  DashboardCard(
                    title: "Categories",
                    icon: Icons.category,
                    count: categories.length.toString(),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ShowCategory()));
                    },
                  ),
                  DashboardCard(
                    title: "Orders",
                    icon: Icons.shopping_cart,
                    count: totalOrders.toString(),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderManagementPage()));
                    },
                  ),
                  DashboardCard(
                    title: "Items",
                    icon: Icons.list,
                    count: items.length.toString(),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ItemsPage()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String count;
  final VoidCallback onTap;

  DashboardCard({required this.title, required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.all(10),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}