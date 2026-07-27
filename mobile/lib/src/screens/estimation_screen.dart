import 'package:flutter/material.dart';

import '../models/registro.dart';

/// Pantalla de estimación: formulario corto de 4 preguntas.
/// Usa tarjetas seleccionables, botones grandes y pictogramas
/// para minimizar dependencia de texto (RF-19, RF-20).
class EstimationScreen extends StatefulWidget {
  const EstimationScreen({super.key, required this.fotos});

  final List<String> fotos;

  @override
  State<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Respuestas
  TamanoDraga? _tamanoDraga;
  TiempoOperando? _tiempoOperando;
  bool _personasVisibles = false;
  bool _motobombasVisibles = false;
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _notasController.dispose();
    _aliasController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _submit() {
    final result = {
      'fotos': widget.fotos,
      'tamanoDraga': _tamanoDraga,
      'tiempoOperando': _tiempoOperando,
      'personasVisibles': _personasVisibles,
      'motobombasVisibles': _motobombasVisibles,
      'notas': _notasController.text.trim(),
      'alias': _aliasController.text.trim(),
      'celular': _celularController.text.trim(),
    };
    Navigator.of(context).pop(result);
  }

  bool get _canContinue {
    return switch (_currentPage) {
      0 => _tamanoDraga != null,
      1 => _tiempoOperando != null,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
        title: const Text('Estimar actividad'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentPage + 1} / 5',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de progreso
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 4,
          ),

          // Páginas
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _PageTamanoDraga(
                  selected: _tamanoDraga,
                  onSelect: (value) => setState(() => _tamanoDraga = value),
                ),
                _PageTiempoOperando(
                  selected: _tiempoOperando,
                  onSelect: (value) => setState(() => _tiempoOperando = value),
                ),
                _PageIndicadores(
                  personasVisibles: _personasVisibles,
                  motobombasVisibles: _motobombasVisibles,
                  onPersonasChanged: (v) => setState(() => _personasVisibles = v),
                  onMotobombasChanged: (v) => setState(() => _motobombasVisibles = v),
                ),
                _PageNotas(controller: _notasController),
                _PageContacto(aliasController: _aliasController, celularController: _celularController),
              ],
            ),
          ),

          // Botón continuar
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton(
              onPressed: _canContinue ? _next : null,
              child: Text(_currentPage == 4 ? 'Generar reporte' : 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Página 1: Tamaño de draga
// ─────────────────────────────────────────────────────────────────────────────

class _PageTamanoDraga extends StatelessWidget {
  const _PageTamanoDraga({required this.selected, required this.onSelect});

  final TamanoDraga? selected;
  final ValueChanged<TamanoDraga> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué tamaño tiene la draga?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Selecciona el tamaño aproximado', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          _SelectableCard(
            icon: Icons.sailing_outlined,
            title: 'Pequeña',
            subtitle: 'Operación manual o artesanal',
            selected: selected == TamanoDraga.pequena,
            onTap: () => onSelect(TamanoDraga.pequena),
          ),
          const SizedBox(height: 12),
          _SelectableCard(
            icon: Icons.directions_boat_outlined,
            title: 'Mediana',
            subtitle: 'Con motor y equipo visible',
            selected: selected == TamanoDraga.mediana,
            onTap: () => onSelect(TamanoDraga.mediana),
          ),
          const SizedBox(height: 12),
          _SelectableCard(
            icon: Icons.directions_boat_filled_outlined,
            title: 'Grande',
            subtitle: 'Maquinaria pesada, múltiples equipos',
            selected: selected == TamanoDraga.grande,
            onTap: () => onSelect(TamanoDraga.grande),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Página 2: Tiempo operando
// ─────────────────────────────────────────────────────────────────────────────

class _PageTiempoOperando extends StatelessWidget {
  const _PageTiempoOperando({required this.selected, required this.onSelect});

  final TiempoOperando? selected;
  final ValueChanged<TiempoOperando> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cuánto tiempo lleva operando?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Estimación aproximada', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          _SelectableCard(
            icon: Icons.hourglass_bottom,
            title: 'Menos de 1 día',
            subtitle: 'Actividad reciente o temporal',
            selected: selected == TiempoOperando.menosUnDia,
            onTap: () => onSelect(TiempoOperando.menosUnDia),
          ),
          const SizedBox(height: 12),
          _SelectableCard(
            icon: Icons.calendar_today_outlined,
            title: 'Varios días',
            subtitle: 'Se ha visto operando antes',
            selected: selected == TiempoOperando.variosDias,
            onTap: () => onSelect(TiempoOperando.variosDias),
          ),
          const SizedBox(height: 12),
          _SelectableCard(
            icon: Icons.date_range,
            title: 'Más de una semana',
            subtitle: 'Presencia establecida en la zona',
            selected: selected == TiempoOperando.masUnaSemana,
            onTap: () => onSelect(TiempoOperando.masUnaSemana),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Página 3: Indicadores visibles
// ─────────────────────────────────────────────────────────────────────────────

class _PageIndicadores extends StatelessWidget {
  const _PageIndicadores({
    required this.personasVisibles,
    required this.motobombasVisibles,
    required this.onPersonasChanged,
    required this.onMotobombasChanged,
  });

  final bool personasVisibles;
  final bool motobombasVisibles;
  final ValueChanged<bool> onPersonasChanged;
  final ValueChanged<bool> onMotobombasChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué se observa a distancia?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Marca lo que puedas ver sin acercarte', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          _CheckboxCard(
            icon: Icons.people_outlined,
            title: 'Personas visibles',
            subtitle: 'Trabajadores o buzos en la zona',
            checked: personasVisibles,
            onChanged: onPersonasChanged,
          ),
          const SizedBox(height: 12),
          _CheckboxCard(
            icon: Icons.engineering_outlined,
            title: 'Motobombas o mangueras',
            subtitle: 'Equipos de extracción visibles',
            checked: motobombasVisibles,
            onChanged: onMotobombasChanged,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No te acerques para verificar. Solo marca lo observable a distancia segura.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
// Página 4: Notas opcionales
// ─────────────────────────────────────────────────────────────────────────────

class _PageNotas extends StatelessWidget {
  const _PageNotas({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notas adicionales', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Opcional: describe brevemente lo que observas', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Ej: Actividad sobre margen del río con remoción de sedimentos...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Este campo es opcional. Puedes dejarlo vacío y continuar.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
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
// Componentes reutilizables
// ─────────────────────────────────────────────────────────────────────────────

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxCard extends StatelessWidget {
  const _CheckboxCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: checked ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: checked ? colorScheme.primary : colorScheme.outlineVariant,
              width: checked ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: checked ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: checked ? colorScheme.primary : colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Página 5: Contacto opcional
// ─────────────────────────────────────────────────────────────────────────────

class _PageContacto extends StatelessWidget {
  const _PageContacto({required this.aliasController, required this.celularController});

  final TextEditingController aliasController;
  final TextEditingController celularController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Quieres dejar un contacto?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Opcional: por si la organización necesita más información. Si lo dejas vacío, el reporte será anónimo.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: aliasController,
            decoration: const InputDecoration(
              labelText: 'Alias o nombre',
              hintText: 'Ej: Río Claro',
              prefixIcon: Icon(Icons.person_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: celularController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Celular',
              hintText: 'Ej: 725-11445',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu identidad nunca se expone públicamente. Estos datos solo son visibles para la organización receptora.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
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
