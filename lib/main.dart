import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // NOVÝ IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAL-v5HQ3h7lPEatfN-BN7slx8QY--6Wnw",
      authDomain: "maturitnipomocnik.firebaseapp.com",
      projectId: "maturitnipomocnik",
      storageBucket: "maturitnipomocnik.firebasestorage.app",
      messagingSenderId: "639618148005",
      appId: "1:639618148005:web:7134be3c4a83fc60a1cf4c",
      measurementId: "G-LRNYZSHC6R",
    ),
  );

  runApp(const MaturitniApp());
}

// --- DATOVÝ MODEL ---
class Otazka {
  String id;
  int cislo;
  String nazev;
  String popis;
  int progres; 
  String predmet;
  DateTime? posledniUprava;
  DateTime? naplanovanoNa;
  String odkaz; // NOVÉ POLE

  Otazka({
    required this.id,
    required this.cislo,
    this.nazev = '',
    this.popis = '',
    this.progres = 0, 
    required this.predmet,
    this.posledniUprava,
    this.naplanovanoNa,
    this.odkaz = '', // VÝCHOZÍ HODNOTA
  });

  factory Otazka.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Otazka(
      id: doc.id,
      cislo: data['cislo'] ?? 0,
      nazev: data['nazev'] ?? '',
      popis: data['popis'] ?? '',
      progres: data['progres'] ?? 0,
      predmet: data['predmet'] ?? '',
      posledniUprava: (data['lastUpdate'] as Timestamp?)?.toDate(),
      naplanovanoNa: (data['planDate'] as Timestamp?)?.toDate(),
      odkaz: data['odkaz'] ?? '', // NAČTENÍ Z FIREBASE
    );
  }
}

class MaturitniApp extends StatefulWidget {
  const MaturitniApp({super.key});

  @override
  State<MaturitniApp> createState() => _MaturitniAppState();
}

class _MaturitniAppState extends State<MaturitniApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _nactiNastaveni();
  }

  void _nactiNastaveni() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('nastaveni').doc('uzivatel_1').get();
      if (doc.exists && doc.data() != null) {
        bool isDark = doc.data()!['darkMode'] ?? false;
        setState(() {
          _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (e) {
      print("Nastavení zatím v DB není: $e");
    }
  }

  void _toggleTheme() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    await FirebaseFirestore.instance.collection('nastaveni').doc('uzivatel_1').set({
      'darkMode': _themeMode == ThemeMode.dark,
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      themeMode: _themeMode,
      home: MenuObrazovka(onThemeToggle: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

// --- HLAVNÍ MENU ---
class MenuObrazovka extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const MenuObrazovka({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<MenuObrazovka> createState() => _MenuObrazovkaState();
}

class _MenuObrazovkaState extends State<MenuObrazovka> {
  late Timer _timer;
  DateTime maturitaDatum = DateTime(2026, 5, 25, 8, 0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _vypocitejOdpocet() {
    final ted = DateTime.now();
    final rozdil = maturitaDatum.difference(ted);
    if (rozdil.isNegative) return "Maturita již probíhá!";
    return "${rozdil.inDays} dní, ${rozdil.inHours % 24} hod, ${rozdil.inMinutes % 60} min";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maturita 2026'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NastaveniObrazovka(onThemeToggle: widget.onThemeToggle, isDarkMode: widget.isDarkMode)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text("Čas do ústních maturit:", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(_vypocitejOdpocet(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 5),
                      const Text("25. 5. 2026", style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KalendarObrazovka())),
                icon: const Icon(Icons.calendar_month),
                label: const Text("Můj studijní plán", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 30),
              const Text("Předměty:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildMenuButton('Český Jazyk', Colors.redAccent, 'ČJ'),
              _buildMenuButton('Informační Technologie', Colors.blueAccent, 'IT'),
              _buildMenuButton('Ekonomika', Colors.green.shade700, 'EKO'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String nazev, Color barva, String kod) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: barva, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeznamOtazekObrazovka(predmet: kod))),
        child: Text(nazev, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// --- KALENDÁŘ OBRAZOVKA ---
class KalendarObrazovka extends StatefulWidget {
  const KalendarObrazovka({super.key});

  @override
  State<KalendarObrazovka> createState() => _KalendarObrazovkaState();
}

class _KalendarObrazovkaState extends State<KalendarObrazovka> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Studijní plán")),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDay,
            firstDate: DateTime(2024),
            lastDate: DateTime(2027),
            onDateChanged: (date) {
              setState(() => _selectedDay = date);
            },
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('otazky').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var naplanovaneOtazky = snapshot.data!.docs.map((d) => Otazka.fromFirestore(d)).where((o) {
                  return o.naplanovanoNa != null &&
                      o.naplanovanoNa!.day == _selectedDay.day &&
                      o.naplanovanoNa!.month == _selectedDay.month &&
                      o.naplanovanoNa!.year == _selectedDay.year;
                }).toList();

                if (naplanovaneOtazky.isEmpty) {
                  return const Center(child: Text("Na tento den nemáš nic naplánováno."));
                }

                return ListView.builder(
                  itemCount: naplanovaneOtazky.length,
                  itemBuilder: (context, index) {
                    final o = naplanovaneOtazky[index];
                    return ListTile(
                      leading: Icon(Icons.book, color: Theme.of(context).primaryColor),
                      title: Text("${o.predmet}: ${o.nazev}"),
                      subtitle: Text("Progres: ${o.progres}%"),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditorObrazovka(otazka: o))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- SEZNAM OTÁZEK (OPRAVENÝ) ---
class SeznamOtazekObrazovka extends StatelessWidget {
  final String predmet;
  const SeznamOtazekObrazovka({super.key, required this.predmet});

  @override
  Widget build(BuildContext context) {
    int max = predmet == 'IT' ? 25 : 20;
    return Scaffold(
      appBar: AppBar(title: Text(predmet)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('otazky').where('predmet', isEqualTo: predmet).orderBy('cislo').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: max,
            itemBuilder: (context, index) {
              int c = index + 1;
              var d = docs.where((doc) => doc['cislo'] == c);
              Otazka o = d.isNotEmpty ? Otazka.fromFirestore(d.first) : Otazka(id: '$predmet-$c', cislo: c, nazev: 'Otázka č. $c', predmet: predmet);
              
              return ListTile(
                leading: CircleAvatar(child: Text('$c')),
                title: Row(
                  children: [
                    Expanded(child: Text(o.nazev, style: const TextStyle(fontWeight: FontWeight.bold))),
                    // IKONA ODKAZU SE TEĎ UKÁŽE VEDLE NÁZVU
                    if (o.odkaz.isNotEmpty) 
                      const Icon(Icons.link, size: 18, color: Colors.blueAccent),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: o.progres / 100, 
                      color: o.progres > 70 ? Colors.green : Colors.orange
                    ),
                  ],
                ),
                // PROCENTA JSOU ZPĚT NA SVÉM MÍSTĚ VPRAVO
                trailing: Text('${o.progres}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditorObrazovka(otazka: o))),
              );
            },
          );
        },
      ),
    );
  }
}

// --- EDITOR ---
class EditorObrazovka extends StatefulWidget {
  final Otazka otazka;
  const EditorObrazovka({super.key, required this.otazka});
  @override
  State<EditorObrazovka> createState() => _EditorObrazovkaState();
}

class _EditorObrazovkaState extends State<EditorObrazovka> {
  late TextEditingController _nazevCtrl;
  late TextEditingController _popisCtrl;
  late TextEditingController _odkazCtrl; // NOVÝ CONTROLLER
  late double _progres;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nazevCtrl = TextEditingController(text: widget.otazka.nazev);
    _popisCtrl = TextEditingController(text: widget.otazka.popis);
    _odkazCtrl = TextEditingController(text: widget.otazka.odkaz); // NAČTENÍ ODKAZU
    _progres = widget.otazka.progres.toDouble();
    _selectedDate = widget.otazka.naplanovanoNa;
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // FUNKCE NA OTEVŘENÍ ODKAZU
  // AGRESIVNÍ OTEVÍRÁNÍ ODKAZU (Bez čekání na systém)
  void _launchOnlineDoc() {
    final String urlText = _odkazCtrl.text.trim();
    if (urlText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vlož odkaz!")));
      return;
    }

    // Odstraníme zbytečné await a zkusíme přímé volání
    try {
      String finalUrl = urlText;
      if (!finalUrl.startsWith('http')) {
        finalUrl = 'https://$finalUrl';
      }

      final Uri url = Uri.parse(finalUrl);

      // Tady je ta změna: Použijeme LaunchMode.externalNonBrowserApplication 
      // nebo prostě vynecháme složité ověřování
      launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
      );
      
      // Okamžitá zpětná vazba uživateli, aby věděl, že se něco děje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Otevírám prohlížeč..."), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      // Pokud i tohle selže, vypíšeme chybu do konzole místo zamrznutí UI
      print("Chyba při otevírání: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Otázka: ${widget.otazka.cislo}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nazevCtrl, decoration: const InputDecoration(labelText: "Název")),
            const SizedBox(height: 15),
            TextField(controller: _popisCtrl, decoration: const InputDecoration(labelText: "Poznámky"), maxLines: 3),
            const SizedBox(height: 15),
            // POLE PRO ODKAZ
            TextField(
              controller: _odkazCtrl, 
              decoration: const InputDecoration(labelText: "Online odkaz (Google Dokumenty)", hintText: "https://docs.google.com/...")
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _launchOnlineDoc,
              icon: const Icon(Icons.open_in_new),
              label: const Text("Otevřít materiály online"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.calendar_today),
              title: const Text("Naplánovat učení"),
              subtitle: Text(_selectedDate == null ? "Nezvoleno" : "${_selectedDate!.day}. ${_selectedDate!.month}. ${_selectedDate!.year}"),
              onTap: _pickDate,
              trailing: _selectedDate != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedDate = null)) : null,
            ),
            const SizedBox(height: 20),
            Text("Naučeno: ${_progres.round()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(value: _progres, min: 0, max: 100, divisions: 20, onChanged: (v) => setState(() => _progres = v)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, 
              child: FilledButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('otazky').doc(widget.otazka.id).set({
                    'cislo': widget.otazka.cislo,
                    'nazev': _nazevCtrl.text,
                    'popis': _popisCtrl.text,
                    'odkaz': _odkazCtrl.text, // ULOŽENÍ ODKAZU
                    'progres': _progres.round(),
                    'predmet': widget.otazka.predmet,
                    'lastUpdate': FieldValue.serverTimestamp(),
                    'planDate': _selectedDate,
                  });
                  if (mounted) Navigator.pop(context);
                }, 
                child: const Text("Uložit do cloudu")
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NASTAVENÍ ---
class NastaveniObrazovka extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const NastaveniObrazovka({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nastavení")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Tmavý režim"),
            subtitle: const Text("Šetří oči při nočním učení"),
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            value: isDarkMode,
            onChanged: (v) => onThemeToggle(),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Verze aplikace"),
            trailing: Text("1.4.0"),
          ),
        ],
      ),
    );
  }
}