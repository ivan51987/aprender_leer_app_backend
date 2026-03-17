import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _surnamesController = TextEditingController();
  final _apiService = ApiService();
  final _progressService = ProgressService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_device';
  }

  void _register() async {
    final name = _nameController.text.trim();
    final surnames = _surnamesController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa tu nombre.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceId = await _getDeviceId();
      print('RegisterScreen: Device ID capturado: $deviceId');

      final response = await _apiService.registerNino(
        nombre: name,
        apellidos: surnames,
        deviceId: deviceId,
      );
      
      print('RegisterScreen: Respuesta recibida del API');
      if (response['success'] == true && response['child'] != null) {
        final childData = response['child'];
        final int id = (childData['id'] is String) ? int.parse(childData['id']) : (childData['id'] as int);
        
        // Combine name and surnames for local storage
        final String fullName = "${childData['nombre']} ${childData['apellidos'] ?? ""}".trim();
        print('RegisterScreen: Guardando progreso local para: $fullName (ID: $id)');
        await _progressService.registerNino(id, fullName);
        
        if (!mounted) return;
        print('RegisterScreen: Navegando a HomeScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('RegisterScreen: Excepción capturada: $e');
      setState(() {
        _errorMessage = 'Error al registrar: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.face_retouching_natural,
                        size: 70,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Bienvenido!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu perfil para jugar',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre(s)',
                        hint: 'Escribe tu nombre',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      
                      // Surnames field
                      _buildTextField(
                        controller: _surnamesController,
                        label: 'Apellido(s)',
                        hint: 'Escribe tus apellidos',
                        icon: Icons.people_outline,
                      ),
                      const SizedBox(height: 24),
                      
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                        
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  '¡EMPEZAR A JUGAR!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontSize: 18),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnamesController.dispose();
    super.dispose();
  }
}
