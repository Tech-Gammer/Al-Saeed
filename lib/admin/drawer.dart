import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myfirstmainproject/admin/additems.dart';
import 'package:myfirstmainproject/admin/addunit.dart';
import 'package:myfirstmainproject/admin/admin.dart';
import 'package:myfirstmainproject/admin/loginpage.dart';
import 'package:myfirstmainproject/admin/ordermanagement.dart';
import 'package:myfirstmainproject/admin/showcategory.dart';
import 'package:myfirstmainproject/admin/showslider.dart';
import 'package:myfirstmainproject/admin/showunit.dart';
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
  String? adminNumber;
  late String adminId;


  @override
  void initState() {
    super.initState();
    fetchUserRole();
    _initializeadminData();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate back to the Sign In page
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      // print("Error signing out: $e"); // Handle error if necessary
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
      // print('Error fetching user role: $e');
      setState(() {
        userRole = 'Error';
      });
    }
  }

  Future<String> getAdminNumber(String adminId) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await databaseReference.child('admin/$adminId').once();
    if (event.snapshot.exists) {
      final riderData = Map<String, dynamic>.from(event.snapshot.value as Map);
      return riderData['adminNumber'] ?? '';
    }
    throw Exception('Admin not found');
  }

  Future<void> _initializeadminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
       adminId = user.uid; // Get the rider ID from Firebase Authentication
        adminNumber = await getAdminNumber(adminId);
        // print(adminId);
        // print(adminNumber);
        setState(() {}); // Refresh state once data is loaded
      }
    } catch (e) {
      // Handle errors
      // print('Error initializing rider data: $e');
    }
  }





  @override
  Widget build(BuildContext context) {

    final int? adminNumberInt = int.tryParse(adminNumber ?? '');

    return Drawer(
      child: ListView(
        children: <Widget>[
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text("Role: $userRole\nAdmin Number: $adminNumber",style: CustomTextStyles.customTextStyle, textAlign: TextAlign.center,),
              titleTextStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  color: Colors.grey,width: 1,
                ),
                borderRadius: BorderRadius.circular(10)
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("HOME",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const Admin()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("ADD ITEMS",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const AddItems()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("SHOW ITEMS",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ItemsPage()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("ADD CATEGORY",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const AddCategory()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("SHOW CATEGORY",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const ShowCategory()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("ADD SLIDER",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const AddSlider()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text("SHOW SLDIER IMAGES",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const SliderImages()));
            },
          ),const Divider(
            color: Colors.grey,
          ),ListTile(
            leading: const Icon(Icons.add),
            title: const Text("ADD UNITS",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const Addunit()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text("SHOW UNITS",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const ShowUnit()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text("ORDER MANAGEMENT",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderManagementPage()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          if (adminNumberInt == 1) // Conditionally show the Super Admin Panel
            ListTile(
            leading: const Icon(Icons.admin_panel_settings_sharp),
            title: const Text("SUPER ADMIN PANEL",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>SuperAdminPanel()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.storefront),
            title: const Text("SHOW FRONT SIDE",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const FrontPage()));
            },
          ),const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("LOG OUT",style: CustomTextStyles.customTextStyle),
            onTap: (){
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
