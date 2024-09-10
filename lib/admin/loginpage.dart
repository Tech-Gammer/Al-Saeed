import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/admin.dart';
import 'package:myfirstmainproject/rider/riderpage.dart';
import 'package:myfirstmainproject/homepage.dart'; // Ensure this import is correct
import 'package:myfirstmainproject/admin/registerpage.dart';

import '../Model/datamodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth authentication = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final DatabaseReference userRef = FirebaseDatabase.instance.ref("users");
  bool isLoggingIn = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoggingIn = true;
      });

      try {
        // Sign in with Firebase Auth
        UserCredential userCredential = await authentication.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Get the user ID
        String uid = userCredential.user?.uid ?? '';

        // References to the admins, users, and riders nodes
        DatabaseReference adminRef = FirebaseDatabase.instance.ref("admin/$uid");
        DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");
        DatabaseReference riderRef = FirebaseDatabase.instance.ref("riders/$uid");

        // Check if user is in the admins node
        DataSnapshot adminSnapshot = await adminRef.get();

        if (adminSnapshot.exists) {
          // User is in the admin node
          Map<dynamic, dynamic> adminData = adminSnapshot.value as Map<dynamic, dynamic>;
          String role = adminData['role'] ?? '';

          if (role == '0') { // Admin role
            _showRolePrompt(
                "Admin Access",
                "You are logged in as an Admin. Would you like to go to the Admin side or the Home page?",
                const Admin(),
                "Admin Side",
                const FrontPage(),
                "Home Page"
            );
          } else {
            // Role not found or incorrect for admin
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid role for admin.')),
            );
          }
        } else {
          // Check if user is in the users node
          DataSnapshot userSnapshot = await userRef.get();

          if (userSnapshot.exists) {
            // User is in the users node
            Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
            String role = userData['role'] ?? '';

            if (role == '1') { // Buyer role
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const FrontPage()), // Ensure you have a FrontPage class
              );
            } else {
              // Role not found or incorrect for user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid role for user.')),
              );
            }
          } else {
            // Check if user is in the riders node
            DataSnapshot riderSnapshot = await riderRef.get();

            if (riderSnapshot.exists) {
              // User is in the riders node
              Map<dynamic, dynamic> riderData = riderSnapshot.value as Map<dynamic, dynamic>;
              String role = riderData['role'] ?? '';

              if (role == '2') {
                _showRolePrompt(
                    "Rider Access",
                    "You are logged in as a Rider. Would you like to go to the Riders page or the Home page?",
                    const OrdersForRiders(),
                    "Rider Page",
                    const FrontPage(),
                    "Home Page"
                );
              } else {
                // Role not found or incorrect for rider
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid role for rider.')),
                );
              }
            } else {
              // Handle case where user data doesn't exist in any node
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User data not found.')),
              );
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        // Handle authentication errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      } finally {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  void _showRolePrompt(
      String title,
      String content,
      Widget page1,
      String page1Text,
      Widget page2,
      String page2Text
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page1));
                  },
                  child: Text(page1Text, style: GoogleFonts.lora(color: Colors.black)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page2));
                  },
                  child: Text(page2Text, style: GoogleFonts.lora(color: Colors.black)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              child: const Row(
                children: [
                  Image(image: AssetImage("images/logomain.png")),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 310,
                height: 450,
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            hintText: "Enter your E-mail Address",
                            label: Text("E-mail"),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            hintText: "Enter Your Password",
                            labelText: "Password",
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        color: Colors.black,
                        child: InkWell(
                          onTap: isLoggingIn ? null : loginUser,
                          child: Container(
                            width: 200.0,
                            height: 50.0,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Center(
                              child: Text(
                                isLoggingIn ? "Logging in..." : "Login",
                                style: const TextStyle(
                                  fontSize: 25,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text("If not a registered member, click on"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return const RegisterPage();
                              }));
                            },
                            child: const Text("Register"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
