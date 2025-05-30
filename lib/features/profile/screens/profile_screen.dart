import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _photoUrl;
  bool _isUploading = false;
  String? _role;

  // For image picking
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _isUploading = true);

      File imageFile = File(pickedFile.path);

      try {
        final ref = FirebaseStorage.instance.ref().child(
          'user_photos/${user.uid}.jpg',
        );
        await ref.putFile(imageFile);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoUrl': url});
        setState(() {
          _photoUrl = url;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About Us"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ECO EV App\n"),
            Text(
              "Empowering Sri Lanka's EV future with smart, easy, and accessible charging solutions.\n",
            ),
            Divider(),
            Text("Company: ECO EV Solutions Pvt Ltd"),
            Text("Hotline: +94 77 123 4567"),
            Text("Email: support@ecoev.lk"),
            Text("Location: Colombo, Sri Lanka"),
            SizedBox(height: 8),
            Text("Version: 1.0.0"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _role = doc.data()!['role'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("User data not found."));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;

          String username = data['username'] ?? 'No Name';
          String email = data['email'] ?? 'No Email';
          String contact = data['contact'] ?? 'No Contact';
          String nic = data['nic'] ?? '-';
          String role = data['role'] ?? '-';
          String photoUrl = _photoUrl ?? data['photoUrl'] ?? '';
          String createdAt =
              data['created_at'] != null
                  ? (data['created_at'] as Timestamp)
                      .toDate()
                      .toString()
                      .split(' ')
                      .first
                  : '-';

          return SafeArea(
            child: Column(
              children: [
                // Profile header area
                Stack(
                  children: [
                    // The header content (profile image, edit, admin button)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 30, bottom: 18),
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Profile image
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: (photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/profile_placeholder.png') as ImageProvider,
                            ),
                            // Edit photo icon (bottom right)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _isUploading ? null : _pickAndUploadImage,
                                borderRadius: BorderRadius.circular(25),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Admin Dashboard Floating Button (top right of header area)
                    if (_role == 'admin')
                      Positioned(
                        top: 18, // adjust vertically if needed
                        right: 30, // adjust horizontally if needed
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/admin');
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF30B27C),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 0,
                    ),
                    children: [
                      // Username
                      const SizedBox(height: 10),
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _profileRow(
                                "Contact",
                                contact,
                                icon: Icons.phone,
                              ),
                              const Divider(),
                              _profileRow(
                                "NIC / Passport",
                                nic,
                                icon: Icons.credit_card,
                              ),
                              const Divider(),
                              _profileRow("Role", role, icon: Icons.security),
                              const Divider(),
                              _profileRow(
                                "Joined",
                                createdAt,
                                icon: Icons.calendar_today,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // --- Log Out Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Log Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/welcome',
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // --- Bottom area fixed! ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // About Us & Feedback Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Color(0xFF007800),
                              ),
                              label: const Text(
                                "About Us",
                                style: TextStyle(color: Color(0xFF007800)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF007800),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: _showAboutUsDialog,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.feedback_outlined,
                                color: Color(0xFF007800),
                              ),
                              label: const Text(
                                "Feedback",
                                style: TextStyle(color: Color(0xFF007800)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF007800),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/feedback');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // --- Company Info ---
                      Text(
                        "Developed by ECO EV Solutions Pvt Ltd\n© 2025 ECO EV App | All rights reserved",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper for Profile Info Row
  Widget _profileRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
