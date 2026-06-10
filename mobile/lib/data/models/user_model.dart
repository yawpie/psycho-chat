import 'package:psycho_chat/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'].toString(),
    );
  }
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'].toString(),
      username: map['username'].toString(),
    );
  }
}