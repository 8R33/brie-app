import 'package:flutter/material.dart';

import '../services/theme_controller.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final controller = BrieThemeController.instance;

  static const Map<String, String> colourLabels = {
    'background': 'Main background',
    'surface': 'Large surfaces',
    'card': 'Cards',
    'accent': 'Buttons and accents',
    'text': 'Main text',
    'muted': 'Secondary text',
  };

  @override
  Widget build(BuildContext context) {
    final palette = controller.currentPalette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Appearance',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Make brié feel like yours',
              style: TextStyle(
                color: palette.text,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a colour theme for your personal space.',
              style: TextStyle(color: palette.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            ...controller.themeNames.map((name) {
              final option = controller.paletteFor(name);
              final selected = controller.selectedTheme == name;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await controller.selectTheme(name);
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: option.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? option.accent
                            : option.muted.withValues(alpha: 0.35),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: option.background,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                name == BrieThemeController.light
                                    ? Icons.wb_sunny_outlined
                                    : name == BrieThemeController.purple
                                    ? Icons.nightlight_round
                                    : Icons.water_drop_outlined,
                                color: option.accent,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: option.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name == BrieThemeController.light
                                        ? 'Your original light appearance'
                                        : name == BrieThemeController.purple
                                        ? 'Deep plum and soft lilac'
                                        : 'Deep ocean and sea glass',
                                    style: TextStyle(
                                      color: option.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: option.accent,
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 9,
                          children: option.colors.values.take(6).map((color) {
                            return Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: option.text.withValues(alpha: 0.2),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            _sectionTitle('Customize your colours', palette.text),
            const SizedBox(height: 6),
            Text(
              'Edit colours for the currently selected theme.',
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: colourLabels.entries.map((entry) {
                  final color = palette.colors[entry.key]!;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.text.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                      style: TextStyle(color: palette.muted),
                    ),
                    trailing: Icon(Icons.edit_outlined, color: palette.accent),
                    onTap: () => _editColour(entry.key, color),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await controller.resetCurrentPalette();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset selected theme'),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your theme and colour choices are saved on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _editColour(String key, Color original) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) => _ColourEditorDialog(
        title: colourLabels[key] ?? 'Choose colour',
        initialColor: original,
      ),
    );

    if (selected != null) {
      await controller.updateColor(key, selected);
      if (mounted) setState(() {});
    }
  }
}

class _ColourEditorDialog extends StatefulWidget {
  final String title;
  final Color initialColor;

  const _ColourEditorDialog({required this.title, required this.initialColor});

  @override
  State<_ColourEditorDialog> createState() => _ColourEditorDialogState();
}

class _ColourEditorDialogState extends State<_ColourEditorDialog> {
  late HSVColor hsv;
  late TextEditingController hexController;

  @override
  void initState() {
    super.initState();
    hsv = HSVColor.fromColor(widget.initialColor);
    hexController = TextEditingController(text: _hex(widget.initialColor));
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  void _update(HSVColor value) {
    setState(() {
      hsv = value;
      hexController.text = _hex(hsv.toColor());
    });
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = hsv.toColor();

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: hexController,
              decoration: const InputDecoration(
                labelText: 'HEX colour',
                hintText: '#FDDDEA',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final cleaned = value.trim().replaceFirst('#', '');
                if (cleaned.length == 6) {
                  final parsed = int.tryParse(cleaned, radix: 16);
                  if (parsed != null) {
                    _update(HSVColor.fromColor(Color(0xFF000000 | parsed)));
                  }
                }
              },
            ),
            const SizedBox(height: 18),
            const Align(alignment: Alignment.centerLeft, child: Text('Hue')),
            Slider(
              min: 0,
              max: 360,
              value: hsv.hue.clamp(0, 360),
              onChanged: (value) => _update(hsv.withHue(value)),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Saturation'),
            ),
            Slider(
              value: hsv.saturation,
              onChanged: (value) => _update(hsv.withSaturation(value)),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Brightness'),
            ),
            Slider(
              value: hsv.value,
              onChanged: (value) => _update(hsv.withValue(value)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, hsv.toColor()),
          child: const Text('Apply colour'),
        ),
      ],
    );
  }
}
