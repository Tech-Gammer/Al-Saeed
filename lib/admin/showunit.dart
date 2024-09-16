import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/admin/addunit.dart';
import 'package:myfirstmainproject/admin/admin.dart';

import '../components.dart';

class ShowUnit extends StatefulWidget {
  const ShowUnit({super.key});

  @override
  State<ShowUnit> createState() => _ShowUnitState();
}

class _ShowUnitState extends State<ShowUnit> {
  List<String> units = []; // List to store category names

  @override
  void initState() {
    super.initState();
    fetchUnits();
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
        });
      } else {
        setState(() {
          units = [];
        });
      }
    } catch (e) {
      print('Error fetching units: $e');
    }
  }

  Future<void> deleteUnit(String unitName) async {
    try {
      final unitRef = FirebaseDatabase.instance.ref("unit");

      // Find the key of the category to be deleted
      final snapshot = await unitRef.orderByChild("name").equalTo(unitName).once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final key = data.keys.first;

        // Remove the category from Firebase
        await unitRef.child(key).remove();

        // Update the state to remove the category locally
        setState(() {
          units.remove(unitName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unit deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting Unit")),
      );
    }
  }

  void showDeleteConfirmationDialog(String unitName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete the unit '$unitName'?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await deleteUnit(unitName);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Show Unit"),
      body: units.isEmpty
          ? Center(
        child: Text(
          'No units found.',
          style: GoogleFonts.lora(fontSize: 20),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: units.length,
        itemBuilder: (context, index) {
          String unit = units[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(unit, style: GoogleFonts.lora()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => showDeleteConfirmationDialog(unit),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddUnitDialog();
        },
        child: const Icon(Icons.add,color: Colors.white,),
        backgroundColor: const Color(0xFFE0A45E),
      ),
    );
  }

  void showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Addunit();
      },
    );
  }
}
