import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:myfirstmainproject/admin/addcategory.dart';
import '../components.dart';
import 'admin.dart';
import 'package:flutter/services.dart';

class AddItems extends StatefulWidget {
  const AddItems({super.key});

  @override
  State<AddItems> createState() => _AddItemsState();
}

class _AddItemsState extends State<AddItems> {
  String item_name = "";
  String description = "";
  String rate = "";
  String category = "";
  final dref = FirebaseDatabase.instance.ref("items");
  final dref1 = FirebaseDatabase.instance.ref("Image");
  final storref = FirebaseStorage.instance;
  final dc = TextEditingController();
  final nc = TextEditingController();
  final rc = TextEditingController();
  final catetoryController = TextEditingController();
  File? file;
  XFile? pickfile;
  bool isSaving = false;
  String? url;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final categoryRef = FirebaseDatabase.instance.ref("category");
      final snapshot = await categoryRef.once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> fetchedCategories = data.values.map((value) => value['name'].toString()).toList();
        setState(() {
          categories = fetchedCategories;
        });
      } else {
        setState(() {
          categories = [];
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> getImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (kIsWeb) {
          pickfile = image;
        } else {
          file = File(image.path);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No Image Selected")));
    }
  }

  Future<void> upload_Image() async {
    if (file != null || pickfile != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Uploading Image...")));
      final imageRef = storref.ref().child("Images/${DateTime.now().millisecondsSinceEpoch}.jpg");
      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await pickfile!.readAsBytes();
        uploadTask = imageRef.putData(bytes);
      } else {
        uploadTask = imageRef.putFile(file!);
      }

      await uploadTask.whenComplete(() async {
        url = await imageRef.getDownloadURL();
        dref1.child("img").set(url).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image uploaded successfully")));
        }).onError((error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
      });
    }
  }

  Future<void> checkForDuplicateAndSave() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final itemsRef = dref.child(uid);

    // Query the items under the current admin ID for duplicate names
    final snapshot = await itemsRef.orderByChild('item_name').equalTo(item_name).once();

    if (snapshot.snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item with this name already exists")),
      );
      setState(() {
        isSaving = false;
      });
    } else {
      await upload_Image();
      save();
    }
  }

  void save() async {
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading image. Please try again.")));
      setState(() {
        isSaving = false;
      });
      return;
    }

    String uid = FirebaseAuth.instance.currentUser!.uid; // Get the current user's UID
    String id = dref.child(uid).push().key.toString(); // Generate a new item ID

    // Convert rate to integer and handle any parsing errors
    int? rateInt;
    try {
      rateInt = int.tryParse(rate);
      if (rateInt == null) {
        throw FormatException("Invalid rate format");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid rate format")));
      setState(() {
        isSaving = false;
      });
      return;
    }

    dref.child(uid).child(id).set({
      'item_name': item_name,
      'description': description,
      'rate': rateInt.toString(), // Save rate as string
      'category': category,
      'image': url,
      'itemId': id,
      'adminId': uid,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data Saved Successfully")));

      // Clear the form
      setState(() {
        nc.clear();
        dc.clear();
        rc.clear();
        catetoryController.clear();
        file = null;
        pickfile = null;
        item_name = "";
        description = "";
        rate = "";
        isSaving = false;
        category = "";
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong")));
      setState(() {
        isSaving = false;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Register Items"),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundImage: file != null
                      ? FileImage(file!)
                      : pickfile != null
                      ? NetworkImage(pickfile!.path) as ImageProvider
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: file == null && pickfile == null
                      ? Icon(Icons.image, color: Colors.grey, size: 100)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey, size: 30),
                    onPressed: getImage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nc,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  filled: true,
                  labelText: "Name",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "Enter your Name",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: dc,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  filled: true,
                  labelText: "Description",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "Enter your Description",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: rc,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  filled: true,
                  labelText: "Rate",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "Enter your Rate",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: categories.isNotEmpty
                        ? DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Category",
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                      value: category.isEmpty ? null : category,
                      items: categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          category = newValue!;
                        });
                      },
                    )
                        : CustomLoader(),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddCategory()));
                    },
                    icon: const Icon(Icons.add, size: 40),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: InkWell(
                onTap: isSaving
                    ? null
                    : () async {
                  setState(() {
                    isSaving = true;
                  });
                  item_name = nc.text.toString();
                  description = dc.text.toString();
                  rate = rc.text.toString();
                  if (item_name.isEmpty || description.isEmpty || rate.isEmpty || category.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please Enter The Fields")));
                    setState(() {
                      isSaving = false;
                    });
                  } else {
                    await checkForDuplicateAndSave();
                  }
                },
                child: Container(
                  width: 200.0,
                  height: 50.0,
                  decoration: const BoxDecoration(color: Color(0xFFE0A45E), borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Center(
                    child: Text(
                      isSaving ? "Saving..." : "Save Data",
                      style: NewCustomTextStyles.newcustomTextStyle,
                    ),
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

class CustomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 8.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
