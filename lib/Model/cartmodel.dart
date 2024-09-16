
class CartItem {
  String itemId;
  final String adminId;
  String name;
  String imageUrl;
  String category;
  String sale_rate;
  String ptc_code;
  String barcode;
  String description;
  int quantity;
  String unit;
  String uid;
  String item_qty;

  CartItem({
    required this.itemId,
    required this.adminId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.sale_rate,
    required this.ptc_code,
    required this.barcode,
    required this.unit,
    required this.description,
    required this.quantity,
    required this.uid,
    required this.item_qty,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'adminId': adminId,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'sale_rate': sale_rate,
      'ptc_code' : ptc_code,
      'barcode' : barcode,
      'description': description,
      'quantity': quantity,
      'uid': uid,
      'unit':unit,
      'item_qty' : item_qty,
    };
  }
}
