import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/addcategory.dart';
import 'package:myfirstmainproject/admin/admin.dart';

import '../components.dart';

class ShowCategory extends StatefulWidget {
  const ShowCategory({super.key});

  @override
  State<ShowCategory> createState() => _ShowCategoryState();
}

class _ShowCategoryState extends State<ShowCategory> {
  List<String> categories = []; // List to store category names

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

  Future<void> deleteCategory(String categoryName) async {
    try {
      final categoryRef = FirebaseDatabase.instance.ref("category");

      // Find the key of the category to be deleted
      final snapshot = await categoryRef.orderByChild("name").equalTo(categoryName).once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final key = data.keys.first;

        // Remove the category from Firebase
        await categoryRef.child(key).remove();

        // Update the state to remove the category locally
        setState(() {
          categories.remove(categoryName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Category deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting category")),
      );
    }
  }

  void showDeleteConfirmationDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete the category '$categoryName'?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await deleteCategory(categoryName);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Show Category"),
      body: categories.isEmpty
          ? Center(
        child: Text(
          'No categories found.',
          style: GoogleFonts.lora(fontSize: 20),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          String category = categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(category, style: GoogleFonts.lora()),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => showDeleteConfirmationDialog(category),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddCategoryDialog();
        },
        child: const Icon(Icons.add,color: Colors.white,),
        backgroundColor: Color(0xFFE0A45E),
      ),
    );
  }

  void showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCategory();
      },
    );
  }
}
