import 'dart:convert'; // Thư viện để mã hóa ảnh
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// KHÔNG CẦN IMPORT FIREBASE STORAGE NỮA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  bool _isEditingName = false;

  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isChangingPass = false;

  bool _isLoading = false;
  File? _imageFile;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
    _currentPhotoUrl = _user?.photoURL;
  }

  // --- XỬ LÝ NÚT BACK ---
  Future<bool> _onWillPop() async {
    Navigator.pop(context, true); // Trả về true để Profile reload
    return false;
  }

  // --- 1. CHỌN ẢNH VÀ LƯU BASE64 (MIỄN PHÍ, KHÔNG CẦN STORAGE) ---
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    // QUAN TRỌNG: Phải nén ảnh thật nhỏ để lưu được vào Firestore (giới hạn 1MB)
    // imageQuality: 25 (Chất lượng thấp)
    // maxWidth: 512 (Kích thước nhỏ)
    final pickedFile = await picker.pickImage(source: source, imageQuality: 25, maxWidth: 512);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isLoading = true;
      });

      try {
        // 1. Đọc file ảnh thành các byte dữ liệu
        final bytes = await _imageFile!.readAsBytes();

        // 2. Mã hóa các byte này thành chuỗi ký tự (Base64)
        String base64Image = base64Encode(bytes);

        // 3. Cập nhật chuỗi này vào Firestore (field: photoUrl)
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'photoUrl': base64Image,
        });

        // (Lưu ý: Ta không update vào Auth.currentUser.updatePhotoURL vì chuỗi này quá dài,
        // Auth thường chỉ chứa link ngắn. Ta chỉ lưu vào Firestore để hiển thị).

        setState(() {
          _currentPhotoUrl = base64Image;
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu ảnh thành công!")));

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi lưu ảnh: $e"), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. ĐỔI TÊN ---
  Future<void> _updateName() async {
    String newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _user!.updateDisplayName(newName);
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'displayName': newName,
      });
      await _user!.reload();

      setState(() => _isEditingName = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đổi tên thành công!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. MENU CHỌN ẢNH ---
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Chọn từ thư viện ảnh'),
                onTap: () { Navigator.pop(ctx); _pickAndUploadImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Chụp ảnh mới'),
                onTap: () { Navigator.pop(ctx); _pickAndUploadImage(ImageSource.camera); },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. ĐỔI MẬT KHẨU ---
  Future<void> _changePassword() async {
    String oldPass = _oldPassController.text;
    String newPass = _newPassController.text;
    String confirmPass = _confirmPassController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin"))); return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu xác nhận không khớp"), backgroundColor: Colors.red)); return;
    }

    setState(() => _isLoading = true);
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: _user!.email!, password: oldPass);
      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPass);

      _oldPassController.clear(); _newPassController.clear(); _confirmPassController.clear();
      setState(() => _isChangingPass = false);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green));
    } catch (e) {
      String msg = "Lỗi: $e";
      if (e.toString().contains('wrong-password')) msg = "Mật khẩu cũ không chính xác!";
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- HÀM HỖ TRỢ HIỂN THỊ ẢNH (FILE HOẶC BASE64) ---
  ImageProvider? _getDisplayImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!); // Ảnh vừa chọn từ máy
    }
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      try {
        // Nếu chuỗi dài (Base64) -> Giải mã
        return MemoryImage(base64Decode(_currentPhotoUrl!));
      } catch (e) {
        return null; // Lỗi giải mã
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Cài đặt ứng dụng"),
          centerTitle: true,
          // Xử lý nút Back trên AppBar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      // SỬ DỤNG HÀM HIỂN THỊ MỚI
                      backgroundImage: _getDisplayImage(),
                      child: (_imageFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: InkWell(
                        onTap: _isLoading ? null : () => _showImageSourceActionSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Tên hiển thị
              _buildExpandableCard(
                title: "Tên hiển thị",
                subtitle: _nameController.text.isNotEmpty ? _nameController.text : "Chưa đặt tên",
                icon: Icons.person_outline,
                isExpanded: _isEditingName,
                onTap: () => setState(() => _isEditingName = !_isEditingName),
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Nhập tên mới", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateName,
                      child: const Text("Lưu tên"),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),

              // Đổi mật khẩu
              _buildExpandableCard(
                title: "Đổi mật khẩu",
                subtitle: "Nhấn để thay đổi",
                icon: Icons.lock_outline,
                isExpanded: _isChangingPass,
                onTap: () => setState(() => _isChangingPass = !_isChangingPass),
                children: [
                  TextField(controller: _oldPassController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu cũ", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _newPassController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu mới", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: "Nhập lại mật khẩu", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
                      onPressed: _isLoading ? null : _changePassword,
                      child: const Text("Cập nhật mật khẩu"),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),

              // Dark Mode
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text("Chế độ tối (Dark Mode)", style: TextStyle(fontWeight: FontWeight.bold)),
                  secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  value: isDarkMode,
                  onChanged: (val) {
                    context.read<ThemeCubit>().toggleTheme(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCard({required String title, required String subtitle, required IconData icon, required bool isExpanded, required VoidCallback onTap, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.blue),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.edit, size: 20),
            onTap: onTap,
          ),
          if (isExpanded) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(children: children)),
        ],
      ),
    );
  }
}