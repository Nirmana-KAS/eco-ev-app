import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AddStationScreen extends StatefulWidget {
  const AddStationScreen({super.key});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _slots2xController = TextEditingController();
  final TextEditingController _slots1xController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  File? _selectedImage;
  File? _cardImage;
  LatLng? _selectedLatLng;
  bool _isLoading = false;
  bool _isUploadingCardImage = false;
  String? _uploadedCardImageUrl;

  // Map initial position (Sri Lanka)
  static const LatLng _initPosition = LatLng(7.0, 80.0);

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _gmailController.dispose();
    _slots2xController.dispose();
    _slots1xController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCardImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _cardImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File image) async {
    final fileName =
        'station_logos/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text}.png';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<String?> _uploadCardImage(String stationId) async {
    if (_cardImage == null) return null;
    setState(() => _isUploadingCardImage = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'station_card_images/$stationId.jpg',
      );
      await ref.putFile(_cardImage!);
      return await ref.getDownloadURL();
    } finally {
      setState(() => _isUploadingCardImage = false);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _addStation() async {
    if (!_formKey.currentState!.validate() ||
        _selectedLatLng == null ||
        _openTime == null ||
        _closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields including location and opening hours.',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Upload image
      String imageUrl = "";
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!) ?? "";
      }

      String openingHours =
          "${_formatTimeOfDay(_openTime!)} - ${_formatTimeOfDay(_closeTime!)}";

      // Add station data to Firestore
      DocumentReference stationDoc = await FirebaseFirestore.instance
          .collection('stations')
          .add({
            'name': _nameController.text.trim(),
            'owner': _ownerController.text.trim(),
            'address': _addressController.text.trim(),
            'latitude': _selectedLatLng!.latitude,
            'longitude': _selectedLatLng!.longitude,
            'contactNumber': _contactController.text.trim(),
            'gmail': _gmailController.text.trim(),
            'slots2x': int.parse(_slots2xController.text.trim()),
            'slots1x': int.parse(_slots1xController.text.trim()),
            'openingHours': openingHours,
            'pricePerHour': double.parse(_priceController.text.trim()),
            'logoUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Upload card image if available
      if (_cardImage != null) {
        String? cardImageUrl = await _uploadCardImage(stationDoc.id);
        if (cardImageUrl != null) {
          await stationDoc.update({'cardImageUrl': cardImageUrl});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Station added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add station: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _selectedLatLng = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _pickOpenTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _openTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) setState(() => _openTime = time);
  }

  Future<void> _pickCloseTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _closeTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (time != null) setState(() => _closeTime = time);
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 48;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Charging Station')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. Station Logo Picker
              Column(
                children: [
                  Text(
                    "Upload Station Logo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : null,
                          child:
                              _selectedImage == null
                                  ? const Icon(Icons.ev_station, size: 40, color: Colors.white70)
                                  : null,
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
                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 1.1 Station Card Image Picker
              Column(
                children: [
                  Text(
                    "Upload Station Card Image",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 220,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(18),
                            image: _cardImage != null
                                ? DecorationImage(
                                    image: FileImage(_cardImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _cardImage == null
                              ? const Icon(Icons.image, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: InkWell(
                            onTap: _pickCardImage,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 2. Station Name
              _buildTextField(
                _nameController,
                'Station Name',
                TextInputType.text,
              ),
              const SizedBox(height: 14),
              // 3. Station Owner's Name
              _buildTextField(
                _ownerController,
                'Owner\'s Name',
                TextInputType.text,
              ),
              const SizedBox(height: 14),
              // 4. Address
              _buildTextField(
                _addressController,
                'Address',
                TextInputType.streetAddress,
              ),
              const SizedBox(height: 14),
              // 5. Location Picker (Map)
              Text(
                'Station Location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLatLng ?? _initPosition,
                        zoom: 13,
                      ),
                      markers:
                          _selectedLatLng == null
                              ? {}
                              : {
                                Marker(
                                  markerId: const MarkerId('station_location'),
                                  position: _selectedLatLng!,
                                ),
                              },
                      onTap:
                          (latLng) => setState(() => _selectedLatLng = latLng),
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Use My Location'),
                        onPressed: _selectLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(30, 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 6. Contact Number
              _buildTextField(
                _contactController,
                'Contact Number',
                TextInputType.phone,
              ),
              const SizedBox(height: 14),
              // 7. Gmail
              _buildTextField(
                _gmailController,
                'Gmail',
                TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              // 8 & 9. Charging Slots
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _slots2xController,
                      '2x Speed Slots',
                      TextInputType.number,
                      validator: (v) => _validateInt(v, '2x Speed Slots'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      _slots1xController,
                      '1x Speed Slots',
                      TextInputType.number,
                      validator: (v) => _validateInt(v, '1x Speed Slots'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // 10. Opening Hours
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickOpenTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _openTime == null
                            ? "Open Time"
                            : _formatTimeOfDay(_openTime!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickCloseTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _closeTime == null
                            ? "Close Time"
                            : _formatTimeOfDay(_closeTime!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // 11. Price per hour
              _buildTextField(
                _priceController,
                'Price per hour (e.g. 500)',
                TextInputType.number,
                validator: (v) => _validateDouble(v, 'Price'),
              ),
              const SizedBox(height: 22),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || _isUploadingCardImage)
                          ? null
                          : _addStation,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Add Station',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType keyboardType, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _validateInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid integer for $fieldName';
    return null;
  }

  String? _validateDouble(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid number for $fieldName';
    return null;
  }
}
