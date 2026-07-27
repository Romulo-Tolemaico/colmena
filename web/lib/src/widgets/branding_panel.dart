import 'dart:async';
import 'package:flutter/material.dart';

/// Layout base compartido para Login y Register.
/// Fondo completo con imagen de naturaleza + overlay + branding izquierdo + card derecha.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  /// El formulario que va dentro de la card derecha.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: imagen de naturaleza
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Image.network(
              'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1920&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (ctx, err, st) => Container(color: const Color(0xFF0A1F0A)),
            ),
          ),

          // Overlay oscuro verde con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0A1F0A).withValues(alpha: 0.55),
                  const Color(0xFF0A1F0A).withValues(alpha: 0.35),
                  const Color(0xFF0A1F0A).withValues(alpha: 0.5),
                ],
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: isWide ? _WideLayout(child: child) : _NarrowLayout(child: child),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT WIDE (desktop)
// ─────────────────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panel izquierdo - branding
        const Expanded(
          flex: 5,
          child: _BrandingContent(),
        ),

        // Panel derecho - card con formulario
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: _FormCard(child: child),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT NARROW (móvil/tablet estrecho)
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: _FormCard(
          child: Column(
            children: [
              // Logo compacto arriba del form
              const _CompactLogo(),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DEL FORMULARIO
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E1A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO COMPACTO (para pantallas angostas)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactLogo extends StatelessWidget {
  const _CompactLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
          ),
          child: const Icon(Icons.hive_rounded, size: 26, color: Color(0xFF81C784)),
        ),
        const SizedBox(height: 12),
        const Text(
          'COLMENA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRANDING CONTENT (panel izquierdo)
// ─────────────────────────────────────────────────────────────────────────────

class _BrandingContent extends StatefulWidget {
  const _BrandingContent();

  @override
  State<_BrandingContent> createState() => _BrandingContentState();
}

class _BrandingContentState extends State<_BrandingContent> {
  int _currentIndex = 0;
  bool _visible = true;
  Timer? _timer;

  static const _quotes = [
    '"Ríos sanos, comunidades fuertes, futuro sostenible"',
    '"La tecnología al servicio de nuestros ecosistemas"',
    '"Juntos protegemos lo que nos da vida"',
    '"Monitoreo inteligente para un planeta mejor"',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _next());
  }

  void _next() {
    if (!mounted) return;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _quotes.length;
        _visible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + nombre
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                ),
                child: const Icon(Icons.hive_rounded, size: 28, color: Color(0xFF81C784)),
              ),
              const SizedBox(width: 16),
              const Text(
                'COLMENA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),

          const Spacer(flex: 2),

          // Título principal
          const Text(
            'Sistema comunitario de\nmonitoreo ambiental',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tecnología al servicio de nuestras comunidades\ny la protección de nuestros ríos.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 44),

          // Cards de features
          const Row(
            children: [
              Expanded(child: _PillarCard(icon: Icons.eco_outlined, title: 'Conservación', subtitle: 'Protegemos nuestros\necosistemas')),
              SizedBox(width: 12),
              Expanded(child: _PillarCard(icon: Icons.verified_outlined, title: 'Transparencia', subtitle: 'Datos confiables\npara la acción')),
              SizedBox(width: 12),
              Expanded(child: _PillarCard(icon: Icons.groups_outlined, title: 'Comunidad', subtitle: 'Juntos por un futuro\nsostenible')),
            ],
          ),

          const Spacer(flex: 3),

          // Quote animado al fondo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  ),
                  child: const Icon(Icons.format_quote_rounded, color: Color(0xFF81C784), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedOpacity(
                        opacity: _visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 350),
                        child: AnimatedSlide(
                          offset: _visible ? Offset.zero : const Offset(0, 0.1),
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            _quotes[_currentIndex],
                            style: const TextStyle(
                              color: Color(0xFFA5D6A7),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'COLMENA  |  MONITOREO AMBIENTAL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PILLAR CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
            ),
            child: Icon(icon, color: const Color(0xFF81C784), size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
