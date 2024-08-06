import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/addslider.dart';

import '../components.dart';
import 'admin.dart';

class SliderImages extends StatefulWidget {
  const SliderImages({super.key});

  @override
  State<SliderImages> createState() => _SliderImagesState();
}

class _SliderImagesState extends State<SliderImages> {
  final DatabaseReference dref = FirebaseDatabase.instance.ref("slider images");
  final FirebaseStorage storref = FirebaseStorage.instance;
  List<Map<String, dynamic>> images = [];
  String? deletingKey;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final snapshot = await dref.once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      setState(() {
        images = data.entries.map((e) => {
          'key': e.key,
          'image': e.value['image'],
        }).toList();
      });
    }
  }

  Future<void> deleteImage(String key, String url) async {
    setState(() {
      deletingKey = key;
    });

    try {
      // Delete the image from Firebase Storage
      final imageRef = storref.refFromURL(url);
      await imageRef.delete();

      // Delete the image reference from Firebase Realtime Database
      await dref.child(key).remove().then((value) {
        setState(() {
          images.removeWhere((image) => image['key'] == key);
          deletingKey = null;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image deleted successfully")));
        });
      });
    } catch (error) {
      setState(() {
        deletingKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting image: $error")));
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          color: Colors.black,
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Show Slider Images"),
      body: images.isEmpty
          ? Center(
          child: Text(
            "No Image Found",
            style: GoogleFonts.lora(),
          )
      )
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          final isDeleting = deletingKey == image['key'];
          return GridTile(
            child: GestureDetector(
              onTap: () => _showImagePreview(image['image']),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      image['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isDeleting)
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteImage(image['key'], image['image']);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=>AddSlider()));
        },
        child: Icon(Icons.add,color: Colors.white),
        backgroundColor: Color(0xFFE0A45E),
      ),
    );
  }
}
