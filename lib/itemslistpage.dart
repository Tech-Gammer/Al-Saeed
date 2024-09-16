import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myfirstmainproject/components.dart';
import 'package:myfirstmainproject/homepage.dart';
import 'itemselectpage.dart';

class ItemListPage extends StatefulWidget {
  final String uid;

  const ItemListPage({Key? key, required this.uid}) : super(key: key);

  @override
  _ItemListPageState createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final DatabaseReference _dataRef = FirebaseDatabase.instance.ref("items");
  Map<String, dynamic>? data;
  List<String> categories = ['All Items'];
  String selectedCategory = 'All Items';
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final snapshot = await _dataRef.get();
      if (snapshot.exists) {
        final Map<String, dynamic> allData = {};
        final dataSnapshot = snapshot.value as Map;
        for (final itemId in dataSnapshot.keys) {
          final itemDataSnapshot = dataSnapshot[itemId] as Map;
          allData[itemId] = {
            'item_name': itemDataSnapshot['item_name']?.toString() ?? 'No Name',
            'category': itemDataSnapshot['category']?.toString() ?? 'No Category',
            'net_rate': itemDataSnapshot['net_rate']?.toString() ?? 'No Rate',
            'ptc_code': itemDataSnapshot['ptc_code']?.toString() ?? 'No ptc_code',
            'barcode': itemDataSnapshot['barcode']?.toString() ?? 'No barcode',
            'description': itemDataSnapshot['description']?.toString() ?? 'No Description',
            'image': itemDataSnapshot['image']?.toString() ?? '',
          };
        }

        setState(() {
          data = allData;
          _isLoading = false;
        });
        extractCategories();
      } else {
        setState(() {
          data = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void extractCategories() {
    final Set<String> categorySet = {'All Items'};
    data?.forEach((key, value) {
      final itemData = Map<String, dynamic>.from(value);
      categorySet.add(itemData['category'] ?? 'No Category');
    });
    setState(() {
      categories = categorySet.toList();
    });
  }

  void _filterItemsByCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = data?.entries.where((entry) {
      final item = Map<String, dynamic>.from(entry.value);
      final itemCategory = item['category'];
      return selectedCategory == 'All Items' || itemCategory == selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFe6b67e),
        title: const Text('Items List', style: NewCustomTextStyles.newcustomTextStyle),
        leading: IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>const FrontPage()));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.lora()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _filterItemsByCategory(newValue);
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredData != null && filteredData.isNotEmpty
          ? GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.7,
        ),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(filteredData[index].value);
          final imageUrl = item['image'] as String?;
          final itemName = item['item_name'] as String? ?? 'No Name';
          final category = item['category'] as String? ?? 'No Category';
          final net_rate = item['net_rate'] as String? ?? 'No Rate';
          final ptc_code = item['ptc_code'] as String? ?? 'No ptc_code';
          final item_qty = item['item_qty'] as String? ?? 'No qty';
          final unit = item['unit'] as String? ?? 'No qty';
          final barcode = item['barcode'] as String? ?? 'No barcode';
          final description = item['description'] as String? ?? 'No Description';
          final adminId = item['adminId'] as String? ?? 'adminId';
          final itemId = filteredData[index].key;

          return imageUrl != null && imageUrl.isNotEmpty
              ? GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemSelectPage(
                    imageUrl: imageUrl,
                    category: category,
                    net_rate: net_rate,
                    ptc_code: ptc_code,
                    item_qty:item_qty,
                    unit: unit,
                    description: description,
                    itemId: itemId,
                    item_name: itemName,
                    barcode: barcode,
                    adminId: adminId,

                  ),
                ),
              );
            },
            //     child: Card(
            //   elevation: 5,
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Container(
            //         height: 150,
            //         width: 120,
            //         child: CircleAvatar(
            //           radius: 70,
            //           backgroundImage: NetworkImage(imageUrl),
            //         ),
            //       ),
            //       SizedBox(height: 8),
            //       Text(itemName, style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 18, color: Colors.brown,fontWeight: FontWeight.bold)),
            //         maxLines: 2, // Limits the text to a single line
            //         textAlign: TextAlign.center,),
            //       Text(category, style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 14, color: Colors.brown))),
            //       Text("Rs $rate", style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 14, color: Colors.brown))),
            //       SizedBox(height: 8),
            //       TextButton(
            //         onPressed: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => ItemSelectPage(
            //                 imageUrl: imageUrl,
            //                 category: category,
            //                 sale_rate: sale_rate,
            //                 description: description,
            //                 itemId: itemId,
            //                 item_name: itemName,
            //                 adminId: adminId,
            //               ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           width: 150,
            //           height: 40,
            //           decoration: BoxDecoration(color: Color(0xFFe6b67e), borderRadius: BorderRadius.circular(20)),
            //           child: Center(
            //             child: Text(
            //               "ADD TO CART",
            //               style: GoogleFonts.lora(
            //                 textStyle: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            child: Stack(
              children: [
                Card(
                  elevation: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            itemName,
                            style: GoogleFonts.lora(
                              textStyle: const TextStyle(fontSize: 18, color: Colors.brown, fontWeight: FontWeight.bold),
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Text(
                        category,
                        style: GoogleFonts.lora(
                          textStyle: const TextStyle(fontSize: 16, color: Colors.brown),
                        ),
                      ),
                      Text(
                        "Rs $net_rate",
                        style: GoogleFonts.lora(
                          textStyle: const TextStyle(fontSize: 16, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemSelectPage(
                            item_name: itemName,
                            imageUrl: imageUrl,
                            category: category,
                            item_qty:item_qty,
                            unit: unit,
                            net_rate: net_rate,
                            ptc_code: ptc_code,
                            barcode: barcode,
                            description: description,
                            itemId: itemId,
                            adminId: adminId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_basket,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink();
        },
      )
          : Center(child: Text("No items found", style: GoogleFonts.lora(textStyle: const TextStyle(fontSize: 20, color: Colors.brown)))),
    );
  }
}
