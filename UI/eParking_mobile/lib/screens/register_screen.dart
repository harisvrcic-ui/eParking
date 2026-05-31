import 'package:flutter/material.dart';



import '../l10n/app_strings.dart';

import '../l10n/locale_controller.dart';

import '../models/lookup_item.dart';

import '../services/auth_service.dart';

import '../services/lookup_service.dart';

import '../utils/input_validators.dart';

import '../widgets/form_field_controls.dart';

import '../widgets/language_switcher.dart';

import 'login_screen.dart';

import 'main_shell.dart';



class RegisterScreen extends StatefulWidget {

  const RegisterScreen({super.key});



  @override

  State<RegisterScreen> createState() => _RegisterScreenState();

}



class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();

  final _lookupService = LookupService();



  final _usernameController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  final _firstNameController = TextEditingController();

  final _lastNameController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();



  List<LookupItem> _genders = [];

  List<LookupItem> _cities = [];

  int? _genderId;

  int? _cityId;



  bool _loadingLookups = true;

  bool _isSubmitting = false;

  bool _obscurePassword = true;

  bool _obscureConfirm = true;

  String? _errorMessage;



  @override

  void initState() {

    super.initState();

    _loadLookups();

  }



  @override

  void dispose() {

    _usernameController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    _firstNameController.dispose();

    _lastNameController.dispose();

    _emailController.dispose();

    _phoneController.dispose();

    super.dispose();

  }



  Future<void> _loadLookups() async {

    try {

      final results = await Future.wait([

        _lookupService.getGenders(),

        _lookupService.getCities(),

      ]);

      if (mounted) {

        setState(() {

          _genders = results[0];

          _cities = results[1];

          _loadingLookups = false;

        });

      }

    } catch (_) {

      if (mounted) setState(() => _loadingLookups = false);

    }

  }



  Future<void> _register() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() {

      _isSubmitting = true;

      _errorMessage = null;

    });



    try {

      final user = await _authService.register(

        username: _usernameController.text.trim(),

        password: _passwordController.text,

        firstName: _firstNameController.text.trim(),

        lastName: _lastNameController.text.trim(),

        email: _emailController.text.trim(),

        phoneNumber: _phoneController.text.trim().isEmpty

            ? null

            : _phoneController.text.trim(),

        genderId: _genderId,

        cityId: _cityId,

      );



      if (!user.isUser && !user.isAdmin) {

        throw Exception(AppStrings.current.noMobileAccess);

      }



      if (!mounted) return;



      Navigator.of(context).pushAndRemoveUntil(

        MaterialPageRoute(builder: (_) => MainShell(user: user)),

        (_) => false,

      );

    } catch (e) {

      setState(() {

        _errorMessage = e.toString().replaceFirst('Exception: ', '');

      });

    } finally {

      if (mounted) setState(() => _isSubmitting = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return ListenableBuilder(

      listenable: LocaleController.instance,

      builder: (context, _) {

        final s = context.s;

        return Scaffold(

          appBar: AppBar(title: Text(s.registerTitle)),

          body: SafeArea(

            child: _loadingLookups

                ? const Center(child: CircularProgressIndicator())

                : SingleChildScrollView(

                    padding: const EdgeInsets.all(24),

                    child: Form(

                      key: _formKey,

                      autovalidateMode: AutovalidateMode.disabled,

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [

                          const LanguageSwitcher(),

                          const SizedBox(height: 16),

                          Text(

                            s.registerSubtitle,

                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                                  color: Colors.grey.shade700,

                                ),

                          ),

                          const SizedBox(height: 20),

                          TextFormField(

                            controller: _usernameController,

                            decoration: InputDecoration(

                              labelText: s.username,

                              prefixIcon: const Icon(Icons.person_outline),

                              border: const OutlineInputBorder(),

                              helperText: 'Najmanje 3 znaka, bez razmaka.',

                            ),

                            validator: (v) => InputValidators.username(v, s),

                          ),

                          const SizedBox(height: 12),

                          TextFormField(

                            controller: _firstNameController,

                            decoration: InputDecoration(

                              labelText: s.firstName,

                              border: const OutlineInputBorder(),

                            ),

                            validator: (v) =>

                                InputValidators.text(v, s.firstName, s, minLength: 2),

                          ),

                          const SizedBox(height: 12),

                          TextFormField(

                            controller: _lastNameController,

                            decoration: InputDecoration(

                              labelText: s.lastName,

                              border: const OutlineInputBorder(),

                            ),

                            validator: (v) =>

                                InputValidators.text(v, s.lastName, s, minLength: 2),

                          ),

                          const SizedBox(height: 12),

                          TextFormField(

                            controller: _emailController,

                            decoration: const InputDecoration(

                              labelText: 'Email',

                              border: OutlineInputBorder(),

                            ),

                            keyboardType: TextInputType.emailAddress,

                            validator: (v) => InputValidators.email(v, s),

                          ),

                          const SizedBox(height: 12),

                          if (_genders.isNotEmpty)

                            FormLookupDropdown(

                              label: s.gender,

                              value: _genderId,

                              items: _genders,

                              onChanged: (id) => setState(() => _genderId = id),

                            ),

                          if (_genders.isNotEmpty) const SizedBox(height: 12),

                          if (_cities.isNotEmpty)

                            FormLookupDropdown(

                              label: s.city,

                              value: _cityId,

                              items: _cities,

                              onChanged: (id) => setState(() => _cityId = id),

                            ),

                          if (_cities.isNotEmpty) const SizedBox(height: 12),

                          TextFormField(

                            controller: _phoneController,

                            decoration: InputDecoration(

                              labelText: s.phone,

                              border: const OutlineInputBorder(),

                              helperText: 'Opcionalno.',

                            ),

                            keyboardType: TextInputType.phone,

                            validator: (v) => InputValidators.phone(v, s),

                          ),

                          const SizedBox(height: 12),

                          TextFormField(

                            controller: _passwordController,

                            obscureText: _obscurePassword,

                            decoration: InputDecoration(

                              labelText: s.password,

                              prefixIcon: const Icon(Icons.lock_outline),

                              border: const OutlineInputBorder(),

                              helperText: s.validationPasswordMin(6),

                              suffixIcon: IconButton(

                                icon: Icon(

                                  _obscurePassword

                                      ? Icons.visibility_outlined

                                      : Icons.visibility_off_outlined,

                                ),

                                onPressed: () =>

                                    setState(() => _obscurePassword = !_obscurePassword),

                              ),

                            ),

                            validator: (v) => InputValidators.passwordNew(v, s),

                          ),

                          const SizedBox(height: 12),

                          TextFormField(

                            controller: _confirmPasswordController,

                            obscureText: _obscureConfirm,

                            decoration: InputDecoration(

                              labelText: s.confirmPassword,

                              border: const OutlineInputBorder(),

                              suffixIcon: IconButton(

                                icon: Icon(

                                  _obscureConfirm

                                      ? Icons.visibility_outlined

                                      : Icons.visibility_off_outlined,

                                ),

                                onPressed: () =>

                                    setState(() => _obscureConfirm = !_obscureConfirm),

                              ),

                            ),

                            validator: (v) => InputValidators.passwordConfirm(

                              v,

                              _passwordController.text,

                              s,

                            ),

                          ),

                          if (_errorMessage != null) ...[

                            const SizedBox(height: 16),

                            Text(

                              _errorMessage!,

                              style: TextStyle(color: Theme.of(context).colorScheme.error),

                              textAlign: TextAlign.center,

                            ),

                          ],

                          const SizedBox(height: 24),

                          FilledButton(

                            onPressed: _isSubmitting ? null : _register,

                            child: Padding(

                              padding: const EdgeInsets.symmetric(vertical: 4),

                              child: _isSubmitting

                                  ? const SizedBox(

                                      height: 20,

                                      width: 20,

                                      child: CircularProgressIndicator(strokeWidth: 2),

                                    )

                                  : Text(s.createAccount),

                            ),

                          ),

                          const SizedBox(height: 16),

                          Row(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              Text(s.alreadyHaveAccount),

                              TextButton(

                                onPressed: () {

                                  Navigator.of(context).pushReplacement(

                                    MaterialPageRoute(

                                      builder: (_) => const LoginScreen(),

                                    ),

                                  );

                                },

                                child: Text(s.signInInstead),

                              ),

                            ],

                          ),

                        ],

                      ),

                    ),

                  ),

          ),

        );

      },

    );

  }

}


