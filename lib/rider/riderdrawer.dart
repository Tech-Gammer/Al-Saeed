import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myfirstmainproject/rider/riderpage.dart';

import '../components.dart';
import '../homepage.dart';
import '../admin/loginpage.dart';

class riderdrawerpage extends StatefulWidget {
  const riderdrawerpage({super.key});

  @override
  State<riderdrawerpage> createState() => _riderdrawerpageState();
}

class _riderdrawerpageState extends State<riderdrawerpage> {
  String userRole = 'Loading...';
  late String riderId;
  String? riderNumber;

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

      final userRef = FirebaseDatabase.instance.ref('riders/$userId/role');

      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final role = snapshot.value;
        if (role is String) {
          setState(() {
            userRole = role == '0' ? 'ADMIN' : role == '1'? 'USER': 'Rider';
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

  Future<String> getRiderNumber(String riderId) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await databaseReference.child('riders/$riderId').once();
    if (event.snapshot.exists) {
      final riderData = Map<String, dynamic>.from(event.snapshot.value as Map);
      return riderData['riderNumber'] ?? ''; // Fetch rider number from the database
    }
    throw Exception('Rider not found');
  }

  Future<void> _initializeRiderData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        riderId = user.uid; // Get the rider ID from Firebase Authentication
        riderNumber = await getRiderNumber(riderId);
        // print(riderId);
        // print(riderNumber);
        setState(() {}); // Refresh state once data is loaded
      }
    } catch (e) {
      // Handle errors
      print('Error initializing rider data: $e');
    }
  }



  @override
  void initState() {
    super.initState();
    fetchUserRole();
    _initializeRiderData();
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
              title: Column(
                children: [
                  Text("Role: $userRole",style: CustomTextStyles.customTextStyle, textAlign: TextAlign.center,),
                  Text("Rider No. : $riderNumber",style: CustomTextStyles.customTextStyle, textAlign: TextAlign.center,),

                ],
              ),
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
            title: Text("All Orders Page",style: CustomTextStyles.customTextStyle),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrdersForRiders()));
            },
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
          ),
        ],
      ),
    );
  }
}
