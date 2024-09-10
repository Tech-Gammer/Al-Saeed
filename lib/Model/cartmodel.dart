
class CartItem {
  String itemId;
  final String adminId;
  String name;
  String imageUrl;
  String category;
  String rate;
  String description;
  int quantity;
  String uid;

  CartItem({
    required this.itemId,
    required this.adminId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.rate,
    required this.description,
    required this.quantity,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'adminId': adminId,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'rate': rate,
      'description': description,
      'quantity': quantity,
      'uid': uid,
    };
  }
}
