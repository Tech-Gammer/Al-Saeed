import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for authentication
import 'package:myfirstmainproject/POS/pos_basket.dart';
import 'package:myfirstmainproject/POS/pos_orders.dart';

import '../admin/admin.dart';
import '../components.dart';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final DatabaseReference _itemRef = FirebaseDatabase.instance.ref().child('items');
  final DatabaseReference _basketRef = FirebaseDatabase.instance.ref().child('POS_Basket'); // Reference for saving basket data
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance

  List<Map<String, dynamic>> _basket = [];
  Map<String, dynamic>? _selectedItem;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();

  double _calculatedTotal = 0.0;
  int _basketItemCount = 0; // To track the number of items in the basket


  void _searchItem(String barcodeOrItemName) async {
    final DataSnapshot snapshot = await _itemRef.get();

    if (snapshot.exists) {
      final itemsData = Map<String, dynamic>.from(snapshot.value as Map);

      final lowercaseQuery = barcodeOrItemName.toLowerCase();


      final item = itemsData.values.firstWhere(
            (item) =>
            (
                item['barcode'].toString().toLowerCase().contains(lowercaseQuery)||
                item['item_name'].toString().toLowerCase().contains(lowercaseQuery)
            ),
        orElse: () => null,
      );

      setState(() {
        _selectedItem = item != null ? Map<String, dynamic>.from(item) : null;
        _calculatedTotal = 0.0; // Reset total when new item is selected
      });
    }
  }

  void _calculateTotal(String value) {
    final quantity = int.tryParse(value) ?? 0;
    final sale_rate = double.tryParse(_selectedItem!['sale_rate'].toString()) ?? 0.0;
    final tax = double.tryParse(_selectedItem!['tax'].toString()) ?? 0.0;
    final total = (sale_rate * quantity) + ((tax / 100) * (sale_rate * quantity));

    setState(() {
      _calculatedTotal = total;
    });
  }

  Future<void> _addToBasket() async {
    if (_selectedItem != null) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;

      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }

      final sale_rate = double.tryParse(_selectedItem!['sale_rate'].toString()) ?? 0.0;
      final tax = double.tryParse(_selectedItem!['tax'].toString()) ?? 0.0;
      final total = (sale_rate * quantity) + ((tax / 100) * (sale_rate * quantity));

      final newItem = {
        ..._selectedItem!,
        'quantity': quantity,
        'total': total,
      };

      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        try {
          final basketRef = _basketRef.child(userId);

          // Get the existing basket data
          final snapshot = await basketRef.get();
          Map<String, dynamic> existingItems = snapshot.exists
              ? Map<String, dynamic>.from(snapshot.value as Map)
              : {};

          bool itemExists = false;
          String basketItemId = '';

          // Check if the item is already in the basket
          for (var entry in existingItems.entries) {
            if (entry.value['barcode'] == newItem['barcode']) {
              itemExists = true;
              basketItemId = entry.key;
              int existingQuantity = entry.value['quantity'];
              int newQuantity = existingQuantity + quantity;

              // Update the existing item's quantity
              await basketRef.child(basketItemId).update({
                'quantity': newQuantity,
                'total': newQuantity * sale_rate
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Item quantity updated in basket!")),
              );
              break;
            }
          }

          if (!itemExists) {
            basketItemId = basketRef.push().key ?? '';
            // Add the new item to the basket
            await basketRef.child(basketItemId).set(newItem);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item added to basket!")),
            );
          }

          // Update local basket state
          setState(() {
            _basket.add(newItem);
            _selectedItem = null;
            _quantityController.clear();
            _searchController.clear();
            _calculatedTotal = 0.0; // Reset total after adding to basket
            _fetchBasketItemCount(); // Update basket item count

          });
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add/update item in basket: $error")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user signed in')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No item selected')),
      );
    }
  }

  void _viewBasket() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final basketSnapshot = await _basketRef.child(userId).get();

        if (!basketSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Basket is empty')),
          );
          return;
        }

        List<Map<String, dynamic>> basket = [];
        final basketData = basketSnapshot.value;

        if (basketData is Map) {
          basket = basketData.values
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BasketPage(basket: basket)),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch basket data: $error")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBasketItemCount();
  }

  void _fetchBasketItemCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final snapshot = await _basketRef.child(userId).get();
      if (snapshot.exists) {
        final basketData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _basketItemCount = basketData.length; // Number of items in the basket
        });
      } else {
        setState(() {
          _basketItemCount = 0; // Reset if basket is empty
        });
      }
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:const Color(0xFFe6b67e),
        leading: IconButton(onPressed: (){
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Admin()),
                (Route<dynamic> route) => false, // This removes all previous routes
          );

        }, icon: Icon(Icons.home)),
        title: const Text('Point of Sale'),
        titleTextStyle: TextStyle(
          fontFamily: 'Lora',
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _viewBasket,
                icon: const Icon(Icons.shopping_cart),
              ),
              if (_basketItemCount > 0) // Show badge only if there's an item in the basket
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$_basketItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const pos_Orders()),
              );
            },
            icon: const Icon(Icons.list),
          ),
        ],
      ),

        body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(isLargeScreen),
              if (_selectedItem != null) _buildItemDetails(isLargeScreen),
              ElevatedButton(
                onPressed: _showItemSelectionDialog,
                child: const Text('Select Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showItemSelectionDialog() async {
    final DataSnapshot snapshot = await _itemRef.get();

    if (snapshot.exists) {
      final itemsData = Map<String, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> itemsList = itemsData.values.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          TextEditingController searchController = TextEditingController();
          List<Map<String, dynamic>> filteredItems = itemsList;

          return StatefulBuilder(
            builder: (context, setState) {
              void _filterItems(String query) {
                setState(() {
                  filteredItems = itemsList.where((item) {
                    return item['item_name'].toString().toLowerCase().contains(query.toLowerCase());
                  }).toList();
                });
              }

              return AlertDialog(
                title: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search items by name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: _filterItems,
                    ),
                    const SizedBox(height: 10),
                    Text('Select an item'),
                  ],
                ),
                content: SizedBox(
                  height: 400, // Adjust the height as necessary
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        title: Text(item['item_name']),
                        subtitle: Text('Rate: Pkr ${item['sale_rate']}'),
                        onTap: () {
                          setState(() {
                            _selectedItem = item;
                          });
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      );
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Widget _buildSearchField(bool isLargeScreen) {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by Barcode/Item Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        prefixIcon: Icon(Icons.search),
        contentPadding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
      ),
      onChanged: _searchItem,
    );
  }

  Widget _buildItemDetails(bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 16.0 : 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item Name: ${_selectedItem!['item_name']}', style: _itemDetailStyle(isLargeScreen)),
              Text('Rate: ${_selectedItem!['sale_rate']}', style: _itemDetailStyle(isLargeScreen)),
              Text('Tax (%): ${_selectedItem!['tax']}', style: _itemDetailStyle(isLargeScreen)),
              SizedBox(height: isLargeScreen ? 16.0 : 8.0),
              _buildQuantityField(isLargeScreen),
              SizedBox(height: isLargeScreen ? 16.0 : 8.0),
              Text('Total: \Pkr ${_calculatedTotal.toStringAsFixed(0)}', style: _itemDetailStyle(isLargeScreen)),
              SizedBox(height: isLargeScreen ? 16.0 : 8.0),

              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _addToBasket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe6b67e),
                      padding: const EdgeInsets.all(10),
                    ),
                    child: const Text('Add to Basket', style: NewCustomTextStyles.newcustomTextStyle),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityField(bool isLargeScreen) {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Enter Quantity',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
      ),
      keyboardType: TextInputType.number,
      onChanged: _calculateTotal,
    );
  }

  TextStyle _itemDetailStyle(bool isLargeScreen) {
    return TextStyle(
      fontSize: isLargeScreen ? 18.0 : 16.0,
      fontWeight: FontWeight.w500,
    );
  }
}
