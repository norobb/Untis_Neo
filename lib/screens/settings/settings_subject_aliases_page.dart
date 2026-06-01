part of '../../main.dart';

class SettingsSubjectAliasesPage extends StatelessWidget {
  const SettingsSubjectAliasesPage({super.key});

  void _showAliasDialog(BuildContext context, String subject, String? currentAlias) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: currentAlias ?? '');

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Alias für "$subject"',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Neuer Name',
                hintText: 'z.B. Mathematik 🧮',
                filled: true,
                fillColor: cs.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (currentAlias != null && currentAlias.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearSubjectAlias(subject);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Zurücksetzen'),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final val = controller.text.trim();
                      if (val.isEmpty) {
                        _clearSubjectAlias(subject);
                      } else {
                        _setSubjectAlias(subject, val);
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          'Fächer-Namen',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: knownSubjectsNotifier,
          builder: (context, subjectsSet, _) {
            final subjects = subjectsSet.toList()..sort();
            if (subjects.isEmpty) {
              return Center(
                child: Text(
                  'Keine Fächer geladen.',
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ValueListenableBuilder<Map<String, String>>(
              valueListenable: subjectAliasesNotifier,
              builder: (context, aliases, _) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final currentAlias = aliases[subject];

                    return Card.filled(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.8),
                      child: ListTile(
                        title: Text(
                          currentAlias?.isNotEmpty == true ? currentAlias! : subject,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        ),
                        subtitle: currentAlias?.isNotEmpty == true
                            ? Text(
                                'Original: $subject',
                                style: GoogleFonts.outfit(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: const Icon(Icons.edit_rounded, size: 20),
                        onTap: () => _showAliasDialog(context, subject, currentAlias),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
