import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _careerController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _userService = UserService();

  String _role = 'Estudiante';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; 
  bool _isLoading = false;

  // Solo letras (con acentos y ñ) y espacios. Nada de números ni símbolos.
  static final _lettersOnlyFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'));

  // Regex de correo razonablemente estricta.
  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Al menos una letra y un número, para contraseñas un poco más seguras.
  static final _passwordStrengthRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _careerController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!result.isSuccess) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'No se pudo completar el registro'),
          backgroundColor: AppColors.epnRed,
        ),
      );
      return;
    }

    try {
      final profile = UserModel(
        uid: result.uid!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        career: _careerController.text.trim(),
        role: _role,
      );
      await _userService.createUserProfile(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cuenta creada, pero no se pudo guardar el perfil: $e',
          ),
          backgroundColor: AppColors.epnRed,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Cuenta creada con éxito! Inicia sesión para continuar.'),
        backgroundColor: AppColors.epnBlue,
      ),
    );

    // Pequeña pausa para que el mensaje sea visible antes de volver al
    // login.
    await Future.delayed(const Duration(milliseconds: 900));
    await _authService.signOut();
    if (!mounted) return;
    // El AuthGate (debajo de esta pantalla, que fue empujada con push())
    // ya refleja el cierre de sesión; con pop() volvemos a mostrarlo.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.epnBgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.epnBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crear cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.epnBlue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Regístrate para acceder a Smart Campus EPN',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 28),

                // Rol: Estudiante o Visitante
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo de usuario',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Estudiante',
                      label: Text('Estudiante'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: 'Visitante',
                      label: Text('Visitante'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) {
                    setState(() => _role = selection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.epnBlue,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre: solo letras, 3-50 caracteres
                TextFormField(
                  controller: _nameController,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [_lettersOnlyFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                    counterText: '',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Ingresa tu nombre';
                    if (v.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    if (v.length > 50) {
                      return 'Máximo 50 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Correo: formato válido, máximo 100 caracteres
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 100,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    prefixIcon: Icon(Icons.email_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Ingresa tu correo';
                    if (!_emailRegex.hasMatch(v)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Carrera: solo letras, 3-60 caracteres (opcional para visitantes)
                TextFormField(
                  controller: _careerController,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [_lettersOnlyFormatter],
                  decoration: InputDecoration(
                    labelText: _role == 'Estudiante'
                        ? 'Carrera'
                        : 'Motivo de la visita (opcional)',
                    prefixIcon: const Icon(Icons.school_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (_role == 'Visitante') return null;
                    if (v.isEmpty) return 'Ingresa tu carrera';
                    if (v.length < 3) {
                      return 'Ingresa una carrera válida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña: 6-20 caracteres, letras + números
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    if (v.length > 20) return 'Máximo 20 caracteres';
                    if (!_passwordStrengthRegex.hasMatch(v)) {
                      return 'Debe incluir letras y números';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Registrarme'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}