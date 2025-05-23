import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class EditStationScreen extends StatefulWidget {
  final String stationId;
  const EditStationScreen({super.key, required this.stationId});

  @override
  State<EditStationScreen> createState() => _EditStationScreenState();
}

class _EditStationScreenState extends State<EditStationScreen> {
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
  String? _currentLogoUrl;
  LatLng? _selectedLatLng;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Card image variables
  File? _cardImage;
  bool _isUploadingCardImage = false;
  String? _uploadedCardImageUrl;
  String? _existingCardImageUrl;

  static const LatLng _initPosition = LatLng(7.0, 80.0);

  @override
  void initState() {
    super.initState();
    _loadStation();
  }

  Future<void> _loadStation() async {
    final doc = await FirebaseFirestore.instance.collection('stations').doc(widget.stationId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _existingCardImageUrl = data['cardImageUrl'] ?? null;
        _nameController.text = data['name'] ?? '';
        _ownerController.text = data['owner'] ?? '';
        _addressController.text = data['address'] ?? '';
        _contactController.text = data['contactNumber'] ?? '';
        _gmailController.text = data['gmail'] ?? '';
        _slots2xController.text = data['slots2x']?.toString() ?? '';
        _slots1xController.text = data['slots1x']?.toString() ?? '';
        _priceController.text = data['pricePerHour']?.toString() ?? '';
        _currentLogoUrl = data['logoUrl'] ?? '';
        _selectedLatLng = LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
        if (data['openingHours'] != null) {
          final times = (data['openingHours'] as String).split(' - ');
          if (times.length == 2) {
            _openTime = _parseTimeOfDay(times[0]);
            _closeTime = _parseTimeOfDay(times[1]);
          }
        }
        _isLoadingData = false;
      });
    } else {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final format = DateFormat.jm();
      final dt = format.parse(str);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      return null;
    }
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

  Future<String?> _uploadImage(File image) async {
    final fileName = 'station_logos/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text}.png';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // Card image picker & uploader
  Future<void> _pickCardImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _cardImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadCardImage(String stationId) async {
    if (_cardImage == null) return null;
    setState(() => _isUploadingCardImage = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('station_card_images/$stationId.jpg');
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

  Future<void> _updateStation() async {
    if (!_formKey.currentState!.validate() || _selectedLatLng == null || _openTime == null || _closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields including location and opening hours.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      String imageUrl = _currentLogoUrl ?? "";
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!) ?? "";
      }

      String openingHours = "${_formatTimeOfDay(_openTime!)} - ${_formatTimeOfDay(_closeTime!)}";

      String? cardImageUrl;
      if (_cardImage != null) {
        cardImageUrl = await _uploadCardImage(widget.stationId);
      }

      Map<String, dynamic> updateData = {
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
      };
      if (cardImageUrl != null) {
        updateData['cardImageUrl'] = cardImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('stations')
          .doc(widget.stationId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Station updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update station: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
    final double avatarRadius = 56;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Charging Station'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // ========= Station Logo ==========
                    const Text(
                      "Edit Station Logo",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty
                                    ? NetworkImage(_currentLogoUrl!)
                                    : const AssetImage('assets/station_icon.png') as ImageProvider),
                            child: _selectedImage == null && (_currentLogoUrl == null || _currentLogoUrl!.isEmpty)
                                ? Icon(Icons.ev_station, size: 40, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ========= Station Card Image ==========
                    const Text(
                      "Edit Station Card Image",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 220,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                              image: _cardImage != null
                                  ? DecorationImage(
                                      image: FileImage(_cardImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_existingCardImageUrl != null && _existingCardImageUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(_existingCardImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (_cardImage == null && (_existingCardImageUrl == null || _existingCardImageUrl!.isEmpty))
                                ? Icon(Icons.image, size: 50, color: Colors.grey[400])
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
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingCardImage
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ... Other fields (text fields, map, slots, etc)
                    _buildTextField(_nameController, 'Station Name', TextInputType.text),
                    const SizedBox(height: 14),
                    _buildTextField(_ownerController, 'Owner\'s Name', TextInputType.text),
                    const SizedBox(height: 14),
                    _buildTextField(_addressController, 'Address', TextInputType.streetAddress),
                    const SizedBox(height: 14),
                    Text('Station Location:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            markers: _selectedLatLng == null
                                ? {}
                                : {
                                    Marker(
                                      markerId: const MarkerId('station_location'),
                                      position: _selectedLatLng!,
                                    ),
                                  },
                            onTap: (latLng) => setState(() => _selectedLatLng = latLng),
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(_contactController, 'Contact Number', TextInputType.phone),
                    const SizedBox(height: 14),
                    _buildTextField(_gmailController, 'Gmail', TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(_slots2xController, '2x Speed Slots', TextInputType.number,
                              validator: (v) => _validateInt(v, '2x Speed Slots')),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(_slots1xController, '1x Speed Slots', TextInputType.number,
                              validator: (v) => _validateInt(v, '1x Speed Slots')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickOpenTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_openTime == null
                                ? "Open Time"
                                : _formatTimeOfDay(_openTime!)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickCloseTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_closeTime == null
                                ? "Close Time"
                                : _formatTimeOfDay(_closeTime!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(_priceController, 'Price per hour (e.g. 500)', TextInputType.number,
                        validator: (v) => _validateDouble(v, 'Price')),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isUploadingCardImage) ? null : _updateStation,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Update Station', style: TextStyle(fontWeight: FontWeight.bold)),
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
      validator: validator ?? (value) => value == null || value.trim().isEmpty ? 'Required' : null,
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
