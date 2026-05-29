part of '../../main.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  String _username = '';
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? '';
      _serverUrl = prefs.getString('schoolUrl') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsHubAccount,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsLoggedInAs,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _username.isEmpty ? '—' : _username,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    if (_serverUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _serverUrl,
                        style: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _settingsLogout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        l.settingsLogout,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.errorContainer,
                        foregroundColor: cs.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: savedAccountsNotifier,
              builder: (context, accounts, _) {
                final filteredAccounts = accounts.where((acc) => acc['username'] != _username || acc['schoolUrl'] != _serverUrl).toList();
                
                if (filteredAccounts.isEmpty) {
                  return Card.filled(
                    color: cs.surfaceContainerHigh,
                    child: ListTile(
                      leading: const Icon(Icons.person_add_alt_1_rounded),
                      title: Text(
                        'Weiteren Account hinzufügen',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildBouncyRoute(const AddAccountPage()),
                        ).then((_) => _load());
                      },
                    ),
                  );
                }

                return Card.filled(
                  color: cs.surfaceContainerHigh,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Text(
                          'Gespeicherte Accounts',
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...filteredAccounts.map((acc) {
                        return ListTile(
                          leading: const Icon(Icons.person_rounded),
                          title: Text(
                            acc['username'] ?? 'Unbekannt',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            acc['schoolUrl'] ?? '',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => removeSavedAccount(acc),
                          ),
                          onTap: () async {
                            final success = await switchToAccount(acc);
                            if (success) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account gewechselt!')),
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                _buildBouncyRoute(const MainNavigationScreen()),
                                (route) => false,
                              );
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fehler beim Login.')),
                              );
                            }
                          },
                        );
                      }),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person_add_alt_1_rounded),
                        title: Text(
                          'Neuen Account hinzufügen',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            _buildBouncyRoute(const AddAccountPage()),
                          ).then((_) => _load());
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: demoModeNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: (v) => _settingsSetDemoMode(context, v),
                    title: Text(
                      l.settingsDemoMode,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsDemoModeDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
