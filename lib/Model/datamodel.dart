class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  UserModel(this.uid, this.name, this.email, this.phone, this.password, this.role);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }
}

class AdminModel {
  final String adminId;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  AdminModel(this.adminId, this.name, this.email, this.phone, this.password, this.role);

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }
}
