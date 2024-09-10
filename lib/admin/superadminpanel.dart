import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../components.dart';

class SuperAdminPanel extends StatefulWidget {
  @override
  _SuperAdminPanelState createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  final DatabaseReference _itemsRef = FirebaseDatabase.instance.ref("items");
  final DatabaseReference _ridersRef = FirebaseDatabase.instance.ref("riders");

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _items = [];
  Map<String, String> _userNames = {};
  int _nextRiderNumber = 1;
  int _nextAdminNumber = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersSnapshot = await _userRef.once();
      if (usersSnapshot.snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(usersSnapshot.snapshot.value as Map);

        _users = usersData.values.map((user) {
          final map = Map<String, dynamic>.from(user);
          return {
            'uid': map['uid'] ?? '',
            'name': map['name'] ?? 'Unknown',
            'email': map['email'] ?? 'No Email',
            'role': map['role'] ?? '1',
          };
        }).toList();
      }

      final adminsSnapshot = await _adminRef.once();
      if (adminsSnapshot.snapshot.value != null) {
        final adminsData = Map<String, dynamic>.from(adminsSnapshot.snapshot.value as Map);

        _users.addAll(adminsData.values.map((user) {
          final map = Map<String, dynamic>.from(user);
          return {
            'uid': map['adminId'] ?? '',
            'name': map['name'] ?? 'Unknown',
            'email': map['email'] ?? 'No Email',
            'role': '0',
          };
        }).toList());

        _nextAdminNumber = adminsData.values.fold<int>(1, (prev, admin) {
          final adminNumberString = admin['adminNumber'] ?? '0'; // Adjusted this line
          final adminNumber = int.tryParse(adminNumberString) ?? 0;
          return adminNumber > prev ? adminNumber : prev;
        }) + 1;
      }

      final ridersSnapshot = await _ridersRef.once();
      if (ridersSnapshot.snapshot.value != null) {
        final ridersData = Map<String, dynamic>.from(ridersSnapshot.snapshot.value as Map);

        _users.addAll(ridersData.values.map((user) {
          final map = Map<String, dynamic>.from(user);
          return {
            'uid': map['riderId'] ?? '',
            'name': map['name'] ?? 'Unknown',
            'email': map['email'] ?? 'No Email',
            'role': '2',
          };
        }).toList());

        _nextRiderNumber = ridersData.values.fold<int>(1, (prev, rider) {
          final riderNumberString = rider['riderNumber'] ?? '0';
          final riderNumber = int.tryParse(riderNumberString) ?? 0;
          return riderNumber > prev ? riderNumber : prev;
        }) + 1;
      }

      setState(() {
        _userNames = Map.fromEntries(
            _users.map((user) => MapEntry(user['uid'], user['name'] ?? 'Unknown'))
        );
        fetchItems(); // Fetch items after users are fetched
      });
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
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
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      DataSnapshot userSnapshot = await _userRef.child(uid).get();
      DataSnapshot adminSnapshot = await _adminRef.child(uid).get();
      DataSnapshot riderSnapshot = await _ridersRef.child(uid).get();
      Map<String, dynamic>? userData;

      if (userSnapshot.exists) {
        userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      } else if (adminSnapshot.exists) {
        userData = Map<String, dynamic>.from(adminSnapshot.value as Map);
      } else if (riderSnapshot.exists) {
        userData = Map<String, dynamic>.from(riderSnapshot.value as Map);
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
            'adminNumber': _nextAdminNumber.toString(),
          });
          await _userRef.child(uid).remove();
          await _ridersRef.child(uid).remove();
        } else if (role == '1') { // Move to users node
          await _userRef.child(uid).set({
            'uid': uid,
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'password': userData['password'] ?? '',
            'role': role,
          });
          await _adminRef.child(uid).remove();
          await _ridersRef.child(uid).remove();
        } else if (role == '2') { // Move to riders node
          await _ridersRef.child(uid).set({
            'riderId': uid,
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'password': userData['password'] ?? '',
            'role': role,
            'riderNumber': _nextRiderNumber.toString(), // Add unique rider number
          });
          await _userRef.child(uid).remove();
          await _adminRef.child(uid).remove();
        }

        if (role == '2') {
          setState(() {
            _nextRiderNumber++;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User role updated successfully")));
        await fetchUsers(); // Refresh the users list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
      }
    } catch (e) {
      print('Error updating user role: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating user role")));
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Admin Panel"),
      body: _isLoading // Conditionally display the loading indicator
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Users List
            const Padding(
              padding: EdgeInsets.all(8.0),
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['name'] ?? 'Unknown User'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("E-Mail: ${user['email'] ?? 'No Email'}"),
                      Text("Role: ${user['role'] == '0' ? 'Admin' : user['role'] == '1' ? 'Buyer' : 'Rider'}"),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: user['role'],
                    items: [
                      const DropdownMenuItem(value: '0', child: Text('Admin')),
                      const DropdownMenuItem(value: '1', child: Text('Buyer')),
                      const DropdownMenuItem(value: '2', child: Text('Rider')),
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
