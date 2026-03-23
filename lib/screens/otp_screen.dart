import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../utils/colors.dart';
import 'dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.challenge});

  final LoginChallenge challenge;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    if (_codeCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el codigo enviado a tu correo')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = await AuthService().verifyOtp(widget.challenge.pendingToken, _codeCtrl.text.trim());
      await SessionManager.instance.saveSession(auth);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codigo incorrecto o expirado')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final contentWidth = isWide ? 460.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificacion 2FA'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppColors.bgSlate50,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresa el codigo enviado a ${widget.challenge.maskedEmail}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeCtrl,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Codigo OTP',
                        counterText: '',
                        prefixIcon: const Icon(Icons.key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'El codigo expira en ${widget.challenge.otpExpiresIn ~/ 60} minutos.',
                      style: const TextStyle(color: AppColors.textGray600),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirmar acceso',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
