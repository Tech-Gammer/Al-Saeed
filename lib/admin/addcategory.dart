import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../components.dart';

class AddCategory extends StatefulWidget {
  const AddCategory({Key? key}) : super(key: key);

  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  final dref = FirebaseDatabase.instance.ref().child("category");
  final categoryController = TextEditingController();
  bool isSaving = false;
  String name = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Register Category"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                filled: true,
                labelText: "Add Category",
                labelStyle: TextStyle(fontSize: 15),
                hintText: "Enter Category Name",
              ),
            ),
          ),
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

                name = categoryController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please Enter The Fields")),
                  );
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE0A45E),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Center(
                  child: Text(
                    isSaving ? "Saving..." : "Save Category",
                    style: NewCustomTextStyles.newcustomTextStyle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkForDuplicateAndSave() async {
    final snapshot = await dref.orderByChild('name').equalTo(name).once();

    if (snapshot.snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category already exists")),
      );
      setState(() {
        isSaving = false;
      });
    } else {
      save();
    }
  }

  void save() async {
    String id = dref.push().key.toString();
    dref.child(id).set({
      'name': name,
      'id': id,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data Saved Successfully")),
      );

      // Clear the form
      setState(() {
        categoryController.clear();
        isSaving = false;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
      setState(() {
        isSaving = false;
      });
    });
  }
}
