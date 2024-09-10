
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// class Order {
//   String orderId;
//   String status;
//   String userId;
//   double total; // Change this to double
//   List<OrderItem> items;
//
//   Order({
//     required this.orderId,
//     required this.status,
//     required this.userId,
//     required this.items,
//     required this.total,
//   });
//
//   factory Order.fromMap(Map<String, dynamic> map, String orderId) {
//     List<OrderItem> items = [];
//     if (map['items'] != null) {
//       final itemsMap = Map<String, dynamic>.from(map['items'] as Map);
//       items = itemsMap.entries.map((entry) {
//         return OrderItem.fromMap(Map<String, dynamic>.from(entry.value));
//       }).toList();
//     }
//
//     return Order(
//       orderId: orderId,
//       status: map['status'] ?? 'Pending',
//       userId: map['userId'] ?? '',
//       items: items,
//       total: (map['total'] ?? 0.0).toDouble(), // Convert to double
//     );
//   }
// }

class Order {
  String orderId;
  String status;
  String userId;
  double total;
  List<OrderItem> items;
  Map<String, dynamic>? returnRequest; // Make sure this is nullable

  Order({
    required this.orderId,
    required this.status,
    required this.userId,
    required this.items,
    required this.total,
    this.returnRequest, // Allow null values
  });

  factory Order.fromMap(Map<String, dynamic> map, String orderId) {
    List<OrderItem> items = [];
    if (map['items'] != null) {
      final itemsMap = Map<String, dynamic>.from(map['items'] as Map);
      items = itemsMap.entries.map((entry) {
        return OrderItem.fromMap(Map<String, dynamic>.from(entry.value));
      }).toList();
    }

    return Order(
      orderId: orderId,
      status: map['status'] ?? 'Pending',
      userId: map['userId'] ?? '',
      items: items,
      total: (map['total'] ?? 0.0).toDouble(),
      returnRequest: map['returnRequest'] != null
          ? Map<String, dynamic>.from(map['returnRequest'] as Map)
          : null, // Safely assign the returnRequest
    );
  }
}

class ReturnRequest {
  String reason;
  String status;
  DateTime requestedAt;

  ReturnRequest({
    required this.reason,
    required this.status,
    required this.requestedAt,
  });

  factory ReturnRequest.fromMap(Map<String, dynamic> map) {
    return ReturnRequest(
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Pending',
      requestedAt: DateTime.parse(map['requestedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reason': reason,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}






// class OrderItem {
//   String adminId;
//   String category;
//   String description;
//   String imageUrl;
//   String itemId;
//   String name;
//   int quantity;
//   String rate;
//   // String total;
//
//   OrderItem({
//     required this.adminId,
//     required this.category,
//     required this.description,
//     required this.imageUrl,
//     required this.itemId,
//     required this.name,
//     required this.quantity,
//     required this.rate,
//     // required this.total,
//   });
//
//   factory OrderItem.fromMap(Map<String, dynamic> map) {
//     return OrderItem(
//       adminId: map['adminId'] ?? '',
//       category: map['category'] ?? '',
//       description: map['description'] ?? '',
//       imageUrl: map['imageUrl'] ?? '',
//       itemId: map['itemId'] ?? '',
//       name: map['name'] ?? '',
//       quantity: map['quantity'] ?? 1,
//       rate: map['rate'] ?? '',
//       // total: (int.parse(map['rate'] ?? '0') * (map['quantity'] ?? 1)).toString(),
//     );
//   }
// }

class OrderItem {
  String adminId;
  String category;
  String description;
  String imageUrl;
  String itemId;
  String name;
  int quantity;
  String rate;

  OrderItem({
    required this.adminId,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.rate,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      adminId: map['adminId'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      rate: map['rate'] ?? '',
    );
  }
}





class MapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  MapScreen({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId('userLocation'),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: 'User Location'),
          ),
        },
      ),
    );
  }
}

