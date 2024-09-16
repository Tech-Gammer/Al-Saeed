import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfirstmainproject/admin/additems.dart';

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
  List<String> units = [];

  List<Map<dynamic, dynamic>> _items = [];
  String? selectedCategory;
  String? selectedUnit;

  TextEditingController categoryController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchUnits();
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final snapshot = await itemsRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> items = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> itemList = items.values.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
      return itemList;
    }
    else {
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
      // print('Error fetching categories: $e');
    }
  }

  Future<void> fetchUnits() async {
    try {
      final unitRef = FirebaseDatabase.instance.ref("unit");
      final snapshot = await unitRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> fetchedUnits = data.values.map((value) => value['name'].toString()).toList();

        setState(() {
          units = fetchedUnits;
          if (units.isNotEmpty) selectedUnit = units.first;
        });
      } else {
        setState(() {
          units = [];
        });
      }
    } catch (e) {
      // print('Error fetching categories: $e');
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

  Future<String?> _uploadImage(File imageFile, String? existingImageUrl) async {
    try {
      String fileName;

      // Use the existing image file name if it exists
      if (existingImageUrl != null) {
        Uri uri = Uri.parse(existingImageUrl);
        fileName = uri.pathSegments.last;
      } else {
        // Otherwise, create a new file name
        fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      Reference storageRef = storage.ref().child('$fileName');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      // print('Error uploading image: $e');
      return null;
    }
  }

  // void _showItemDetailsDialog(Map<String, dynamic> item)  {
  //   final TextEditingController nameController = TextEditingController(text: item['item_name'] ?? '');
  //   final TextEditingController netController = TextEditingController(text: (item['net_rate'] ?? 0.0).toString());
  //   final TextEditingController descriptionController = TextEditingController(text: item['description'] ?? '');
  //   final TextEditingController purchasseController = TextEditingController(text: item['purchase_rate'] ?? '');
  //   final TextEditingController saleController = TextEditingController(text: item['sale_rate'] ?? '');
  //   final TextEditingController taxController = TextEditingController(text: item['tax'] ?? '');
  //   final TextEditingController barcodeController = TextEditingController(text: item['barcode'] ?? '');
  //   final TextEditingController ptcController = TextEditingController(text: item['ptc_code'] ?? '');
  //   final TextEditingController item_qtyController = TextEditingController(text: item['item_qty'] ?? '');
  //
  //
  //   String currentCategory = item['category'] ?? '';
  //   String currentUnit = item['unit'] ?? '';
  //
  //   String? imageUrl = item['image'];
  //
  //   double saleRate = double.tryParse(item['sale_rate'] ?? '0.0') ?? 0.0;
  //   double tax = double.tryParse(item['tax'] ?? '0.0') ?? 0.0;
  //   double netRate = saleRate * (1 + tax / 100);
  //
  //   void _updateNetRate() {
  //     final saleRate = double.tryParse(saleController.text) ?? 0.0;
  //     final tax = double.tryParse(taxController.text) ?? 0.0;
  //     final netRate = saleRate * (1 + tax / 100);
  //     netController.text = netRate.toStringAsFixed(0);
  //   }
  //
  //   saleController.addListener(_updateNetRate);
  //   taxController.addListener(_updateNetRate);
  //
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Row(
  //           children: [
  //             const Text("Item Details"),
  //             const Spacer(),
  //             IconButton(onPressed: (){
  //               Navigator.pop(context);
  //             }, icon: const Icon(Icons.close))
  //           ],
  //         ),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Center(
  //                 child: Stack(
  //                   clipBehavior: Clip.none,
  //                   children: [
  //                     CircleAvatar(
  //                       radius: 70,
  //                       backgroundImage: item['image'] != null
  //                             ? NetworkImage(item['image'])
  //                             : null,
  //                       backgroundColor: Colors.grey[200],
  //                       child: _imageFile == null && imageUrl == null
  //                           ? const Icon(Icons.image, color: Colors.grey)
  //                           : null,
  //                     ),
  //                     Positioned(
  //                       bottom: -5,
  //                       right: -5,
  //                       child: IconButton(
  //                         icon: const Icon(Icons.camera_alt, color: Colors.blue, size: 30),
  //                         onPressed: _pickImage,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //             ),
  //               const SizedBox(height: 20),
  //               _buildTextField(nameController, "Item Name"),
  //               TextField(
  //                 controller: TextEditingController(text: netRate.toStringAsFixed(0)),
  //                 decoration: InputDecoration(
  //                   labelText: "Net Rate",
  //                   border: const OutlineInputBorder(
  //                     borderSide: BorderSide(color: Colors.grey, width: 5),
  //                   ),
  //                 ),
  //                 keyboardType: TextInputType.number,
  //                 readOnly: true, // Make net rate field read-only
  //               ),
  //               // _buildTextField(netController, "Net Rate", keyboardType: TextInputType.number),
  //               _buildTextField(purchasseController, "Purchase Rate", keyboardType: TextInputType.number),
  //               _buildTextField(saleController, "Sale Rate", keyboardType: TextInputType.number),
  //               _buildTextField(taxController, "Tax", keyboardType: TextInputType.number),
  //               _buildTextField(barcodeController, "Barcode", keyboardType: TextInputType.number),
  //               _buildTextField(ptcController, "PCT CODE", keyboardType: TextInputType.number),
  //               _buildTextField(item_qtyController, "Item Quantity", keyboardType: TextInputType.number),
  //
  //               _buildCategoryDropdown(currentCategory),
  //               _buildUnitDropdown(currentUnit),
  //               _buildTextField(descriptionController, "Description", maxLines: 3),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           Center(
  //             child: Container(
  //               width: 200,
  //               height: 50,
  //               decoration: const BoxDecoration(
  //                 color: Color(0xFFE0A45E),
  //                 borderRadius: BorderRadius.all(Radius.circular(20))
  //               ),
  //               child: TextButton(
  //                 onPressed: () async {
  //                   final itemId = item['itemId'] as String? ?? '';
  //                   final newPrice = double.tryParse(netController.text) ?? 0.0;
  //
  //                   if (itemId.isNotEmpty) {
  //                     String? newImageUrl;
  //                     if (_imageFile != null) {
  //                       newImageUrl = await _uploadImage(_imageFile!, imageUrl);
  //                     } else {
  //                       newImageUrl = imageUrl; // Keep the old image URL if no new image is selected
  //                     }
  //
  //                     // await _updateItem(itemId, {
  //                     //   'item_name': nameController.text,
  //                     //   'net_rate': newPrice,
  //                     //   'category': selectedCategory ?? currentCategory,
  //                     //   'unit': selectedUnit ?? currentUnit,
  //                     //   'description': descriptionController.text,
  //                     //   'image': newImageUrl,
  //                     //   'sale_rate': saleController,
  //                     //   'purchase-rate': purchasseController,
  //                     //   'tax': taxController,
  //                     //   'barcode': barcodeController,
  //                     //
  //                     // });
  //                     await _updateItem(itemId, {
  //                       'item_name': nameController.text,
  //                       'net_rate': newPrice,
  //                       'category': selectedCategory ?? currentCategory,
  //                       'unit': selectedUnit ?? currentUnit,
  //                       'description': descriptionController.text,
  //                       'image': newImageUrl,
  //                       'sale_rate': saleController.text,
  //                       'purchase_rate': purchasseController.text,
  //                       'tax': taxController.text,
  //                       'barcode': barcodeController.text,
  //                       'ptc_code': ptcController.text,
  //                       'item_qty': item_qtyController.text
  //                     });
  //
  //                     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ItemsPage()));
  //                   } else {
  //                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid item ID")));
  //                   }
  //                 },
  //
  //                 child: const Text("Update Item",style: NewCustomTextStyles.newcustomTextStyle),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }


  void _showItemDetailsDialog(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(text: item['item_name'] ?? '');
    final TextEditingController netController = TextEditingController(text: (item['net_rate'] ?? 0.0).toString());
    final TextEditingController descriptionController = TextEditingController(text: item['description'] ?? '');
    final TextEditingController purchaseController = TextEditingController(text: item['purchase_rate'] ?? '');
    final TextEditingController saleController = TextEditingController(text: item['sale_rate'] ?? '');
    final TextEditingController taxController = TextEditingController(text: item['tax'] ?? '');
    final TextEditingController barcodeController = TextEditingController(text: item['barcode'] ?? '');
    final TextEditingController ptcController = TextEditingController(text: item['ptc_code'] ?? '');
    final TextEditingController itemQtyController = TextEditingController(text: item['item_qty'] ?? '');

    // Initialize with current category and unit from item
    String currentCategory = item['category'] ?? categories.first;
    String currentUnit = item['unit'] ?? units.first;

    String? imageUrl = item['image'];

    double saleRate = double.tryParse(item['sale_rate'] ?? '0.0') ?? 0.0;
    double tax = double.tryParse(item['tax'] ?? '0.0') ?? 0.0;
    double netRate = saleRate * (1 + tax / 100);

    void _updateNetRate() {
      final saleRate = double.tryParse(saleController.text) ?? 0.0;
      final tax = double.tryParse(taxController.text) ?? 0.0;
      final netRate = saleRate * (1 + tax / 100);
      netController.text = netRate.toStringAsFixed(0);
    }

    saleController.addListener(_updateNetRate);
    taxController.addListener(_updateNetRate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text("Item Details"),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
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
                        backgroundImage: item['image'] != null ? NetworkImage(item['image']) : null,
                        backgroundColor: Colors.grey[200],
                        child: _imageFile == null && imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(nameController, "Item Name"),
                TextField(
                  controller: TextEditingController(text: netRate.toStringAsFixed(0)),
                  decoration: const InputDecoration(
                    labelText: "Net Rate",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 5),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: true, // Make net rate field read-only
                ),
                _buildTextField(purchaseController, "Purchase Rate", keyboardType: TextInputType.number),
                _buildTextField(saleController, "Sale Rate", keyboardType: TextInputType.number),
                _buildTextField(taxController, "Tax", keyboardType: TextInputType.number),
                _buildTextField(barcodeController, "Barcode", keyboardType: TextInputType.number),
                _buildTextField(ptcController, "PCT CODE", keyboardType: TextInputType.number),
                _buildTextField(itemQtyController, "Item Quantity", keyboardType: TextInputType.number),

                // Dropdown for selecting category, initialized with currentCategory
                _buildCategoryDropdown(currentCategory),

                // Dropdown for selecting unit, initialized with currentUnit
                _buildUnitDropdown(currentUnit),

                _buildTextField(descriptionController, "Description", maxLines: 3),
              ],
            ),
          ),
          actions: [
            Center(
              child: Container(
                width: 200,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0A45E),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: TextButton(
                  onPressed: () async {
                    final itemId = item['itemId'] as String? ?? '';
                    final newPrice = double.tryParse(netController.text) ?? 0.0;

                    if (itemId.isNotEmpty) {
                      String? newImageUrl;
                      if (_imageFile != null) {
                        newImageUrl = await _uploadImage(_imageFile!, imageUrl);
                      } else {
                        newImageUrl = imageUrl; // Keep the old image URL if no new image is selected
                      }

                      await _updateItem(itemId, {
                        'item_name': nameController.text,
                        'net_rate': newPrice,
                        'category': selectedCategory ?? currentCategory,
                        'unit': selectedUnit ?? currentUnit,
                        'description': descriptionController.text,
                        'image': newImageUrl,
                        'sale_rate': saleController.text,
                        'purchase_rate': purchaseController.text,
                        'tax': taxController.text,
                        'barcode': barcodeController.text,
                        'ptc_code': ptcController.text,
                        'item_qty': itemQtyController.text,
                      });

                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ItemsPage()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid item ID")));
                    }
                  },
                  child: const Text("Update Item", style: NewCustomTextStyles.newcustomTextStyle),
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
      final itemRef = itemsRef.child(itemId);

      await itemRef.update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item updated successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating item")));
    }
  }


  Future<void> deleteItem(String itemId, String imageUrl) async {
    try {
      await itemsRef.child(itemId).remove();
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item and image deleted successfully")),
      );
      setState(() {
        _items.removeWhere((item) => item['itemId'] == itemId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting item: $e")),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(
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
        decoration: const InputDecoration(
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

  Widget _buildUnitDropdown(String currentUnit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedUnit ?? currentUnit,
        decoration: const InputDecoration(
            labelText: "Unit",
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.grey,
                    width: 5
                )
            )
        ),
        items: units.map((unit) {
          return DropdownMenuItem<String>(
            value: unit,
            child: Text(unit),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            selectedUnit = newValue!;
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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No items found"));
          } else {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 5,
                  shadowColor: Colors.blue,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: item['image'] != null
                          ? NetworkImage(item['image'])
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: item['image'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                    ),
                    title: Text("Name: ${item['item_name']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Description: ${item['description']}"),
                        const SizedBox(height: 4),
                        Text("Rate: ${item['net_rate']}"),
                        const SizedBox(height: 4),
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
                              title: const Text("Confirm Deletion"),
                              content: const Text("Are you sure you want to delete this item?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("DELETE"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("CANCEL"),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm) {
                          final itemId = item['itemId'] as String? ?? '';
                          if (itemId.isNotEmpty) {
                            await deleteItem(itemId, item['image']);
                            setState(() {}); // Refresh the list
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid item ID")));
                          }
                        }
                      },
                      icon: const Icon(
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
            child: const Icon(Icons.add,color: Colors.white,),
            backgroundColor: const Color(0xFFE0A45E),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const AddItems()));
            }
        )
    );
  }
}
