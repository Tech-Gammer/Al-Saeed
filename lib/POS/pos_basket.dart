import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myfirstmainproject/POS/pos_panel.dart';

import '../components.dart';

class BasketPage extends StatefulWidget {
  final List<Map<String, dynamic>> basket;

  const BasketPage({super.key, required this.basket});

  @override
  _BasketPageState createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  final DatabaseReference _basketRef = FirebaseDatabase.instance.ref('POS_Basket');
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref('POS_Orders');
  late List<Map<String, dynamic>> basket;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance


  @override
  void initState() {
    super.initState();
    basket = widget.basket;
  }

  double _toDouble(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else {
      return 0.0;
    }
  }

  double get _totalAmount {
    double total = basket.fold(0.0, (sum, item) {
      double itemTotal = _toDouble(item['total']);
      return sum + itemTotal;
    });
    return total;
  }



  // Future<void> _updateQuantity(int index, int newQuantity) async {
  //   // final item = basket[index];
  //   // final basketItemId = item['itemId']; // Use the correct key for Firebase
  //   final Map<String, dynamic> item = basket[index] as Map<String, dynamic>;
  //   final basketItemId = item['itemId'];
  //   print(basketItemId);
  //
  //   if (basketItemId == null) {
  //     // Handle case where 'basketItemId' is missing
  //     return;
  //   }
  //
  //   try {
  //     String userId = _auth.currentUser?.uid ?? ''; // Get the current user's ID
  //
  //     if (newQuantity <= 0) {
  //       // Remove item if quantity is zero or less
  //       basket.removeAt(index);
  //       await _basketRef.child(userId).child(basketItemId).remove(); // Remove item from Firebase
  //     } else {
  //       // Parse the saleRate as double from the string value
  //       final saleRate = double.parse(item['net_rate'].toString());
  //       final newTotal = saleRate * newQuantity;
  //
  //       basket[index]['quantity'] = newQuantity;
  //       basket[index]['total'] = newTotal;
  //
  //       // Update the quantity and total under the user's POS_Basket
  //       await _basketRef.child(userId).child(basketItemId).update({
  //         'quantity': newQuantity,
  //         'total': newTotal,
  //       });
  //     }
  //     setState(() {}); // Rebuild the widget to reflect the updated quantity
  //   } catch (e) {
  //     print('Error updating quantity: $e');
  //   }
  // }
  // Future<void> _showQuantityDialog(int index) async {
  //   final item = basket[index];
  //   final TextEditingController quantityController = TextEditingController(
  //     text: (item['quantity'] ?? 0).toString(),
  //   );
  //
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false, // User must tap button to close
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Adjust Quantity for ${item['item_name'] ?? 'Unknown'}'),
  //         content: TextField(
  //           controller: quantityController,
  //           keyboardType: TextInputType.number,
  //           decoration: InputDecoration(
  //             labelText: 'Quantity',
  //             border: OutlineInputBorder(),
  //           ),
  //           onChanged: (value) {
  //             // Optional: Perform validation or transformation here
  //           },
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Update'),
  //             onPressed: () {
  //               final newQuantity = int.tryParse(quantityController.text) ?? 0;
  //               _updateQuantity(index, newQuantity);
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _showSaveDialog() async {
    final TextEditingController receivedAmountController = TextEditingController();
    final TextEditingController customerNameController = TextEditingController();
    final TextEditingController phoneNumberController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Basket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Amount: ${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextField(
                controller: receivedAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Received Amount *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                final receivedAmount = double.tryParse(receivedAmountController.text) ?? 0.0;
                final customerName = customerNameController.text.trim();
                final phoneNumber = phoneNumberController.text.trim();

                // Check if the received amount is valid
                if (receivedAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Received amount is required and must be greater than 0.')),
                  );
                  return;
                }

                if (receivedAmount < _totalAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Received amount must be equal to or greater than the total amount (${_totalAmount.toStringAsFixed(2)}).')),
                  );
                  return;
                }

                // Proceed to save the basket with the additional details
                Navigator.of(context).pop(); // Close the dialog
                await _saveBasket(receivedAmount, customerName, phoneNumber);
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveBasket(double receivedAmount, String customerName, String phoneNumber) async {
    try {
      // Check if basket has items
      if (basket.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Basket is empty.')),
        );
        return;
      }

      final newOrderRef = _ordersRef.push(); // Auto generate a unique ID
      final orderId = newOrderRef.key; // Get the generated order ID

      await newOrderRef.set({
        'orderId': orderId,
        'items': basket,
        'totalAmount': _totalAmount,
        'receivedAmount': receivedAmount,
        'customerName': customerName.isNotEmpty ? customerName : null,
        'phoneNumber': phoneNumber.isNotEmpty ? phoneNumber : null,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Clear data from POS_Basket
      await _basketRef.remove();

      setState(() {
        basket.clear(); // Clear local state
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Basket saved and cleared successfully!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const POSPage()),
            (Route<dynamic> route) => false, // This removes all previous routes
      );
    } catch (e) {
      print('Error saving basket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save basket.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar.customAppBar("Basket"),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: basket.isNotEmpty
                  ? ListView.builder(
                itemCount: basket.length,
                itemBuilder: (context, index) {
                  final item = basket[index];
                  final sale_rate = _toDouble(item['sale_rate']);
                  final total = _toDouble(item['total']);
                  final quantity = item['quantity'] ?? 0;
                  final tax_amount = item['tax_amount']?? 0;
                  return Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey, width: 2), // Border color and width
                      borderRadius: BorderRadius.circular(12.0), // Border radius
                    ),
                    child: ListTile(
                      title: Text(item['item_name'] ?? 'Unknown'),
                      subtitle: Text('Rate: ${sale_rate.toStringAsFixed(0)} |  Quantity: $quantity | GST: $tax_amount'),
                      trailing: Text('Total: ${total.toStringAsFixed(0)}',style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                      // onTap: () => _showQuantityDialog(index),
                    ),
                  );
                },
              )
                  : const Center(child: Text('No items in the basket')),
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'Grand Total: ${_totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: screenWidth * 0.04),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  // onPressed: _saveBasket,
                  onPressed: _showSaveDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe6b67e),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: const Text('Save Basket', style: NewCustomTextStyles.newcustomTextStyle),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
