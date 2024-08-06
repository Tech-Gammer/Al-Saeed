import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin/admin.dart';
import 'components.dart';
import 'homepage.dart';
import 'itemslistpage.dart';

class Drawerfrontside extends StatefulWidget {
  const Drawerfrontside({super.key});

  @override
  State<Drawerfrontside> createState() => _DrawerfrontsideState();
}

class _DrawerfrontsideState extends State<Drawerfrontside> {
  bool? _isAdmin;
  User? currentUser;

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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFE0A45E),
            ),
            accountName: Text("Alsaeed Sweets & Bakers"),
            accountEmail: Text("alsaeedsweetsbakers.org"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Image.asset("images/logomain.png"),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Home",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>FrontPage()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          if (_isAdmin == true)
            ListTile(
              leading: Icon(Icons.admin_panel_settings_sharp),
              title: Text("Go To Admin Side",style: CustomTextStyles.customTextStyle),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Admin()));
              },
            ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.list_alt),
            title: Text("Items List",style: CustomTextStyles.customTextStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ItemListPage(uid: 'uid')),
              );
            },
          ),Divider(
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}