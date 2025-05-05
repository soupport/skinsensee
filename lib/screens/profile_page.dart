import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/routine_provider.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "User Name";
  String skinType = "Dry";
  bool isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadSkinType();
    _loadUserName(); // Load username on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoutineProvider>(context, listen: false).loadRoutine();
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'User Name'; // Default value
      _nameController.text = userName; // Update text field
    });
  }

  Future<void> _saveUserName(String newUserName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUserName);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        await _saveProfileImage(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSkinType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      skinType = prefs.getString('skin_type') ?? 'Dry';
    });
  }

  Future<void> _saveSkinType(String newSkinType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skin_type', newSkinType);
  }

  Widget _buildProfileImage() {
    if (_profileImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.file(
          File(_profileImagePath!),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF8BBD0),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Color(0xFFEC407A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);
    final skincareRoutine = routineProvider.routine;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: _buildProfileImage(),
              ),
              const SizedBox(height: 20),
              isEditingName
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink.shade100),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink.shade300, width: 2.0),
                        ),
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      cursorColor: Colors.pink[400],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.pink[300]),
                    onPressed: () {
                      setState(() {
                        userName = _nameController.text;
                        isEditingName = false;
                      });
                      _saveUserName(_nameController.text); // Save username
                    },
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[300],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.pink[300]),
                    onPressed: () {
                      setState(() {
                        isEditingName = true;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pink.shade100),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.pink.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Skin Type",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[300],
                      ),
                    ),
                    DropdownButton<String>(
                      value: skinType,
                      underline: Container(),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                      items: <String>['Dry', 'Oily', 'Combination']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: Colors.pink[300],)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            skinType = newValue;
                          });
                          _saveSkinType(newValue);
                        }
                      },
                      icon: Icon(Icons.arrow_drop_down, color: Colors.pink[300]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SkinCare Routine",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[300],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (skincareRoutine.isEmpty)
                      const Center(
                        child: Text(
                          "No products in your routine yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: skincareRoutine
                            .map((product) => _buildRoutineItem(product, routineProvider))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineItem(Product product, RoutineProvider routineProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.pink.shade50.withOpacity(0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _getImageWidget(product),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _removeProduct(product, routineProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeProduct(Product product, RoutineProvider routineProvider) async {
    try {
      if (product.id != null) {
        await routineProvider.removeFromRoutine(product.id!);
      }
    } catch (e) {
      debugPrint('Error removing product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _getImageWidget(Product product) {
    if (product.imagePath.isEmpty) {
      return Container(
        color: Colors.pink.shade50.withOpacity(0.5),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    final imageName = product.imagePath.contains('/')
        ? product.imagePath.split('/').last
        : product.imagePath;

    final assetPath = 'assets/product_images/$imageName';

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.pink.shade50.withOpacity(0.5),
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      },
    );
  }
}