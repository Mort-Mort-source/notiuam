import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../state/verification_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String password;
  final String displayName;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 600; // 10 minutos
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 600);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.length != 6 || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    // 1. Verificar el código en el backend
    final ok = await context
        .read<VerificationProvider>()
        .verifyCode(widget.email, _codeCtrl.text);

    if (!ok) {
      setState(() {
        _error = context.read<VerificationProvider>().error ??
            'Código incorrecto o expirado';
        _submitting = false;
      });
      return;
    }

    // 2. Si el código es válido, procedemos a registrar al usuario
    try {
      await context.read<AuthProvider>().register(
            widget.email,
            widget.password,
            widget.displayName,
          );
      // Al registrarse exitosamente, AuthProvider cambia de estado
      // y el _RootNavigator nos llevará al HomeShell automáticamente.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() {
        _error = ApiClient.extractError(e);
        _submitting = false;
      });
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    final ok = await context.read<VerificationProvider>().sendCode(widget.email);
    if (ok) {
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado a tu correo')),
        );
      }
    } else {
      setState(() => _error = 'No se pudo reenviar el código');
    }
  }

  String get _timeString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar correo'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      size: 64, color: NotiuamColors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Revisa tu correo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: NotiuamColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enviamos un código de 6 dígitos a:\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // Campo para el código
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _secondsLeft > 0
                            ? 'Expira en $_timeString'
                            : 'Código expirado',
                        style: TextStyle(
                          color: _secondsLeft > 0
                              ? Colors.grey.shade600
                              : NotiuamColors.danger,
                        ),
                      ),
                    ],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: NotiuamColors.danger)),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: (_codeCtrl.text.length == 6 && !_submitting)
                          ? _submit
                          : null,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verificar y crear cuenta'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _submitting ? null : _resend,
                    child: const Text('Reenviar código'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}