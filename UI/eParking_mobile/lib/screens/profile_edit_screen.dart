import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/input_validators.dart';
import '../l10n/locale_controller.dart';
import '../models/lookup_item.dart';
import '../models/user_profile.dart';
import '../services/lookup_service.dart';
import '../services/user_service.dart';
import '../widgets/form_field_controls.dart';
import '../widgets/form_navigation.dart';
import '../widgets/language_switcher.dart';
import '../widgets/profile_image_helper.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _service = UserService();
  final _lookupService = LookupService();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  UserProfile? _profile;
  List<LookupItem> _genders = [];
  List<LookupItem> _cities = [];
  int? _genderId;
  int? _cityId;
  String? _existingPicture;
  String? _pendingPictureBase64;
  bool _removePicture = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _service.getMyProfile();
      final genders = await _lookupService.getGenders();
      final cities = await _lookupService.getCities();
      _profile = profile;
      _genders = genders;
      _cities = cities;
      _genderId = profile.genderId;
      _cityId = profile.cityId;
      _usernameController.text = profile.username;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phoneNumber ?? '';
      _existingPicture = profile.picture;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profile == null) return;

    final s = context.s;
    final changePassword = InputValidators.passwordChangeRequested(
      _currentPasswordController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    setState(() => _saving = true);
    try {
      await _service.updateMyProfile(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        genderId: _genderId,
        cityId: _cityId,
      );

      if (changePassword) {
        await _service.changeMyPassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.passwordChanged)),
          );
        }
      }

      if (_pendingPictureBase64 != null || _removePicture) {
        await _service.updateProfilePicture(
          _removePicture ? null : _pendingPictureBase64,
        );
        if (mounted && !changePassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.profilePhotoUpdated)),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await pickProfileImageBase64();
      if (!mounted) return;
      if (picked == null) return;
      setState(() {
        _pendingPictureBase64 = picked;
        _removePicture = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.profilePhotoSelectedHint)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.profilePhotoPickFailed)),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _pendingPictureBase64 = null;
      _removePicture = true;
    });
  }

  String? get _displayPicture {
    if (_removePicture) return null;
    if (_pendingPictureBase64 != null) return _pendingPictureBase64;
    return _existingPicture;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final s = context.s;
        return Scaffold(
          appBar: formScreenAppBar(context, title: s.editProfileTitle),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const LanguageSwitcher(),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                ProfileAvatar(
                                  picture: _displayPicture,
                                  initial: (_firstNameController.text.isNotEmpty
                                          ? _firstNameController.text[0]
                                          : _usernameController.text.isNotEmpty
                                              ? _usernameController.text[0]
                                              : '?')
                                      .toUpperCase(),
                                  radius: 52,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _saving ? null : _pickPhoto,
                                      icon: const Icon(Icons.photo_camera_outlined),
                                      label: Text(s.changeProfilePhoto),
                                    ),
                                    if (_displayPicture != null)
                                      TextButton(
                                        onPressed: _saving ? null : _removePhoto,
                                        child: Text(s.removeProfilePhoto),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: s.username,
                              helperText: 'Najmanje 3 znaka, bez razmaka.',
                            ),
                            validator: (v) => InputValidators.username(v, s),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(labelText: s.firstName),
                            validator: (v) =>
                                InputValidators.text(v, s.firstName, s, minLength: 2),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(labelText: s.lastName),
                            validator: (v) =>
                                InputValidators.text(v, s.lastName, s, minLength: 2),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              helperText: 'Format: korisnik@domena.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => InputValidators.email(v, s),
                          ),
                          const SizedBox(height: 12),
                          if (_genders.isNotEmpty)
                            FormLookupDropdown(
                              label: 'Spol',
                              value: _genderId,
                              items: _genders,
                              onChanged: (id) => setState(() => _genderId = id),
                            ),
                          if (_genders.isNotEmpty) const SizedBox(height: 12),
                          if (_cities.isNotEmpty)
                            FormLookupDropdown(
                              label: 'Grad',
                              value: _cityId,
                              items: _cities,
                              onChanged: (id) => setState(() => _cityId = id),
                            ),
                          if (_cities.isNotEmpty) const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: s.phone,
                              helperText: 'Opcionalno (npr. +387 61 123 456).',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => InputValidators.phone(v, s),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            s.changePasswordSection,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ostavite prazno ako ne mijenjate lozinku.',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              labelText: s.currentPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureCurrent = !_obscureCurrent),
                              ),
                            ),
                            validator: (v) {
                              if (!InputValidators.passwordChangeRequested(
                                v,
                                _newPasswordController.text,
                                _confirmPasswordController.text,
                              )) {
                                return null;
                              }
                              return InputValidators.passwordLogin(v, s);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              labelText: s.newPassword,
                              helperText: s.validationPasswordMin(6),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                            validator: (v) {
                              if (!InputValidators.passwordChangeRequested(
                                _currentPasswordController.text,
                                v,
                                _confirmPasswordController.text,
                              )) {
                                return null;
                              }
                              return InputValidators.passwordNew(v, s);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: s.confirmNewPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (!InputValidators.passwordChangeRequested(
                                _currentPasswordController.text,
                                _newPasswordController.text,
                                v,
                              )) {
                                return null;
                              }
                              return InputValidators.passwordConfirm(
                                v,
                                _newPasswordController.text,
                                s,
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(s.save),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
