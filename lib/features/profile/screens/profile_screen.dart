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
      builder:
          (context) => AlertDialog(
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

  void _showFeedbackDialog() {
    final _feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Feedback"),
            content: TextField(
              controller: _feedbackController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Let us know your thoughts...",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final feedback = _feedbackController.text.trim();
                  if (feedback.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('feedbacks')
                          .add({
                            'uid': user.uid,
                            'feedback': feedback,
                            'created_at': DateTime.now(),
                          });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                      ),
                    );
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    children: [
                      // Profile Photo with edit icon
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: (photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/profile_placeholder.png') as ImageProvider,
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _isUploading ? null : _pickAndUploadImage,
                                borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(height: 18),
                      // Username
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
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _profileRow("Contact", contact, icon: Icons.phone),
                              const Divider(),
                              _profileRow("NIC / Passport", nic, icon: Icons.credit_card),
                              const Divider(),
                              _profileRow("Role", role, icon: Icons.security),
                              const Divider(),
                              _profileRow("Joined", createdAt, icon: Icons.calendar_today),
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
                              fontSize: 17,
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
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.info_outline, color: Colors.white),
                              label: const Text("About Us"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 8,
                              ),
                              onPressed: _showAboutUsDialog,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.feedback_outlined, color: Colors.white),
                              label: const Text("Feedback"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 8,
                              ),
                              onPressed: _showFeedbackDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // --- Company Info ---
                      Text(
                        "Developed by ECO EV Solutions Pvt Ltd\n© 2025 ECO EV App | All rights reserved",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
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
