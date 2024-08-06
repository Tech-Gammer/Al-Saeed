import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfirstmainproject/admin/additems.dart';
import 'package:myfirstmainproject/admin/admin.dart';

import '../components.dart';

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final DatabaseReference itemsRef = FirebaseDatabase.instance.ref("items");
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker picker = ImagePicker();
  List<String> categories = [];
  String? selectedCategory;
  TextEditingController categoryController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    String adminId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await itemsRef.child(adminId).get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> items = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> itemList = items.values.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
      return itemList;
    } else {
      return [];
    }
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
          if (categories.isNotEmpty) selectedCategory = categories.first;
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

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String adminId = FirebaseAuth.instance.currentUser!.uid;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = storage.ref().child('images/$adminId/$fileName');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _showItemDetailsDialog(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(text: item['item_name'] ?? '');
    final TextEditingController priceController = TextEditingController(text: (item['rate'] ?? 0.0).toString());
    final TextEditingController descriptionController = TextEditingController(text: item['description'] ?? '');
    String currentCategory = item['category'] ?? '';
    String? imageUrl = item['image'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text("Item Details"),
              Spacer(),
              IconButton(onPressed: (){
                Navigator.pop(context);
              }, icon: Icon(Icons.close))
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: item['image'] != null
                              ? NetworkImage(item['image'])
                              : null,
                        backgroundColor: Colors.grey[200],
                        child: _imageFile == null && imageUrl == null
                            ? Icon(Icons.image, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
              ),
                SizedBox(height: 20),
                _buildTextField(nameController, "Item Name"),
                _buildTextField(priceController, "Price", keyboardType: TextInputType.number),
                _buildCategoryDropdown(currentCategory),
                _buildTextField(descriptionController, "Description", maxLines: 3),
              ],
            ),
          ),
          actions: [
            Center(
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFE0A45E),
                  borderRadius: BorderRadius.all(Radius.circular(20))
                ),
                child: TextButton(
                  onPressed: () async {
                    final itemId = item['itemId'] as String? ?? '';
                    final newPrice = double.tryParse(priceController.text) ?? 0.0;

                    if (itemId.isNotEmpty) {
                      String? newImageUrl;
                      if (_imageFile != null) {
                        newImageUrl = await _uploadImage(_imageFile!);
                      } else {
                        newImageUrl = imageUrl; // Keep the old image URL if no new image is selected
                      }

                      await _updateItem(itemId, {
                        'item_name': nameController.text,
                        'rate': newPrice,
                        'category': selectedCategory ?? currentCategory,
                        'description': descriptionController.text,
                        'image': newImageUrl,
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ItemsPage()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid item ID")));
                    }
                  },
                  child: Text("Update Item",style: NewCustomTextStyles.newcustomTextStyle),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateItem(String itemId, Map<String, dynamic> updatedData) async {
    try {
      String adminId = FirebaseAuth.instance.currentUser!.uid;
      final itemRef = itemsRef.child(adminId).child(itemId);

      print("Updating item at path: ${itemRef.path}");
      print("Update data: $updatedData");

      await itemRef.update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item updated successfully")));
    } catch (e) {
      print('Error updating item: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating item")));
    }
  }

  Future<void> _deleteItem(String itemId, String? imageUrl) async {
    try {
      String adminId = FirebaseAuth.instance.currentUser!.uid;

      // Delete the item from the database
      final itemRef = itemsRef.child(adminId).child(itemId);
      await itemRef.remove();

      // Delete the image from storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await imageRef.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item deleted successfully")));
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting item")));
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey,
                width: 5
              )
            )
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildCategoryDropdown(String currentCategory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedCategory ?? currentCategory,
        decoration: InputDecoration(
            labelText: "Category",
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.grey,
                    width: 5
                )
            )
        ),
        items: categories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            selectedCategory = newValue!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar.customAppBar("Items List"),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No items found"));
          } else {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 5,
                  shadowColor: Colors.blue,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: item['image'] != null
                          ? NetworkImage(item['image'])
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: item['image'] == null ? Icon(Icons.image, color: Colors.grey) : null,
                    ),
                    title: Text("Name: ${item['item_name']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Description: ${item['description']}"),
                        SizedBox(height: 4),
                        Text("Rate: ${item['rate']}"),
                        SizedBox(height: 4),
                        Text("Category: ${item['category']}"),
                      ],
                    ),
                    onTap: () => _showItemDetailsDialog(item),
                    trailing: IconButton(
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Confirm Deletion"),
                              content: Text("Are you sure you want to delete this item?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("DELETE"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text("CANCEL"),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm) {
                          final itemId = item['itemId'] as String? ?? '';
                          if (itemId.isNotEmpty) {
                            await _deleteItem(itemId, item['image']);
                            setState(() {}); // Refresh the list
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid item ID")));
                          }
                        }
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 25,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
        floatingActionButton:  FloatingActionButton(
            child: Icon(Icons.add,color: Colors.white,),
            backgroundColor: Color(0xFFE0A45E),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddItems()));
            }
        )
    );
  }
}
