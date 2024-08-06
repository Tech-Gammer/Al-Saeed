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

        // Iterate over each admin node
        for (final adminId in dataSnapshot.keys) {
          final adminDataSnapshot = dataSnapshot[adminId] as Map;

          // Iterate over each item node under the admin node
          for (final itemId in adminDataSnapshot.keys) {
            final itemData = adminDataSnapshot[itemId] as Map;

            // Convert each item field to a string if necessary
            allData[itemId] = {
              'item_name': itemData['item_name']?.toString() ?? 'No Name',
              'category': itemData['category']?.toString() ?? 'No Category',
              'rate': itemData['rate']?.toString() ?? 'No Rate',
              'description': itemData['description']?.toString() ?? 'No Description',
              'image': itemData['image']?.toString() ?? '',
            };
          }
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
      print('Error fetching data: $e');
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
        backgroundColor: Color(0xFFe6b67e),
        title: Text('Items List', style: NewCustomTextStyles.newcustomTextStyle),
        leading: IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>FrontPage()));
          },
          icon: Icon(Icons.arrow_back),
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
          ? Center(child: CircularProgressIndicator())
          : filteredData != null && filteredData.isNotEmpty
          ? GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.5,
        ),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(filteredData[index].value);
          final imageUrl = item['image'] as String?;
          final itemName = item['item_name'] as String? ?? 'No Name';
          final category = item['category'] as String? ?? 'No Category';
          final rate = item['rate'] as String? ?? 'No Rate';
          final description = item['description'] as String? ?? 'No Description';
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
                    rate: rate,
                    description: description,
                    itemId: itemId,
                    item_name: itemName,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 150,
                    width: 120,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(itemName, style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 20, color: Colors.brown))),
                  Text(category, style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 14, color: Colors.brown))),
                  Text("Rs $rate", style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 14, color: Colors.brown))),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemSelectPage(
                            imageUrl: imageUrl,
                            category: category,
                            rate: rate,
                            description: description,
                            itemId: itemId,
                            item_name: itemName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 40,
                      decoration: BoxDecoration(color: Color(0xFFe6b67e), borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "ADD TO CART",
                          style: GoogleFonts.lora(
                            textStyle: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : SizedBox.shrink();
        },
      )
          : Center(child: Text("No items found", style: GoogleFonts.lora(textStyle: TextStyle(fontSize: 20, color: Colors.brown)))),
    );
  }
}
