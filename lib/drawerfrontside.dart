import 'package:firebase_auth/firebase_auth.dart' as auth; // Alias Firebase User
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'admin/admin.dart';
import 'rider/riderpage.dart';
import 'components.dart';
import 'homepage.dart';
import 'itemslistpage.dart';


class Drawerfrontside extends StatefulWidget {
  const Drawerfrontside({super.key});

  @override
  State<Drawerfrontside> createState() => _DrawerfrontsideState();
}

class _DrawerfrontsideState extends State<Drawerfrontside> {
  // bool? _isAdmin;
  int? _role;
  // User? currentUser;
  auth.User? currentUser;


  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final currentUser = this.currentUser;
    if (currentUser != null) {
      try {
        final userRef = FirebaseDatabase.instance.ref("users/${currentUser.uid}");
        final snapshot = await userRef.child("role").get();

        if (snapshot.exists) {
          setState(() {
            _role = int.parse(snapshot.value.toString());
          });
        } else {
          // If the role is not found in the users node, check in the admin node
          final adminRef = FirebaseDatabase.instance.ref("admin/${currentUser.uid}");
          final adminSnapshot = await adminRef.child("role").get();

          if (adminSnapshot.exists) {
            setState(() {
              _role = int.parse(adminSnapshot.value.toString());
            });
          } else {
            // If the role is not found in the admin node, check in the riders node
            final riderRef = FirebaseDatabase.instance.ref("riders/${currentUser.uid}");
            final riderSnapshot = await riderRef.child("role").get();

            if (riderSnapshot.exists) {
              setState(() {
                _role = int.parse(riderSnapshot.value.toString());
              });
            } else {
              // Handle case where role is not found in any node
              print("User role not found in any node.");
            }
          }
        }
      } catch (e) {
        print('Error fetching user role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFE0A45E),
            ),
            accountName: const Text("Alsaeed Sweets & Bakers"),
            accountEmail: const Text("alsaeedsweetsbakers.org"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Image.asset("images/logomain.png"),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const FrontPage()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          if (_role == 0)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_sharp),
              title: const Text("Go To Admin Side",style: CustomTextStyles.customTextStyle),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const Admin()));
              },
            ),const Divider(
            color: Colors.grey,
          ),
          const Divider(color: Colors.grey),
          if (_role == 2) // If the role is rider
            ListTile(
              leading: const Icon(Icons.motorcycle),
              title: const Text("Go To Rider Side", style: CustomTextStyles.customTextStyle),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersForRiders())); // Replace with your Rider page
              },
            ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("Items List",style: CustomTextStyles.customTextStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ItemListPage(uid: 'uid')),
              );
            },
          ),const Divider(
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}


