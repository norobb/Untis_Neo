part of '../../main.dart';

class SettingsAboutUpdatesPage extends StatefulWidget {
  const SettingsAboutUpdatesPage({super.key});

  @override
  State<SettingsAboutUpdatesPage> createState() =>
      _SettingsAboutUpdatesPageState();
}

class _SettingsAboutUpdatesPageState extends State<SettingsAboutUpdatesPage> {
  bool _checking = false;
  String _updateChannel = 'stable';

  @override
  void initState() {
    super.initState();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _updateChannel = prefs.getString('update_channel') ?? 'stable';
    });
  }

  Future<void> _setChannel(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('update_channel', channel);
    setState(() {
      _updateChannel = channel;
    });
  }

  Future<void> _changeUpdateRepo() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final controller = TextEditingController(text: updateRepo);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.settingsUpdateRepo, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. norobb/Untis_Neo',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.examsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.examsSave),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('updateRepo', result);
      setState(() {
        updateRepo = result;
      });
    }
  }

  List<int> _extractVersionParts(String input) {
    final cleaned = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final matches = RegExp(r'\d+').allMatches(cleaned);
    if (matches.isEmpty) return const [0];
    return matches
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList(growable: false);
  }

  int _compareVersionStrings(String current, String latest) {
    final currentParts = _extractVersionParts(current);
    final latestParts = _extractVersionParts(latest);
    final maxLen = math.max(currentParts.length, latestParts.length);
    for (var i = 0; i < maxLen; i++) {
      final a = i < currentParts.length ? currentParts[i] : 0;
      final b = i < latestParts.length ? latestParts[i] : 0;
      if (a == b) continue;
      return a.compareTo(b);
    }
    return 0;
  }

  String? _pickReleaseAssetUrl(List<dynamic> assets) {
    String? fallback;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = (asset['name'] ?? '').toString().toLowerCase();
      final url = (asset['browser_download_url'] ?? '').toString();
      if (url.isEmpty) continue;
      fallback ??= url;
      if (name.endsWith('.apk')) return url;
    }
    return fallback;
  }

  Future<bool> _confirmInstall(AppL10n l, String latestVersion) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            l.settingsGithubUpdateFound(latestVersion),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.settingsGithubCurrentVersion}: $appVersion',
                style: GoogleFonts.outfit(),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.settingsGithubLatestVersion}: $latestVersion',
                style: GoogleFonts.outfit(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.settingsGithubInstallQuestion,
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.settingsGithubInstallLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.settingsGithubInstallNow),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _downloadAndInstallApk(String url, String version, AppL10n l) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadProgressDialog(url: url, version: version, l: l),
    );
  }

  Future<void> _checkGithubUpdate() async {
    if (_checking) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    setState(() => _checking = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.settingsGithubChecking),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final String url = _updateChannel == 'nightly'
          ? 'https://api.github.com/repos/$updateRepo/releases'
          : 'https://api.github.com/repos/$updateRepo/releases/latest';

      final resp = await http.get(
        Uri.parse(url),
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('GitHub API error ${resp.statusCode}');
      }

      final dynamic decoded = jsonDecode(resp.body);
      final Map<String, dynamic> data;

      if (_updateChannel == 'nightly') {
        if (decoded is List && decoded.isNotEmpty) {
          data = decoded.first as Map<String, dynamic>;
        } else {
          throw Exception('No releases found');
        }
      } else {
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid GitHub response');
        }
        data = decoded;
      }

      final tag = (data['tag_name'] ?? '').toString().trim();
      final htmlUrl =
          (data['html_url'] ?? 'https://github.com/$updateRepo/releases')
              .toString();
      final assets = (data['assets'] is List)
          ? data['assets'] as List<dynamic>
          : const <dynamic>[];
      final assetUrl = _pickReleaseAssetUrl(assets);
      final targetUrl = assetUrl ?? htmlUrl;
      final latestVersion = tag.isEmpty ? (data['name'] ?? '').toString() : tag;
      final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersion);
      final hasUpdate = hasComparableVersion
          ? _compareVersionStrings(appVersion, latestVersion) < 0
          : true;

      if (!hasUpdate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubNoUpdate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final confirmed = await _confirmInstall(l, latestVersion);
      if (!confirmed) return;

      if (targetUrl.toLowerCase().endsWith('.apk')) {
        await _downloadAndInstallApk(targetUrl, latestVersion, l);
      } else {
        final launched = await url_launcher.launchUrlString(
          targetUrl,
          mode: url_launcher.LaunchMode.externalApplication,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              launched
                  ? l.settingsGithubInstallPrompted
                  : l.settingsGithubOpenFailed,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsGithubCheckFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsHubUpdatesAbout,
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
              child: ListTile(
                leading: const Icon(Icons.system_update_alt_rounded),
                title: Text(
                  l.settingsGithubUpdateCheck,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsGithubUpdateCheckDesc,
                  style: GoogleFonts.outfit(),
                ),
                trailing: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.3),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: _checking ? null : _checkGithubUpdate,
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded),
                        const SizedBox(width: 16),
                        Text(
                          'Update Channel',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _updateChannel,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'stable',
                          child: Text('Stable', style: GoogleFonts.outfit()),
                        ),
                        DropdownMenuItem(
                          value: 'nightly',
                          child: Text('Nightly', style: GoogleFonts.outfit()),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) _setChannel(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.source_rounded),
                title: Text(
                  l.settingsUpdateRepo,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  updateRepo,
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.edit_rounded),
                onTap: _changeUpdateRepo,
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(
                  l.settingsGithubOpenReleasePage,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsGithubRepoLabel,
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  url_launcher.launchUrlString(
                    'https://github.com/$updateRepo/releases',
                    mode: url_launcher.LaunchMode.externalApplication,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerLow,
              child: ListTile(
                leading: const Icon(Icons.rocket_launch_outlined),
                title: Text(
                  l.appName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${l.settingsAppVersion} $appVersion (${l.settingsBuild} ${appBuildNumber.isEmpty ? '-' : appBuildNumber})',
                  style: GoogleFonts.outfit(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String version;
  final AppL10n l;
  const _DownloadProgressDialog({required this.url, required this.version, required this.l});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  bool _downloading = true;
  String _statusMessage = 'Downloading update...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/untisplus_update_${widget.version}.apk');
      final sink = file.openWrite();

      await response.stream.listen((List<int> chunk) {
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          if (mounted) {
            setState(() {
              _progress = receivedBytes / totalBytes;
            });
          }
        }
        sink.add(chunk);
      }).asFuture();

      await sink.close();

      if (mounted) {
        setState(() {
          _downloading = false;
          _statusMessage = 'Starting installation...';
        });
      }

      if (!mounted) return;
      Navigator.pop(context);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installation failed: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _statusMessage = 'Download failed.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update to ${widget.version}', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_downloading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text('${(_progress * 100).toStringAsFixed(1)}%', style: GoogleFonts.outfit()),
          ],
          Text(_statusMessage, style: GoogleFonts.outfit()),
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.outfit()),
          ),
      ],
    );
  }
}
