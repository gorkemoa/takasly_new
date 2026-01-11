import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/account/update_user_model.dart';
import '../../theme/app_theme.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../services/analytics_service.dart';

class ProfileEditView extends StatefulWidget {
  final bool isMandatory;
  const ProfileEditView({super.key, this.isMandatory = false});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _birthday; // format: dd.MM.yyyy
  int _gender = 3; // 1- Erkek, 2- Kadın, 3- Belirtilmemiş (Default)
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  bool _showContact = true;

  File? _pickedImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<String> _months = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];
  final List<int> _years = List.generate(125, (index) => 2024 - index);

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('Profil Duzenle');
    final user = context.read<AuthViewModel>().userProfile;
    _nameController = TextEditingController(text: user?.userFirstname ?? '');
    _surnameController = TextEditingController(text: user?.userLastname ?? '');
    _emailController = TextEditingController(text: user?.userEmail ?? '');
    _phoneController = TextEditingController(text: user?.userPhone ?? '');

    // Initialize new fields
    _birthday = user?.userBirthday;
    if (_birthday != null && _birthday!.isNotEmpty) {
      try {
        final parts = _birthday!.split('.');
        if (parts.length == 3) {
          _selectedDay = int.tryParse(parts[0]);
          _selectedMonth = int.tryParse(parts[1]);
          _selectedYear = int.tryParse(parts[2]);
        }
      } catch (_) {}
    }

    // Parse gender string to int
    if (user?.userGender == "Erkek") {
      _gender = 1;
    } else if (user?.userGender == "Kadın") {
      _gender = 2;
    } else {
      _gender = 3;
    }

    _showContact = (user?.isShowContact == true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    ); // Quality 70 to reduce size
    if (image != null) {
      // Read bytes and convert to base64
      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);

      // Determine mime type (simple check, or default to jpeg/png)
      // Usually image_picker returns jpg or png.
      // User example: "data:image/png;base64,..."
      // We'll construct the data URI.
      final String extension = image.path.split('.').last.toLowerCase();
      String mimeType = "image/jpeg";
      if (extension == 'png') {
        mimeType = "image/png";
      }

      setState(() {
        _pickedImage = File(image.path);
        _base64Image = "data:$mimeType;base64,$base64String";
      });
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();

      final request = UpdateUserRequestModel(
        userFirstname: _nameController.text,
        userLastname: _surnameController.text,
        userEmail: _emailController.text,
        userPhone: _phoneController.text,
        userGender: _gender,
        userBirthday: _birthday,
        showContact: _showContact ? 1 : 0,
        profilePhoto: _base64Image, // Send base64 image if selected
      );

      await authViewModel.updateAccount(request);

      if (authViewModel.state == AuthState.success ||
          authViewModel.errorMessage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi.')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Hata oluştu'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.userProfile;

    return PopScope(
      canPop: !widget.isMandatory,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen profil bilgilerinizi kaydedin."),
            backgroundColor: AppTheme.error,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            "Profili Düzenle",
            style: AppTheme.safePoppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          leading: widget.isMandatory
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
          centerTitle: true,
        ),
        body: authViewModel.state == AuthState.busy
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Photo Edit Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                image: _pickedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_pickedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : (user?.profilePhoto != null &&
                                          user!.profilePhoto!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(user.profilePhoto!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  (_pickedImage == null &&
                                      (user?.profilePhoto == null ||
                                          user!.profilePhoto!.isEmpty))
                                  ? const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField("Ad", _nameController),
                      const SizedBox(height: 16),
                      _buildTextField("Soyad", _surnameController),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "E-posta",
                        _emailController,
                        TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Telefon",
                        _phoneController,
                        TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      // Birthday Selector
                      _buildBirthdaySelector(),
                      const SizedBox(height: 24),
                      // Gender Selector
                      _buildGenderSection(),
                      const SizedBox(height: 24),
                      // Show Contact Switch
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            "İletişim Bilgisi Görünsün",
                            style: AppTheme.safePoppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          value: _showContact,
                          onChanged: (bool value) {
                            setState(() {
                              _showContact = value;
                            });
                          },
                          activeColor: AppTheme.primary,
                        ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Kaydet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    TextInputType? type,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: AppTheme.safePoppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          textCapitalization:
              (type == TextInputType.emailAddress ||
                  type == TextInputType.phone)
              ? TextCapitalization.none
              : TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: "$label giriniz",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _updateBirthday() {
    if (_selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      final d = _selectedDay!.toString().padLeft(2, '0');
      final m = _selectedMonth!.toString().padLeft(2, '0');
      final y = _selectedYear!.toString();
      _birthday = "$d.$m.$y";
    }
  }

  Widget _buildBirthdaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            "Doğum Tarihi",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        Row(
          children: [
            // Day
            Expanded(
              flex: 2,
              child: _buildIOSStyleSelector<int>(
                value: _selectedDay,
                items: _days,
                label: "Gün",
                itemLabel: (val) => val.toString(),
                onChanged: (val) {
                  setState(() {
                    _selectedDay = val;
                    _updateBirthday();
                  });
                  // Auto-open month picker
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _openMonthPicker();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Month
            Expanded(
              flex: 3,
              child: _buildIOSStyleSelector<int>(
                value: _selectedMonth,
                items: List.generate(12, (i) => i + 1),
                label: "Ay",
                itemLabel: (val) => _months[val - 1],
                onChanged: (val) {
                  setState(() {
                    _selectedMonth = val;
                    _updateBirthday();
                  });
                  // Auto-open year picker
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _openYearPicker();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Year
            Expanded(
              flex: 3,
              child: _buildIOSStyleSelector<int>(
                value: _selectedYear,
                items: _years,
                label: "Yıl",
                itemLabel: (val) => val.toString(),
                onChanged: (val) {
                  setState(() {
                    _selectedYear = val;
                    _updateBirthday();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods for sequential opening
  void _openMonthPicker() {
    _showCustomPicker<int>(
      "Ay Seçiniz",
      List.generate(12, (i) => i + 1),
      _selectedMonth,
      (val) => _months[val - 1],
      (val) {
        setState(() {
          _selectedMonth = val;
          _updateBirthday();
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          _openYearPicker();
        });
      },
    );
  }

  void _openYearPicker() {
    _showCustomPicker<int>(
      "Yıl Seçiniz",
      _years,
      _selectedYear,
      (val) => val.toString(),
      (val) {
        setState(() {
          _selectedYear = val;
          _updateBirthday();
        });
      },
    );
  }

  Widget _buildIOSStyleSelector<T>({
    required T? value,
    required List<T> items,
    required String label,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    final bool hasValue = value != null;
    return GestureDetector(
      onTap: () => _showCustomPicker(label, items, value, itemLabel, onChanged),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hasValue
                ? AppTheme.primary.withOpacity(0.5)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? itemLabel(value as T) : label,
                style: AppTheme.safePoppins(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? AppTheme.textPrimary : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: hasValue ? AppTheme.primary : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPicker<T>(
    String label,
    List<T> items,
    T? value,
    String Function(T) itemLabel,
    void Function(T?) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Text(
                label,
                style: AppTheme.safePoppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == value;
                    return InkWell(
                      onTap: () {
                        onChanged(item);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            if (isSelected) const SizedBox(width: 8),
                            Text(
                              itemLabel(item),
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            "Cinsiyet",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        Row(
          children: [
            _buildGenderOption(1, "Erkek", Icons.male_rounded),
            const SizedBox(width: 12),
            _buildGenderOption(2, "Kadın", Icons.female_rounded),
            const SizedBox(width: 12),
            _buildGenderOption(
              3,
              "Belirtilmemiş",
              Icons.remove_circle_outline_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(int value, String label, IconData icon) {
    bool isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
