import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../components.dart';

class Addunit extends StatefulWidget {
  const Addunit({Key? key}) : super(key: key);

  @override
  State<Addunit> createState() => _AddunitState();
}

class _AddunitState extends State<Addunit> {
  final dref = FirebaseDatabase.instance.ref().child("unit");
  final unitController = TextEditingController();
  bool isSaving = false;
  String name = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Register UNIT"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: unitController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                filled: true,
                labelText: "Add Unit",
                labelStyle: TextStyle(fontSize: 15),
                hintText: "Enter Unit Name",
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

                name = unitController.text.trim();

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
                    isSaving ? "Saving..." : "Save Unit",
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
        const SnackBar(content: Text("Unit already exists")),
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
        unitController.clear();
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
