import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onRegister, required this.onGoToLogin, this.errorMessage});

  final Future<void> Function(String nombre, String correo, String contrasena, String rol) onRegister;
  final VoidCallback onGoToLogin;
  final String? errorMessage;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _selectedRole = 'ANALISTA';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.onRegister(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _selectedRole,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 860;

    return Scaffold(
      backgroundColor: const Color(0xFF1B2B1B),
      body: Row(
        children: [
          // Panel izquierdo - branding
          if (isWide)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B2B1B), Color(0xFF2D4A2D), Color(0xFF1A3A2A)],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.group_add_outlined, size: 48, color: Color(0xFF81C784)),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Únete a Colmena',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Forma parte de la red comunitaria\nde monitoreo ambiental',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 40),
                        _BenefitCard(icon: Icons.shield_outlined, title: 'Protege tu comunidad', subtitle: 'Reporta de forma segura'),
                        const SizedBox(height: 12),
                        _BenefitCard(icon: Icons.visibility_outlined, title: 'Monitoreo continuo', subtitle: 'Accede al mapa y alertas'),
                        const SizedBox(height: 12),
                        _BenefitCard(icon: Icons.lock_outlined, title: 'Anonimato garantizado', subtitle: 'Tu identidad protegida'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Panel derecho - formulario
          Expanded(
            flex: 4,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isWide) ...[
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.hive_outlined, size: 44, color: theme.colorScheme.primary),
                                  const SizedBox(height: 6),
                                  Text('Colmena', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          Text('Crear cuenta', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            'Completa tus datos para registrarte',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),

                          const SizedBox(height: 24),

                          // Error
                          if (widget.errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(widget.errorMessage!, style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Nombre
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(theme, 'Nombre completo', 'Juan Pérez', Icons.person_outlined),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(theme, 'Correo electrónico', 'tu@correo.com', Icons.email_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                              if (!v.contains('@')) return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Rol
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: _inputDecoration(theme, 'Rol', '', Icons.badge_outlined),
                            items: const [
                              DropdownMenuItem(value: 'ANALISTA', child: Text('Analista')),
                              DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                            ],
                            onChanged: (v) { if (v != null) setState(() => _selectedRole = v); },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(theme, 'Contraseña', '••••••••', Icons.lock_outlined).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                              if (v.length < 8) return 'Mínimo 8 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: _inputDecoration(theme, 'Confirmar contraseña', '••••••••', Icons.lock_outlined).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                              if (v != _passwordController.text) return 'No coinciden';
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Crear cuenta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('¿Ya tienes cuenta?', style: theme.textTheme.bodyMedium),
                                TextButton(onPressed: widget.onGoToLogin, child: const Text('Iniciar sesión')),
                              ],
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF81C784), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
