import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de inicio tipo dashboard profesional.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key, required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.hive_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Colmena', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text('Monitoreo ambiental', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _ConnectionBadge(isOnline: isOnline),
              ],
            ),

            const SizedBox(height: 24),

            // Banner hero con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.water_drop_outlined, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Protege los ríos\nde tu comunidad',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sistema comunitario contra la minería ilegal en ríos. Reporta de forma segura y anónima.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cómo funciona - diseño timeline
            Text('¿Cómo funciona?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('4 pasos simples para generar un reporte', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),

            _TimelineStep(
              step: 1,
              icon: Icons.camera_alt_rounded,
              title: 'Captura evidencia',
              description: 'Toma fotos a distancia segura con GPS automático',
              color: const Color(0xFF1565C0),
              isLast: false,
            ),
            _TimelineStep(
              step: 2,
              icon: Icons.edit_note_rounded,
              title: 'Describe la actividad',
              description: 'Responde 4 preguntas rápidas sobre lo que observas',
              color: const Color(0xFFE65100),
              isLast: false,
            ),
            _TimelineStep(
              step: 3,
              icon: Icons.auto_awesome_rounded,
              title: 'Análisis inteligente',
              description: 'Mercurio estimado, normativa y nivel de riesgo',
              color: const Color(0xFF6A1B9A),
              isLast: false,
            ),
            _TimelineStep(
              step: 4,
              icon: Icons.picture_as_pdf_rounded,
              title: 'Reporte PDF oficial',
              description: 'Genera documentación formal para denuncia',
              color: const Color(0xFF2E7D32),
              isLast: true,
            ),

            const SizedBox(height: 28),

            // Alerta de seguridad
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.amber.shade50.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tu seguridad es lo primero',
                        style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber.shade900, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SafetyPoint(text: 'Mantén distancia segura de la operación'),
                  _SafetyPoint(text: 'Usa el zoom de tu cámara, no te acerques'),
                  _SafetyPoint(text: 'No te expongas a los operadores'),
                  _SafetyPoint(text: 'Si sientes peligro, aléjate inmediatamente'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Recursos institucionales
            Row(
              children: [
                Text('Recursos institucionales', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 4),
            Text('Entidades bolivianas de referencia', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),

            _InstitutionCard(
              icon: Icons.account_balance_rounded,
              title: 'AJAM',
              subtitle: 'Autoridad Jurisdiccional Administrativa Minera',
              url: 'https://www.autoridadminera.gob.bo/',
              gradientColors: const [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
            const SizedBox(height: 10),
            _InstitutionCard(
              icon: Icons.park_rounded,
              title: 'SERNAP',
              subtitle: 'Servicio Nacional de Áreas Protegidas',
              url: 'https://www.sernap.gob.bo/',
              gradientColors: const [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            const SizedBox(height: 10),
            _InstitutionCard(
              icon: Icons.people_rounded,
              title: 'Defensoría del Pueblo',
              subtitle: 'Reportar vulneración de derechos',
              url: 'https://www.defensoria.gob.bo/',
              gradientColors: const [Color(0xFFE65100), Color(0xFFF57C00)],
            ),
            const SizedBox(height: 10),
            _InstitutionCard(
              icon: Icons.gavel_rounded,
              title: 'Ley 1333',
              subtitle: 'Ley de Medio Ambiente de Bolivia',
              url: 'https://www.lexivox.org/norms/BO-L-1333.html',
              gradientColors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            ),

            const SizedBox(height: 28),

            // Dato impactante
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.water_damage_outlined, size: 36, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    '¿Sabías que...?',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 gramo de mercurio contamina hasta 10,000 litros de agua. La minería ilegal de oro en Bolivia libera toneladas de este metal tóxico cada año, afectando ríos, peces y comunidades enteras.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isOnline ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isOnline ? Colors.green : Colors.orange).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? Colors.green : Colors.orange),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isLast,
  });

  final int step;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Center(
                    child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SafetyPoint extends StatelessWidget {
  const _SafetyPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 15, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            // Si falla, intentar sin especificar modo
            try {
              await launchUrl(uri);
            } catch (_) {}
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gradientColors[0].withValues(alpha: 0.15)),
            color: gradientColors[0].withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: gradientColors[0].withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: gradientColors[0].withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios, size: 12, color: gradientColors[0]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
