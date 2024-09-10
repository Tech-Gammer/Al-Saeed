import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'components.dart';
import 'package:geocoding/geocoding.dart';


class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _riderRef = FirebaseDatabase.instance.ref("riders");
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
  GoogleMapController? _controller;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _profileImageUrl;
  Uint8List? _imageBytes;
  LatLng _currentPosition =  const LatLng(31.5925, 74.3095);

  @override
  void initState() {
    super.initState();
    fetchUserData();
    setState(() {
      _addressController.text = _currentPosition.toString();

    });
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
            // Check in the riders node
            final riderSnapshot = await _riderRef.child(currentUser!.uid).once();
            if (riderSnapshot.snapshot.value != null) {
              final data = Map<String, dynamic>.from(riderSnapshot.snapshot.value as Map);
              setState(() {
                _nameController.text = data['name'] ?? '';
                _emailController.text = data['email'] ?? '';
                _phoneController.text = data['phone'] ?? '';
                _passwordController.text = data['password'] ?? '';
                _addressController.text = data['address'] ?? '';
                _zipCodeController.text = data['zip_code'] ?? '';
                _profileImageUrl = data['profileImage'];
                _role = 'Rider';
              });
            } else {
              print("No user data found");
            }
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
            : _role == 'Rider'
            ? _riderRef.child(currentUser!.uid)
            : _userRef.child(currentUser!.uid);

        await ref.update({'profileImage': downloadUrl});
        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image uploaded successfully")));
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
            : _role == 'Rider'
            ? _riderRef.child(currentUser!.uid)
            : _userRef.child(currentUser!.uid);

        await ref.update({'profileImage': null});
        setState(() {
          _profileImageUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image deleted successfully")));
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
              : _role == 'Rider'
              ? _riderRef.child(currentUser!.uid)
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
            updates['latitude'] = _currentPosition.latitude; // Save latitude
            updates['longitude'] = _currentPosition.longitude; // Save longitude
            hasChanges = true;
          }
          if (_zipCodeController.text != currentData['zip_code']) {
            updates['zip_code'] = _zipCodeController.text;
            hasChanges = true;
          }

          if (hasChanges) {
            await ref.update(updates);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No changes to update")));
          }
        } catch (e) {
          print('Error updating user data: $e');
        }
      }
    }
  }


  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }


  Future<void> _getUserLocation() async {
    Position position = await _determinePosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude,
          _currentPosition.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String fullAddress = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';

        setState(() {
          _addressController.text = fullAddress;
          // _zipCodeController.text = place.postalCode ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location fetched successfully")),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch address")),
      );
    }

    _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
  }

  Future<void> _mapDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            scrollable: true,
            content: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.hardEdge,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 5, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    height: 400,
                    width: 800,
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _controller = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition,
                        zoom: 14.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("currentLocation"),
                          position: _currentPosition,
                        ),
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _getUserLocation();

                          setState(() {
                            _controller?.animateCamera(
                              CameraUpdate.newLatLng(_currentPosition),
                            );
                          });
                          await Future.delayed(const Duration(seconds: 3));

                          Navigator.pop(context);
                        },
                        child: const Text('Select Current Location'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("User Profile"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
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
                            : const AssetImage('images/no_image.png') as ImageProvider,
                        child: _imageBytes == null && _profileImageUrl == null
                            ? const Icon(Icons.camera_alt, color: Colors.white, size: 30)
                            : null,
                      ),
                      if (_isUploadingImage)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircularProgressIndicator(),
                        ),
                      if (_profileImageUrl != null && _isDeletingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _deleteImage,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text("Role: $_role", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
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
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
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
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Regex for validating Pakistani phone numbers
                    final regex = RegExp(r'^\+92[0-9]{10}$|^03[0-9]{9}$');
                    if (!regex.hasMatch(value)) {
                      return 'Please enter a valid Pakistani phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
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
                const SizedBox(height: 10),
                TextFormField(
                  // readOnly: true,
                   controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton( onPressed: () {
                      _mapDialog();
                    }, icon: const Icon(Icons.location_history),)
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(
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
                const SizedBox(height: 20),
                Card(
                  color: const Color(0xFFe6b67e),
                  child: InkWell(
                    onTap: updateUserData,
                    child: Container(
                      width: 200.0,
                      height: 50.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFe6b67e),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: const Center(
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
