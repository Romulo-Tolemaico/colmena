import 'package:flutter/material.dart';

import '../app.dart';

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1180;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: view.index,
              onDestinationSelected: (index) => onChangeView(AppView.values[index]),
              extended: !sidebarCollapsed,
              labelType: sidebarCollapsed ? NavigationRailLabelType.all : NavigationRailLabelType.none,
              minExtendedWidth: 220,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Historial')),
                NavigationRailDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning), label: Text('Alertas')),
              ],
              leading: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text('C', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        if (!sidebarCollapsed)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Colmena', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Monitoreo ambiental', style: textTheme.bodySmall),
                            ],
                          ),
                        IconButton(
                          onPressed: onToggleSidebar,
                          icon: Icon(sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!sidebarCollapsed)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: const Icon(Icons.person, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Monitor', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      Text('En línea', style: textTheme.bodySmall?.copyWith(color: Colors.green)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout),
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
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
                            onChanged: (value) {
                              if (value != null) onLanguageChange(value);
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
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isWide && detailPane != null
                          ? Row(
                              key: const ValueKey('wide-shell'),
                              children: [
                                Expanded(flex: 7, child: child),
                                Container(
                                  width: 380,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    border: Border(left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                                  ),
                                  child: detailPane,
                                ),
                              ],
                            )
                          : Stack(
                              key: const ValueKey('compact-shell'),
                              children: [
                                Positioned.fill(child: child),
                                if (detailPane != null)
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      margin: const EdgeInsets.all(16),
                                      constraints: const BoxConstraints(maxHeight: 360),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.14),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: detailPane,
                                    ),
                                  ),
                              ],
                            ),
                    ),
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
