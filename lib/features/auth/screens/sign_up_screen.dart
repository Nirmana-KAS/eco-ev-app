import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eco_ev_app/data/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  File? _selectedImage;
  bool _isUploadingImage = false;
  // Removed unused _uploadedPhotoUrl field

  final _nicController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _uploadProfilePhoto(String uid) async {
    if (_selectedImage == null) return null;
    try {
      setState(() => _isUploadingImage = true);
      final ref = FirebaseStorage.instance.ref().child('user_photos/$uid.jpg');
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      // print('Profile photo upload error: $e');
      debugPrint('Profile photo upload error: $e');
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Create Firebase Auth user first
    final error = await AuthService.signUp(
      nic: _nicController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      contact: _contactController.text.trim(),
      password: _passwordController.text.trim(),
      photoUrl: null, // temp, we'll update below if photo is picked
    );

    if (!mounted) return;

    // 2. Upload the profile photo IF signup succeeded and photo is picked
    if (error == null && _selectedImage != null) {
      final uid = await AuthService.getCurrentUid(); // A helper to get the current user’s uid
      if (uid != null) {
        final url = await _uploadProfilePhoto(uid);
        // Update the user doc with the new photo URL
        await AuthService.updatePhotoUrl(uid, url ?? "");
      }
    }

    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful!")),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/sign-in');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          children: [
            const Text(
              "Hello! Register to get\nstarted",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF23272E),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Color(0x1A30B27C), // #30B27C with 10% opacity
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : const AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _inputField(_nicController, "NIC/Passport"),
            const SizedBox(height: 14),
            _inputField(_usernameController, "Username"),
            const SizedBox(height: 14),
            _inputField(
              _emailController,
              "Email",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _inputField(
              _contactController,
              "Contact Number",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _passwordField(
              _passwordController,
              "Password",
              _obscurePassword,
              () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            const SizedBox(height: 14),
            _passwordField(
              _confirmPasswordController,
              "Confirm password",
              _obscureConfirmPassword,
              () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF30B27C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  shadowColor: const Color(0xFF30B27C).withOpacity(0.4),
                ),
                onPressed: _isUploadingImage || _isLoading ? null : _register,
                child: (_isUploadingImage || _isLoading)
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(fontSize: 15),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/sign-in');
                  },
                  child: const Text(
                    "Login Now",
                    style: TextStyle(
                      color: Color(0xFF30B27C),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0x1A30B27C), // #30B27C with 10% opacity
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0x1A30B27C), // #30B27C with 10% opacity
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }
}
