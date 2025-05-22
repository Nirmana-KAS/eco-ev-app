import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String contact;
  final String nic;
  final String role;
  final String authProvider;
  final DateTime? createdAt;
  final String? photoUrl; // <-- add this

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.contact,
    required this.nic,
    required this.role,
    required this.authProvider,
    this.createdAt,
    this.photoUrl, // <-- add this
  });

  // Factory to create UserModel from Firestore data (doc snapshot)
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      contact: map['contact'] ?? '',
      nic: map['nic'] ?? '',
      role: map['role'] ?? '',
      authProvider: map['auth_provider'] ?? '',
      createdAt:
          map['created_at'] != null
              ? (map['created_at'] as Timestamp).toDate()
              : null,
      photoUrl: map['photoUrl'], // <-- add this
    );
  }

  // Convert to Map for uploading to Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'contact': contact,
      'nic': nic,
      'role': role,
      'auth_provider': authProvider,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'photoUrl': photoUrl, // <-- add this
    };
  }
}
