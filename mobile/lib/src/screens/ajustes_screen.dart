import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de ajustes con modo oscuro, información de la app y guía de seguridad.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajustes', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Apariencia
            _SectionTitle(title: 'Apariencia'),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.dark_mode_outlined,
              title: 'Modo oscuro',
              subtitle: 'Reduce el brillo para uso nocturno',
              trailing: Switch(
                value: isDarkMode,
                onChanged: onThemeChanged,
              ),
            ),

            const SizedBox(height: 24),

            // Idioma
            _SectionTitle(title: 'Idioma'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: 'es',
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.language_outlined),
                ),
                dropdownColor: theme.colorScheme.surface,
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'qu', child: Text('Quechua (Runasimi)')),
                ],
                onChanged: (value) {},
              ),
            ),

            const SizedBox(height: 24),

            // Guía de seguridad
            _SectionTitle(title: 'Guía de seguridad'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.red.shade700, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Tu seguridad es lo más importante',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SecurityTip(icon: Icons.do_not_step, text: 'No te acerques a la operación'),
                  _SecurityTip(icon: Icons.zoom_in, text: 'Usa el zoom de tu cámara'),
                  _SecurityTip(icon: Icons.visibility_off_outlined, text: 'No te expongas a los operadores'),
                  _SecurityTip(icon: Icons.photo_camera_outlined, text: 'Observa y registra solo lo visible'),
                  _SecurityTip(icon: Icons.groups_outlined, text: 'Si estás en peligro, aléjate'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Enlaces útiles
            _SectionTitle(title: 'Recursos útiles'),
            const SizedBox(height: 10),
            _LinkCard(
              icon: Icons.account_balance_outlined,
              title: 'Autoridad Minera (AJAM)',
              subtitle: 'Autoridad Jurisdiccional Administrativa Minera',
              url: 'https://www.autoridadminera.gob.bo/',
            ),
            const SizedBox(height: 8),
            _LinkCard(
              icon: Icons.park_outlined,
              title: 'SERNAP',
              subtitle: 'Servicio Nacional de Áreas Protegidas',
              url: 'https://www.sernap.gob.bo/',
            ),
            const SizedBox(height: 8),
            _LinkCard(
              icon: Icons.gavel_outlined,
              title: 'Ley 1333',
              subtitle: 'Ley de Medio Ambiente de Bolivia',
              url: 'https://www.lexivox.org/norms/BO-L-1333.html',
            ),
            const SizedBox(height: 8),
            _LinkCard(
              icon: Icons.people_outline,
              title: 'Defensoría del Pueblo',
              subtitle: 'Reportar vulneración de derechos',
              url: 'https://www.defensoria.gob.bo/',
            ),

            const SizedBox(height: 24),

            // Información de la app
            _SectionTitle(title: 'Información'),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.info_outline,
              title: 'Versión',
              subtitle: 'Colmena v1.0.0',
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.storage_outlined,
              title: 'Datos locales',
              subtitle: 'Los registros se guardan en tu dispositivo',
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.lock_outline,
              title: 'Privacidad',
              subtitle: 'Tu identidad nunca se expone. Reporta anónimamente.',
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.icon, required this.title, required this.subtitle, this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.title, required this.subtitle, required this.url});
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          try { await launchUrl(uri); } catch (_) {}
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  const _SecurityTip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}


class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
