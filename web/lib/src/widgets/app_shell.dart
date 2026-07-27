import 'package:flutter/material.dart';

import '../app.dart';
import '../models/reporte.dart';
import 'floating_chat.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.view,
    required this.onChangeView,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.language,
    required this.onLanguageChange,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.detailPane,
    required this.child,
    this.userName = '',
    this.userRol = '',
    this.reportes = const [],
    this.onChatMessage,
  });

  final AppView view;
  final ValueChanged<AppView> onChangeView;
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final String language;
  final ValueChanged<String> onLanguageChange;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Widget? detailPane;
  final Widget child;
  final String userName;
  final String userRol;
  final List<Reporte> reportes;
  final Future<String?> Function(String mensaje)? onChatMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Sidebar personalizado
                _Sidebar(
                  view: view,
                  onChangeView: onChangeView,
                  sidebarCollapsed: sidebarCollapsed,
                  onToggleSidebar: onToggleSidebar,
                  onLogout: onLogout,
                  userName: userName,
                  userRol: userRol,
                ),
                // Contenido principal
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      Material(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Colmena Ambiental', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Panel comunitario de denuncias y seguimiento', style: textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // TODO(i18n): Implementar internacionalización con flutter_localizations
                              // y archivos .arb antes de habilitar este selector.
                              DropdownButton<String>(
                                value: language,
                                underline: const SizedBox.shrink(),
                                focusColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                onChanged: (value) {
                                  if (value != null) {
                                    onLanguageChange(value);
                                    // Quitar foco del dropdown después de seleccionar
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(value: 'es', child: Text('Español')),
                                  DropdownMenuItem(value: 'en', child: Text('English')),
                                  DropdownMenuItem(value: 'qu', child: Text('Quechua')),
                                ],
                              ),
                              const SizedBox(width: 12),
                              FilledButton.tonalIcon(
                                onPressed: onToggleTheme,
                                icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                                label: Text(themeMode == ThemeMode.light ? 'Claro' : 'Oscuro'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Cuerpo
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: detailPane != null
                              ? detailPane
                              : child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Chat flotante
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingChat(reportes: reportes, onSendMessage: onChatMessage),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar customizado que evita los problemas de layout de NavigationRail
/// con widgets complejos en leading/trailing.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.view,
    required this.onChangeView,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.onLogout,
    this.userName = '',
    this.userRol = '',
  });

  final AppView view;
  final ValueChanged<AppView> onChangeView;
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final VoidCallback onLogout;
  final String userName;
  final String userRol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final railWidth = sidebarCollapsed ? 72.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: railWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          // Logo y toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: sidebarCollapsed
                ? Column(
                    children: [
                      IconButton(
                        onPressed: onToggleSidebar,
                        icon: const Icon(Icons.menu),
                        tooltip: 'Expandir menú',
                      ),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primary,
                        child: Text('C', style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primary,
                        child: Text('C', style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Colmena', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            Text('Monitoreo', style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onToggleSidebar,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Colapsar menú',
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // Navegación
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
            selected: view == AppView.dashboard,
            collapsed: sidebarCollapsed,
            onTap: () => onChangeView(AppView.dashboard),
          ),
          _NavItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            label: 'Historial',
            selected: view == AppView.historial,
            collapsed: sidebarCollapsed,
            onTap: () => onChangeView(AppView.historial),
          ),
          _NavItem(
            icon: Icons.warning_amber_outlined,
            selectedIcon: Icons.warning,
            label: 'Alertas',
            selected: view == AppView.alertas,
            collapsed: sidebarCollapsed,
            onTap: () => onChangeView(AppView.alertas),
          ),

          const Spacer(),

          // Usuario y logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                if (!sidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showProfileDialog(context, userName, userRol, colorScheme, textTheme),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.isNotEmpty ? userName : 'Usuario',
                                  style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userRol.isNotEmpty ? userRol : 'En línea',
                                  style: textTheme.bodySmall?.copyWith(color: Colors.green, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => _showProfileDialog(context, userName, userRol, colorScheme, textTheme),
                    icon: CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.primary),
                      ),
                    ),
                    tooltip: 'Mi perfil',
                  ),
                SizedBox(
                  width: double.infinity,
                  child: sidebarCollapsed
                      ? IconButton(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout, size: 20),
                          tooltip: 'Cerrar sesión',
                        )
                      : TextButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Cerrar sesión'),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 12,
            ),
            child: collapsed
                ? Center(
                    child: Icon(
                      selected ? selectedIcon : icon,
                      color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

void _showProfileDialog(BuildContext context, String userName, String userRol, ColorScheme colorScheme, TextTheme textTheme) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName.isNotEmpty ? userName : 'Usuario',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userRol.isNotEmpty ? userRol : 'Sin rol',
                  style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Estado: En línea', style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.security, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Sesión activa', style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
