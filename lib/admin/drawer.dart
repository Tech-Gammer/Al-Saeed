import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/additems.dart';
import 'package:myfirstmainproject/admin/admin.dart';
import 'package:myfirstmainproject/admin/loginpage.dart';
import 'package:myfirstmainproject/admin/ordermanagement.dart';
import 'package:myfirstmainproject/admin/showcategory.dart';
import 'package:myfirstmainproject/admin/showslider.dart';
import 'package:myfirstmainproject/admin/superadminpanel.dart';
import 'package:myfirstmainproject/homepage.dart';
import '../components.dart';
import 'addcategory.dart';
import 'addslider.dart';
import 'itemslistpage.dart';

class DrawerContent extends StatefulWidget {
  const DrawerContent({super.key});

  @override
  State<DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  String userRole = 'Loading...';

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navigate back to the Sign In page
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      print("Error signing out: $e"); // Handle error if necessary
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
            userRole = role == '0' ? 'ADMIN' : 'USER';
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


  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text("Role: $userRole",style: CustomTextStyles.customTextStyle, textAlign: TextAlign.center,),
              titleTextStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey,width: 1,
                ),
                borderRadius: BorderRadius.circular(10)
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("HOME",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Admin()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("ADD ITEMS",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddItems()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.list_alt),
            title: Text("SHOW ITEMS",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ItemsPage()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("ADD CATEGORY",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddCategory()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.list_alt),
            title: Text("SHOW CATEGORY",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ShowCategory()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("ADD SLIDER",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddSlider()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text("SHOW SLDIER IMAGES",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>SliderImages()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.task),
            title: Text("ORDER MANAGEMENT",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderManagementPage()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.admin_panel_settings_sharp),
            title: Text("SUPER ADMIN PANEL",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>SuperAdminPanel()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.storefront),
            title: Text("SHOW FRONT SIDE",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>FrontPage()));
            },
          ),Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("LOG OUT",style: CustomTextStyles.customTextStyle),
            onTap: (){
              _logout();
            },
          )
        ],
      ),
    );
  }
}
