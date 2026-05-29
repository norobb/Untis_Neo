part of '../../main.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _serverController = TextEditingController();
  final _schoolController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogginIn = false;
  bool _manualSchoolEntry = false;
  bool _isSearching = false;
  List<SchoolSearchResult> _searchResults = [];
  Timer? _debounce;

  Future<void> _searchSchools(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse('https://mobile.webuntis.com/ms/schoolquery2');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": "1",
          "method": "searchSchool",
          "params": [{"search": query}],
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['schools'] != null) {
          final list = (data['result']['schools'] as List)
              .map((e) => SchoolSearchResult.fromJson(e))
              .toList();
          if (mounted) {
            setState(() {
              _searchResults = list;
              _isSearching = false;
            });
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchSchools(value);
    });
  }

  Future<void> _login() async {
    final server = _serverController.text.trim();
    final school = _schoolController.text.trim();
    final user = _userController.text.trim();
    final pass = _passwordController.text;

    if (server.isEmpty || school.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fülle alle Felder aus.')),
      );
      return;
    }

    setState(() => _isLogginIn = true);

    try {
      final res = await _authenticateUntis(
        user: user,
        password: pass,
        client: 'UntisPlus',
        requestId: 'multiaccount',
        useLoginKey: false,
        serverUrl: server,
        school: school,
      );

      if (res != null) {
        final Map<String, dynamic> newAcc = {
          'username': user,
          'password': pass,
          'schoolUrl': server,
          'schoolName': school,
          'loginCredentialMode': 'password',
          'sessionId': res['sessionId']?.toString() ?? '',
          'personId': (res['personId'] as num?)?.toInt() ?? 0,
          'personType': (res['personType'] as num?)?.toInt() ?? 0,
        };
        
        await switchToAccount(newAcc);
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            _buildBouncyRoute(const MainNavigationScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login fehlgeschlagen. Bitte Zugangsdaten prüfen.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogginIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          'Account hinzufügen',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!_manualSchoolEntry) ...[
              TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Schule suchen',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_searchResults.isNotEmpty)
                ..._searchResults.map((s) => Card.filled(
                  color: cs.surfaceContainerHigh,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(s.displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text(s.serverUrl, style: GoogleFonts.outfit()),
                    onTap: () {
                      setState(() {
                        _serverController.text = s.serverUrl;
                        _schoolController.text = s.loginName;
                        _manualSchoolEntry = true;
                      });
                    },
                  ),
                )),
            ] else ...[
              TextField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Server-URL',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolController,
                decoration: InputDecoration(
                  labelText: 'Schulname (Login)',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: 'Benutzername',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLogginIn ? null : _login,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLogginIn
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Login & Hinzufügen', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setState(() => _manualSchoolEntry = false),
                child: Text('Andere Schule suchen', style: GoogleFonts.outfit()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
