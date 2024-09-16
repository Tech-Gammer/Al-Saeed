import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:myfirstmainproject/paymentfiles/payment.dart';
import 'package:myfirstmainproject/paymentfiles/paymentresponse.dart';
import 'package:myfirstmainproject/paymentfiles/textfields.dart';


class firstpage extends StatefulWidget {
  late double totalBalance;
  final Future<void> Function() placeOrder;

  firstpage(
      this.totalBalance,
      {required this.placeOrder,
      }
      );

  @override
  State<firstpage> createState() => _firstpageState();
}
class _firstpageState extends State<firstpage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _feedbackRef = FirebaseDatabase.instance.ref("Feedback");


  TextEditingController amountController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  final formkey1 = GlobalKey<FormState>();
  final formkey2 = GlobalKey<FormState>();
  final formkey3 = GlobalKey<FormState>();
  final formkey4 = GlobalKey<FormState>();
  final formkey5 = GlobalKey<FormState>();
  final formkey6 = GlobalKey<FormState>();
  List<String> currencyList = <String>[
    'PKR',
    'USD',
    'INR',
    'EUR',
    'JPY',
    'GBP',
    'AED'
  ];
  String selectedCurrency = 'PKR';
  bool hasDonated = false;
  late User currentUser;
  Map<String, dynamic>? cartItems;




  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    amountController = TextEditingController(text: widget.totalBalance.toStringAsFixed(0) ?? '');
  }

  Future<String?> _fetchOrderId() async {
    try {
      final orderSnapshot = await FirebaseDatabase.instance.ref('orders').orderByKey().limitToLast(1).once();
      final orderData = orderSnapshot.snapshot.value as Map?;
      final latestOrderId = orderData?.keys.last;
      return latestOrderId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch order ID: $e')),
      );
      return null;
    }
  }

  Future<void> fetchCartItems() async {
    String userId = currentUser.uid;
    final userCartRef = _cartRef.child(userId); // Reference to the current user's cart
    final snapshot = await userCartRef.once(); // Get all cart items for the user
    // final userCartRef = _cartRef;
    // final snapshot = await userCartRef.orderByChild('uid').equalTo(currentUser.uid).once();
    if (snapshot.snapshot.value != null) {
      setState(() {
        cartItems = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      });
    } else {
      setState(() {
        cartItems = {};
      });
    }
  }


  Future<void> initPaymentSheet() async {
    try {
      // 1. create payment intent on the server
      final data = await cretaePaymentIntent(
          amount: (int.parse(amountController.text)*100).toString(),
          currency: selectedCurrency,
          name: nameController.text,
          address: addressController.text,
          pin: pincodeController.text,
          city: cityController.text,
          state: stateController.text,
          country: countryController.text);
      // 2. initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // Set to true for custom flow
          customFlow: false,
          // Main params
          merchantDisplayName: 'Umair',
          paymentIntentClientSecret: data['client_secret'],
          // Customer keys
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          // Extra options

          style: ThemeMode.dark,
        ),
      );
      setState(() {

      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      rethrow;
    }
  }

  Future<void> _savePaymentDetails(String orderId) async {
  try {
    final orderRef = _ordersRef.child(orderId);
    final _paymentRef = orderRef.child('payment_details');
    await _paymentRef.update({
    'orderId': orderId,
    'amount': amountController.text,
    'currency': selectedCurrency,
    'name': nameController.text,
    'address': addressController.text,
    'city': cityController.text,
    'state': stateController.text,
    'country': countryController.text,
    'pincode': pincodeController.text,
    'timestamp': DateTime.now().toIso8601String(),
  });

      // final paymentDetails = {
      //   'orderId': orderId,
      //   'amount': amountController.text,
      //   'currency': selectedCurrency,
      //   'name': nameController.text,
      //   'address': addressController.text,
      //   'city': cityController.text,
      //   'state': stateController.text,
      //   'country': countryController.text,
      //   'pincode': pincodeController.text,
      //   'timestamp': DateTime.now().toIso8601String(),
      // };

      // Save payment details within the order node
      // await _paymentRef.child(orderId).set({'payment_details': paymentDetails});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment details saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save payment details: $e')),
      );
    }
  }


  Future<void> showFeedbackDialog(String orderId) async {
    double rating = 0.0;
    TextEditingController feedbackController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rate your items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating;
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(hintText: 'Leave your feedback'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (rating > 0 && feedback.isNotEmpty) {
                  await saveFeedback(orderId, rating, feedback, currentUser.uid);
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResponsePage(orderId),
                    ),
                  );
                } else {
                  // Show a message if feedback or rating is not provided
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please provide a rating and feedback'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveFeedback(String orderId, double rating, String feedback, String userId) async {
    if (cartItems != null && cartItems!.isNotEmpty) {
      cartItems!.forEach((key, item) async {
        final itemId = item['itemId'] ?? 'unknownItemId';  // Handle potential missing fields
        final adminId = item['adminId'] as String? ?? 'unknownAdminId'; // Ensure `adminId` exists
        final feedbackData = {
          'orderId': orderId,
          'itemId': itemId,
          'adminId': adminId,
          'rating': rating,
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': userId
        };

        // Push feedback to the Feedback node
        try {
          await _feedbackRef.push().set(feedbackData);
          print("Feedback saved successfully for $itemId");
        } catch (e) {
          print("Failed to save feedback for $itemId: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save feedback: $e')),
          );
        }
      });
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No cart items found to provide feedback on.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Make Your Payments Easily",
                        style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: ReusableTextField(
                                formkey: formkey,
                                controller: amountController,
                                isNumber: true,
                                title: "Total Order Amount",
                                hint: "Order Amount",
                              readOnly: true,
                            ),

                          ),
                          SizedBox(
                            width: 10,
                          ),
                          DropdownMenu<String>(
                            inputDecorationTheme: InputDecorationTheme(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 0),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            initialSelection: currencyList.first,
                            onSelected: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                selectedCurrency = value!;
                              });
                            },
                            dropdownMenuEntries: currencyList
                                .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                  value: value, label: value);
                            }).toList(),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ReusableTextField(
                        formkey: formkey1,
                        title: "Name",
                        hint: "Ex. Ali",
                        controller: nameController,
                        readOnly: false,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ReusableTextField(
                        formkey: formkey2,
                        title: "Address Line",
                        hint: "Ex. 123 Main St",
                        controller: addressController,
                        readOnly: false,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey3,
                                title: "City",
                                hint: "Ex. Lahore",
                                controller: cityController,
                                readOnly: false,
                              )),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey4,
                                title: "State (Short code)",
                                hint: "Ex. Lh for Lahore",
                                controller: stateController,
                                readOnly: false,
                              )),
                        ],
                      ),

                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey5,
                                title: "Country (Short Code)",
                                hint: "Ex. PK for Pakistan",
                                controller: countryController,
                                readOnly: false,
                              )),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey6,
                                title: "Pincode",
                                hint: "Ex. 123456",
                                controller: pincodeController,
                                readOnly: false,
                                isNumber: true,
                              )),
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent.shade400),
                          child: Text(
                            "Proceed to Pay",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          onPressed: () async {
                            if (formkey.currentState!.validate() &&
                                formkey1.currentState!.validate() &&
                                formkey2.currentState!.validate() &&
                                formkey3.currentState!.validate() &&
                                formkey4.currentState!.validate() &&
                                formkey5.currentState!.validate() &&
                                formkey6.currentState!.validate()) {
                              try {
                                // Initialize the payment sheet
                                await initPaymentSheet();

                                // Present the payment sheet to the user
                                await Stripe.instance.presentPaymentSheet();

                                // Payment successful, show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Done",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Call placeOrder after successful payment

                                await widget.placeOrder();

                                // Fetch the orderId
                                final orderId = await _fetchOrderId();
                                if (orderId == null) {
                                  return; // Stop processing if no orderId is found
                                }

                                // Save payment details to Firebase with the fetched orderId
                                await _savePaymentDetails(orderId);
                                await showFeedbackDialog(orderId); // Ensure dialog is shown

                                // Clear text fields
                                nameController.clear();
                                addressController.clear();
                                cityController.clear();
                                stateController.clear();
                                countryController.clear();
                                pincodeController.clear();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResponsePage(

                                        orderId,

                                    ),
                                  ),
                                );
                              } catch (e) {
                                print("payment sheet failed: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Failed",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      )
                    ]
                )
            ),
          ],
        ),
      ),
    );
  }
}
