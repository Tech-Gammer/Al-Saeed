import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'components.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool obscurePassword = true;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isDeletingImage = false;
  String? _role;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _profileImageUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (currentUser != null) {
      try {
        // Check in the admin node first
        final adminSnapshot = await FirebaseDatabase.instance.ref("admin").child(currentUser!.uid).once();
        if (adminSnapshot.snapshot.value != null) {
          final data = Map<String, dynamic>.from(adminSnapshot.snapshot.value as Map);
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _passwordController.text = data['password'] ?? '';
            _addressController.text = data['address'] ?? '';
            _zipCodeController.text = data['zip_code'] ?? '';
            _profileImageUrl = data['profileImage'];
            _role = 'Admin';
          });
        } else {
          // Check in the users node
          final userSnapshot = await _userRef.child(currentUser!.uid).once();
          if (userSnapshot.snapshot.value != null) {
            final data = Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
            setState(() {
              _nameController.text = data['name'] ?? '';
              _emailController.text = data['email'] ?? '';
              _phoneController.text = data['phone'] ?? '';
              _passwordController.text = data['password'] ?? '';
              _addressController.text = data['address'] ?? '';
              _zipCodeController.text = data['zip_code'] ?? '';
              _profileImageUrl = data['profileImage'];
              _role = 'Buyer';
            });
          } else {
            print("No user data found");
          }
        }
      } catch (e) {
        print('Error fetching user data: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);

        if (result != null && result.files.isNotEmpty) {
          final pickedFile = result.files.first;

          setState(() {
            _imageBytes = pickedFile.bytes; // Use pickedFile.bytes for web
          });

          _uploadImage(bytes: _imageBytes, fileName: pickedFile.name);
        } else {
          print("No image selected");
        }
      } else {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final file = File(pickedFile.path!);

          setState(() {
            _imageBytes = file.readAsBytesSync(); // Convert File to Uint8List
          });

          _uploadImage(bytes: _imageBytes, fileName: '${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        } else {
          print("No image selected");
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadImage({Uint8List? bytes, required String fileName}) async {
    if (bytes != null) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final storageRef = _storage.ref().child('profile_images').child(fileName);
        final uploadTask = storageRef.putData(bytes); // Use putData for Uint8List
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        final ref = _role == 'Admin'
            ? FirebaseDatabase.instance.ref("admin").child(currentUser!.uid)
            : _userRef.child(currentUser!.uid);

        await ref.update({'profileImage': downloadUrl});
        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image uploaded successfully")));
      } catch (e) {
        print('Error uploading image: $e');
      } finally {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _deleteImage() async {
    if (_profileImageUrl != null) {
      setState(() {
        _isDeletingImage = true;
      });

      try {
        final imageRef = _storage.refFromURL(_profileImageUrl!);
        await imageRef.delete();

        final ref = _role == 'Admin'
            ? FirebaseDatabase.instance.ref("admin").child(currentUser!.uid)
            : _userRef.child(currentUser!.uid);

        await ref.update({'profileImage': null});
        setState(() {
          _profileImageUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image deleted successfully")));
      } catch (e) {
        print('Error deleting image: $e');
      } finally {
        setState(() {
          _isDeletingImage = false;
        });
      }
    }
  }

  Future<void> updateUserData() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser != null) {
        try {
          final ref = _role == 'Admin'
              ? FirebaseDatabase.instance.ref("admin").child(currentUser!.uid)
              : _userRef.child(currentUser!.uid);

          final snapshot = await ref.once();
          final currentData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

          bool hasChanges = false;
          Map<String, dynamic> updates = {};

          if (_nameController.text != currentData['name']) {
            updates['name'] = _nameController.text;
            hasChanges = true;
          }
          if (_emailController.text != currentData['email']) {
            updates['email'] = _emailController.text;
            hasChanges = true;
          }
          if (_phoneController.text != currentData['phone']) {
            updates['phone'] = _phoneController.text;
            hasChanges = true;
          }
          if (_passwordController.text != currentData['password']) {
            updates['password'] = _passwordController.text;
            hasChanges = true;
          }
          if (_addressController.text != currentData['address']) {
            updates['address'] = _addressController.text;
            hasChanges = true;
          }
          if (_zipCodeController.text != currentData['zip_code']) {
            updates['zip_code'] = _zipCodeController.text;
            hasChanges = true;
          }

          if (hasChanges) {
            await ref.update(updates);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully")));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No changes detected")));
          }
        } catch (e) {
          print('Error updating user data: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("User Profile"),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : AssetImage('assets/placeholder.png') as ImageProvider,
                        child: _imageBytes == null && _profileImageUrl == null
                            ? Icon(Icons.camera_alt, color: Colors.white, size: 30)
                            : null,
                      ),
                      if (_isUploadingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircularProgressIndicator(),
                        ),
                      if (_profileImageUrl != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: _deleteImage,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text("Role: $_role", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    enabled: false,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  enabled: false, // Make password read-only
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _zipCodeController,
                  decoration: InputDecoration(
                    labelText: 'Zip Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your zip code';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Card(
                  color: Color(0xFFe6b67e),
                  child: InkWell(
                    onTap: updateUserData,
                    child: Container(
                      width: 200.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFe6b67e),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Center(
                        child: Text(
                          "Update Profile",
                          style: NewCustomTextStyles.newcustomTextStyle
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
