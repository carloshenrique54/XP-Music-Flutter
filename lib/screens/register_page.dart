import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'main_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _cpf = TextEditingController();
  final _cep = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _cpf.dispose();
    _cep.dispose();
    super.dispose();
  }

  Future<bool> _validateCEP(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) return false;

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) {
          return false;
        }
        return true;
      }
    } catch (_) {
      return true;
    }
    return false;
  }

  Future<void> _register() async {
    if (_nome.text.trim().isEmpty || _email.text.trim().isEmpty || _senha.text.trim().isEmpty) {
      _snack('Preencha nome, email e senha');
      return;
    }

    if (_cep.text.isNotEmpty) {
      setState(() => _loading = true);
      final isValid = await _validateCEP(_cep.text);
      if (!isValid) {
        setState(() => _loading = false);
        _snack('CEP inválido ou não encontrado!');
        return;
      }
    }

    setState(() => _loading = true);

    // Verifica se o e-mail já está cadastrado
    final emailExists = await AuthService.checkEmailExists(_email.text.trim());
    if (emailExists) {
      setState(() => _loading = false);
      _snack('Este e-mail já está cadastrado.');
      return;
    }

    try {
      await AuthService.register(
        email: _email.text.trim(),
        senha: _senha.text,
        nome: _nome.text.trim(),
        cpf: _cpf.text.trim(),
        cep: _cep.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF140826),
          content: Text('Conta criada com sucesso!', style: TextStyle(color: Colors.white)),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('User already exists') || errorMsg.contains('already registered') || errorMsg.contains('Duplicado')) {
          errorMsg = 'Este e-mail já está cadastrado.';
        } else if (errorMsg.contains('invalid email') || errorMsg.contains('Format')) {
          errorMsg = 'Formato de e-mail inválido.';
        } else if (errorMsg.contains('password') || errorMsg.contains('senha')) {
          errorMsg = 'A senha deve conter pelo menos 6 caracteres.';
        }
        _snack(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF140826),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0B5A), Color(0xFF080014)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
                        ),
                      ),
                      const Text(
                        'Criar conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          controller: _nome,
                          hint: 'Nome completo',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _email,
                          hint: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _senha,
                          hint: 'Senha',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _cpf,
                          hint: 'CPF (opcional)',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _cep,
                          hint: 'CEP (opcional)',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA855F7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Criar conta',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFFA855F7), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        ),
      ),
    );
  }
}
