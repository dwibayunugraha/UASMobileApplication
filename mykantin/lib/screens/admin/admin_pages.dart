import 'dart:convert'; // Untuk menggunakan jsonDecode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // Digunakan untuk Web
import 'dart:io' show File; // Digunakan untuk Mobile
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart'; // Pastikan ini diimpor


class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Makanan';
  String? _imageUrl;
  File? _imageFile;
  Uint8List? _imageData;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageData = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _imageData = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_imageData == null && _imageFile == null) return null;

    try {
      final Uri url = Uri.parse("https://api.cloudinary.com/v1_1/dovv0fdeh/image/upload");

      // Form data untuk Cloudinary API
      var request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = 'mykantin'; // Ganti dengan nama preset kamu
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _imageData ?? await _imageFile!.readAsBytes(),
        filename: DateTime.now().millisecondsSinceEpoch.toString() + '.jpg',
      ));

      final http.Response response = await http.Response.fromStream(await request.send());

      // Ganti json() menjadi jsonDecode()
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body); // Menggunakan jsonDecode
        return responseBody['secure_url']; // URL gambar yang sudah di-upload
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _addMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageData != null || _imageFile != null) {
        imageUrl = await _uploadImageToCloudinary();
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Simpan data menu ke Firebase Realtime Database
      final menuRef = FirebaseDatabase.instance.ref().child('menu_items').push();
      final menuData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'image': imageUrl,
        'rating': 0.0,
        'createdAt': ServerValue.timestamp,
      };

      await menuRef.set(menuData);

      // Reset form setelah berhasil
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
      _imageData = null;
      _selectedCategory = 'Makanan';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Menu Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter menu item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Makanan', child: Text('Makanan')),
                          DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                          DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image'),
                      ),
                      const SizedBox(height: 16),
                      if (_imageData != null)
                        Image.memory(_imageData!, height: 100, fit: BoxFit.cover)
                      else if (_imageFile != null)
                        Image.file(_imageFile!, height: 100, fit: BoxFit.cover),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _addMenuItem,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Add Menu Item'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
