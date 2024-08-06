import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components.dart';
import 'admin.dart';

class SuperAdminPanel extends StatefulWidget {
  @override
  _SuperAdminPanelState createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  final DatabaseReference _itemsRef = FirebaseDatabase.instance.ref("items");
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _items = [];
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      // Fetch users from the users node
      final usersSnapshot = await _userRef.once();
      if (usersSnapshot.snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(usersSnapshot.snapshot.value as Map);

        _users.addAll(usersData.values.map((user) {
          final map = Map<String, dynamic>.from(user);
          return {
            'uid': map['uid'] ?? '',
            'name': map['name'] ?? 'Unknown',
            'role': map['role'] ?? '1', // Default to '1' if null
          };
        }).toList());
      }

      // Fetch admins from the admin node
      final adminsSnapshot = await _adminRef.once();
      if (adminsSnapshot.snapshot.value != null) {
        final adminsData = Map<String, dynamic>.from(adminsSnapshot.snapshot.value as Map);

        _users.addAll(adminsData.values.map((user) {
          final map = Map<String, dynamic>.from(user);
          return {
            'uid': map['adminId'] ?? '',
            'name': map['name'] ?? 'Unknown',
            'role': '0', // Admin role
          };
        }).toList());
      }

      // Map user UIDs to names
      setState(() {
        _userNames = Map.fromEntries(
            _users.map((user) => MapEntry(user['uid'], user['name'] ?? 'Unknown'))
        );
        fetchItems(); // Fetch items after users are fetched
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> fetchItems() async {
    try {
      List<Map<String, dynamic>> allItems = [];

      for (final user in _users) {
        final uid = user['uid'];
        final itemsSnapshot = await _itemsRef.child(uid).once();
        if (itemsSnapshot.snapshot.value != null) {
          final itemsData = Map<String, dynamic>.from(itemsSnapshot.snapshot.value as Map);
          final userItems = itemsData.values.map((item) {
            final map = Map<String, dynamic>.from(item);
            return {
              'uid': uid,
              'userName': _userNames[uid] ?? 'Unknown User',
              'item_name': map['item_name'] ?? 'Unnamed Item',
              'description': map['description'] ?? 'No Description',
              'rate': map['rate']?.toString() ?? '0.0',
              'category': map['category'] ?? 'Uncategorized',
              'image': map['image'] ?? '',
            };
          }).toList();
          allItems.addAll(userItems);
        }
      }

      setState(() {
        _items = allItems;
      });
    } catch (e) {
      print('Error fetching items: $e');
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      // Fetch the user's data from the appropriate node
      DataSnapshot userSnapshot = await _userRef.child(uid).get();
      DataSnapshot adminSnapshot = await _adminRef.child(uid).get();
      Map<String, dynamic>? userData;

      if (userSnapshot.exists) {
        userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      } else if (adminSnapshot.exists) {
        userData = Map<String, dynamic>.from(adminSnapshot.value as Map);
      }

      if (userData != null) {
        if (role == '0') { // Move to admin node
          await _adminRef.child(uid).set({
            'adminId': uid,
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'password': userData['password'] ?? '',
            'role': role,
          });
          await _userRef.child(uid).remove();
        } else { // Move to users node
          await _userRef.child(uid).set({
            'uid': uid,
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'password': userData['password'] ?? '',
            'role': role,
          });
          await _adminRef.child(uid).remove();
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User role updated successfully")));
        fetchUsers(); // Refresh the users list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not found")));
      }
    } catch (e) {
      print('Error updating user role: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating user role")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Admin Panel"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Users List
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Users",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['name'] ?? 'Unknown User'),
                  subtitle: Text("Role: ${user['role'] == '0' ? 'Admin' : 'Buyer'}"),
                  trailing: DropdownButton<String>(
                    value: user['role'],
                    items: [
                      DropdownMenuItem(value: '0', child: Text('Admin')),
                      DropdownMenuItem(value: '1', child: Text('Buyer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        updateUserRole(user['uid'], value);
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
