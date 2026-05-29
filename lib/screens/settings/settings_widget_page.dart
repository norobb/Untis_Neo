part of '../../main.dart';

class SettingsWidgetPage extends StatefulWidget {
  const SettingsWidgetPage({super.key});

  @override
  State<SettingsWidgetPage> createState() => _SettingsWidgetPageState();
}

class _SettingsWidgetPageState extends State<SettingsWidgetPage> {
  Color _bgColor = const Color(0xFFE5E5E5);
  Color _textColor = const Color(0xFF000000);
  Color _secTextColor = const Color(0xFF555555);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    final bgStr = prefs.getString('widget_bg_color') ?? '#E5E5E5';
    final txtStr = prefs.getString('widget_text_color') ?? '#000000';
    final secStr = prefs.getString('widget_sec_text_color') ?? '#555555';
    
    setState(() {
      _bgColor = _colorFromHex(bgStr) ?? const Color(0xFFE5E5E5);
      _textColor = _colorFromHex(txtStr) ?? const Color(0xFF000000);
      _secTextColor = _colorFromHex(secStr) ?? const Color(0xFF555555);
    });
  }

  Color? _colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      return Color(int.parse('0x$hex'));
    }
    return null;
  }

  String _hexFromColor(Color color) {
    return '#${color.a.toInt().toRadixString(16).padLeft(2, '0')}${color.r.toInt().toRadixString(16).padLeft(2, '0')}${color.g.toInt().toRadixString(16).padLeft(2, '0')}${color.b.toInt().toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  Future<void> _saveColor(String key, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final hex = _hexFromColor(color);
    await prefs.setString(key, hex);
    
    // Also update widget immediately
    await HomeWidget.saveWidgetData<String>(key, hex);
    await HomeWidget.updateWidget(name: 'TimetableWidgetProvider');
  }

  void _showColorPicker(String title, Color currentColor, Function(Color) onSelect) {
    // A simple sheet with preset colors to avoid complex color picker dependency
    final presets = [
      Colors.white,
      Colors.black,
      Colors.transparent,
      Colors.grey.shade800,
      Colors.grey.shade200,
      Colors.blue.shade900,
      Colors.red.shade900,
      Colors.green.shade900,
      const Color(0x88000000), // Semi-transparent black
      const Color(0x88FFFFFF), // Semi-transparent white
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presets.map((c) => GestureDetector(
                onTap: () {
                  onSelect(c);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text('Widget Anpassen', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: Column(
                children: [
                  ListTile(
                    title: Text('Hintergrundfarbe', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    trailing: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: _bgColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
                    ),
                    onTap: () => _showColorPicker('Hintergrundfarbe wählen', _bgColor, (c) {
                      setState(() => _bgColor = c);
                      _saveColor('widget_bg_color', c);
                    }),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('Haupttext (Fach & Zeit)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    trailing: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: _textColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
                    ),
                    onTap: () => _showColorPicker('Textfarbe wählen', _textColor, (c) {
                      setState(() => _textColor = c);
                      _saveColor('widget_text_color', c);
                    }),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('Nebentext (Raum & Titel)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    trailing: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: _secTextColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
                    ),
                    onTap: () => _showColorPicker('Nebentextfarbe wählen', _secTextColor, (c) {
                      setState(() => _secTextColor = c);
                      _saveColor('widget_sec_text_color', c);
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Vorschau:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nächste Stunde', style: TextStyle(color: _secTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Mathematik', style: TextStyle(color: _textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('08:00 - 08:45', style: TextStyle(color: _textColor, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Raum: R101', style: TextStyle(color: _secTextColor, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
