import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/features/auth/data/firebase_auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Email form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isSignUpMode = false;

  // Phone form controllers
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _isCodeSent = false;
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signInWithGoogle();
      if (cred != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${cred.user?.displayName ?? cred.user?.email ?? 'Usuario'}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error con Google Sign-In: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu correo y contraseña'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isSignUpMode) {
        await repo.createUserWithEmailAndPassword(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada con éxito! Ingresando a la app...'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await repo.signInWithEmailAndPassword(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Sesión iniciada con éxito!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Error [${e.code}]: ${e.message}';

        switch (e.code) {
          case 'email-already-in-use':
            msg = 'Este correo ya está registrado. Cambia a "Iniciar Sesión" e ingresa tu contraseña.';
            break;
          case 'user-not-found':
            msg = 'No existe una cuenta con este correo. Presiona abajo en "¿No tienes cuenta? Regístrate aquí".';
            break;
          case 'wrong-password':
            msg = 'Contraseña incorrecta. Por favor verifica tu clave.';
            break;
          case 'invalid-credential':
            msg = _isSignUpMode
                ? 'El correo ya existe o la contraseña no cumple el formato.'
                : 'Correo o contraseña incorrectos. Verifica tus datos o regístrate abajo.';
            break;
          case 'invalid-email':
            msg = 'El formato del correo electrónico no es válido.';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSmsCode() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu número de teléfono (+51)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String phone = rawPhone;
    if (!phone.startsWith('+')) {
      phone = '+51$phone';
    }

    setState(() => _isSendingCode = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (cred) async {
          await repo.signInWithPhoneCredential(cred.verificationId!, cred.smsCode!);
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isSendingCode = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error SMS: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        codeSent: (vId, resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = vId;
              _isCodeSent = true;
              _isSendingCode = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código SMS enviado. Revisa tu celular.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (vId) {
          _verificationId = vId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar SMS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifySmsCode() async {
    final code = _codeController.text.trim();
    if (_verificationId == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el código SMS de 6 dígitos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithPhoneCredential(_verificationId!, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Teléfono verificado con éxito!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de confirmación incorrecto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Branding
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'JM IMPORTS',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión de Reparaciones & Venta de Repuestos',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLightGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Primary 1-Tap Action Button: Google / Gmail
                FilledButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continuar con Google (Gmail)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o ingresa con las opciones de abajo',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 20),

                // Method Selector Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryBlue,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textLightGray,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.email_rounded, size: 20),
                        text: 'Correo / Clave',
                      ),
                      Tab(
                        icon: Icon(Icons.phone_android_rounded, size: 20),
                        text: 'Teléfono SMS',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views Container
                SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Email Form
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUpMode ? 'Registro con Correo' : 'Iniciar Sesión con Correo',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.bodyLarge,
                              decoration: const InputDecoration(
                                labelText: 'Correo Electrónico',
                                hintText: 'usuario@gmail.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: AppTextStyles.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _isLoading ? null : _handleEmailAuth,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isSignUpMode ? 'Crear Cuenta' : 'Iniciar Sesión',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUpMode = !_isSignUpMode;
                                });
                              },
                              child: Text(
                                _isSignUpMode ? '¿Ya tienes cuenta? Inicia sesión aquí' : '¿No tienes cuenta? Regístrate aquí',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentLightBlue),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Phone SMS Form
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Autenticación por Teléfono (SMS)',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (!_isCodeSent) ...[
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: AppTextStyles.bodyLarge,
                                decoration: const InputDecoration(
                                  labelText: 'Número de Celular (+51)',
                                  hintText: '+51 987654321',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_android_rounded),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _isSendingCode ? null : _sendSmsCode,
                                icon: _isSendingCode
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.sms_rounded),
                                label: const Text('Enviar Código SMS'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Código enviado a ${_phoneController.text}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.headlineMedium.copyWith(letterSpacing: 4),
                                decoration: const InputDecoration(
                                  labelText: 'Código de 6 dígitos',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.pin_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _isSendingCode ? null : _verifySmsCode,
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('Verificar e Ingresar'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isCodeSent = false;
                                  });
                                },
                                child: Text(
                                  'Cambiar número de teléfono',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentLightBlue),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.accentLightBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Una vez ingreses, desbloquearás con tu Huella Digital.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
