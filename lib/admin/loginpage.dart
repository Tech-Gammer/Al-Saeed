import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/admin.dart';
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

  // void loginUser() async {
  //   if (formKey.currentState?.validate() ?? false) {
  //     setState(() {
  //       isLoggingIn = true;
  //     });
  //
  //     try {
  //       // Sign in with Firebase Auth
  //       UserCredential userCredential = await authentication.signInWithEmailAndPassword(
  //         email: emailController.text.trim(),
  //         password: passwordController.text.trim(),
  //       );
  //
  //       // Get the user ID
  //       String uid = userCredential.user?.uid ?? '';
  //
  //
  //       // References to the users and admins nodes
  //       DatabaseReference adminRef = FirebaseDatabase.instance.ref("admins/$uid");
  //       DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");
  //
  //
  //       // Fetch data from both nodes
  //       DataSnapshot userSnapshot = await userRef.get();
  //       DataSnapshot adminSnapshot = await adminRef.get();
  //
  //       if (adminSnapshot.exists) {
  //         // User is in the admin node
  //         Map<dynamic, dynamic> adminData = adminSnapshot.value as Map<dynamic, dynamic>;
  //         String role = adminData['role'] ?? '';
  //
  //         if (role == '0') { // Admin role
  //           _showAdminPrompt();
  //         } else {
  //           // Role not found or incorrect
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Invalid role for admin.')),
  //           );
  //         }
  //       } else if (userSnapshot.exists) {
  //         // User is in the users node
  //         Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
  //         String role = userData['role'] ?? '';
  //
  //         if (role == '1') { // Buyer role
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (context) => FrontPage()), // Ensure you have a FrontPage class
  //           );
  //         } else {
  //           // Role not found or incorrect
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Invalid role for user.')),
  //           );
  //         }
  //       } else {
  //         // Handle case where user data doesn't exist in either node
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('User data not found.')),
  //         );
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       // Handle authentication errors
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error: ${e.message}')),
  //       );
  //     } finally {
  //       setState(() {
  //         isLoggingIn = false;
  //       });
  //     }
  //   }
  // }


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

        // References to the admins and users nodes
        DatabaseReference adminRef = FirebaseDatabase.instance.ref("admin/$uid");
        DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");

        // Check if user is in the admins node
        DataSnapshot adminSnapshot = await adminRef.get();

        if (adminSnapshot.exists) {
          // User is in the admin node
          Map<dynamic, dynamic> adminData = adminSnapshot.value as Map<dynamic, dynamic>;
          String role = adminData['role'] ?? '';

          if (role == '0') { // Admin role
            _showAdminPrompt();
          } else {
            // Role not found or incorrect for admin
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid role for admin.')),
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
                MaterialPageRoute(builder: (context) => FrontPage()), // Ensure you have a FrontPage class
              );
            } else {
              // Role not found or incorrect for user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid role for user.')),
              );
            }
          } else {
            // Handle case where user data doesn't exist in either node
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User data not found.')),
            );
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




  void _showAdminPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Admin Access"),
          content: Text("You are logged in as an Admin. Would you like to go to the Admin side or the Home page?"),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Admin()));
                  },
                  child: Text("Admin Side",style: GoogleFonts.lora(
                    color : Colors.black
                  ),),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FrontPage()));
                  },
                  child: Text("Home Page",style: GoogleFonts.lora(
                    color : Colors.black
                  ),),
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
              child: Row(
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
                          decoration: InputDecoration(
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
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
                      SizedBox(height: 30),
                      Card(
                        color: Colors.black,
                        child: InkWell(
                          onTap: isLoggingIn ? null : loginUser,
                          child: Container(
                            width: 200.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Center(
                              child: Text(
                                isLoggingIn ? "Logging in..." : "Login",
                                style: TextStyle(
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
                          Text("If not a registered member, click on"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return RegisterPage();
                              }));
                            },
                            child: Text("Register"),
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
