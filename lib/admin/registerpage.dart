import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myfirstmainproject/admin/loginpage.dart';
import '../Model/datamodel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authentication = FirebaseAuth.instance;
  final nc = TextEditingController();
  final ec = TextEditingController();
  final phonec = TextEditingController();
  final pass = TextEditingController();
  final DatabaseReference dref = FirebaseDatabase.instance.ref();

  final String defaultRole = "1"; // Default role for all new users, e.g., "1" for Buyer

  void Registeruser() async {
    try {
      // Register the user with email and password
      UserCredential userCredential = await authentication.createUserWithEmailAndPassword(
        email: ec.text.trim(),
        password: pass.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User authenticated")),
      );

      // Reference to the users and admin nodes
      final DatabaseReference usersRef = dref.child('users');
      final DatabaseReference adminRef = dref.child('admin');

      // Check if the admin node is empty to determine if this is the first user
      DataSnapshot adminSnapshot = await adminRef.get();
      bool isFirstUser = !adminSnapshot.exists || adminSnapshot.children.isEmpty;

      // Determine the role and the node to store the user
      String userRole = isFirstUser ? '0' : '1'; // '0' for admin (first user), '1' for regular user
      DatabaseReference userRef = isFirstUser ? adminRef.child(uid) : usersRef.child(uid);

      // Create the appropriate model
      if (isFirstUser) {
        // First user is an admin
        AdminModel adminModel = AdminModel(
          uid,
          nc.text.trim(),
          ec.text.trim(),
          phonec.text.trim(),
          pass.text.trim(),
          userRole,
        );

        // Save the admin data to the admin node
        await adminRef.child(uid).set(adminModel.toMap());
      } else {
        // Regular user
        UserModel userModel = UserModel(
          uid,
          nc.text.trim(),
          ec.text.trim(),
          phonec.text.trim(),
          pass.text.trim(),
          userRole,
        );

        // Save the user data to the users node
        await usersRef.child(uid).set(userModel.toMap());
      }

      // Send verification email
      User? user = authentication.currentUser;
      if (user != null) {
        await user.sendEmailVerification();

        // Show verification email sent message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification email sent. Please check your email.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found for sending verification email.")),
        );
      }

      // Navigate to the LoginPage
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));

    } catch (error) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              child: Image.asset("images/logomain.png"),
            ),
            Center(
              child: Container(
                width: 300,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: nc,
                        decoration: InputDecoration(
                          hintText: "Enter Your Name",
                          labelText: "Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: ec,
                        decoration: InputDecoration(
                          hintText: "Enter Your Email Address",
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: phonec,
                        decoration: InputDecoration(
                          hintText: "Enter Your Phone No",
                          labelText: "Phone No",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: pass,
                        decoration: InputDecoration(
                          hintText: "Enter Your Password",
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      color: Colors.black,
                      child: InkWell(
                        onTap: () {
                          Registeruser();
                        },
                        child: Container(
                          width: 200.0,
                          height: 50.0,
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(20))),
                          child: Center(child: Text("Register", style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text("If you are already registered, please click on"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                          },
                          child: Text("Login"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
