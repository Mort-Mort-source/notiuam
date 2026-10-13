import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            _emailCtrl.text.trim(),
            _passCtrl.text,
            _nameCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.transparent,
        foregroundColor: NotiuamColors.charcoal,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Bienvenido a NotiUAM',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: NotiuamColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Regístrate para empezar a comunicarte',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),

                    // ----- Nombre -----
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Nombre muy corto'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ----- Correo (unico) -----
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional',
                        hintText: 'nombre@cua.uam.mx',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        final email = v.trim().toLowerCase();
                        if (!email.endsWith('@cua.uam.mx')) {
                          return 'Solo se permiten correos @cua.uam.mx';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ----- Contrasena -----
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña (mínimo 8 caracteres)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Mínimo 8 caracteres'
                          : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: NotiuamColors.danger)),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Registrarme'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}