class CartItem {
  final String itemId;
  final String name;
  final String imageUrl;
  final String category;
  final String rate;
  final String description;
  final int quantity;
  final String uid; // Add uid field

  CartItem({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.rate,
    required this.description,
    required this.quantity,
    required this.uid, // Initialize uid
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'rate': rate,
      'description': description,
      'quantity': quantity,
      'userId': uid, // Include uid in map
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      itemId: map['itemId'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      category: map['category'],
      rate: map['rate'],
      description: map['description'],
      quantity: map['quantity'],
      uid: map['userId'], // Read uid from map
    );
  }
}
