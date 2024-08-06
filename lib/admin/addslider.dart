import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../components.dart';
import 'admin.dart';

class AddSlider extends StatefulWidget {
  const AddSlider({super.key});

  @override
  State<AddSlider> createState() => _AddSliderState();
}

class _AddSliderState extends State<AddSlider> {
  final dref = FirebaseDatabase.instance.ref("slider images");
  final storref = FirebaseStorage.instance;
  File? file;
  XFile? pickfile;
  bool isSaving = false;
  String? url;

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

  Future<void> uploadImage() async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image uploaded successfully")));
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
      });
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
    String id = dref.push().key.toString();
    dref.child(id).set({
      'image': url,
      'key': id,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data Saved Successfully")));
      setState(() {
        file = null;
        pickfile = null;
        isSaving = false;
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
      appBar: CustomAppBar.customAppBar("Add Slider Images"),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                (file != null || pickfile != null)
                    ? CircleAvatar(
                  radius: 100,
                  backgroundImage: kIsWeb ? NetworkImage(pickfile!.path) : FileImage(file!) as ImageProvider,
                )
                    : CircleAvatar(
                  radius: 170,
                  backgroundColor: Colors.grey[300], // Placeholder color
                  child: Text(
                    "No Image",
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 15,
                  child: GestureDetector(
                    onTap: getImage,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.camera_alt,
                        color: Color(0xFFE0A45E),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30,),
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

                  await uploadImage();
                  if (url != null) {
                    save();
                  } else {
                    setState(() {
                      isSaving = false;
                    });
                  }
                },
                child: Container(
                  width: 200.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Color(0xFFE0A45E),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                      isSaving ? "Saving..." : "Save Image",
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


