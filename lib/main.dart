import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  DateTime? posledniUprava; // NOVÉ POLE

  Otazka({
    required this.id,
    required this.cislo,
    this.nazev = '',
    this.popis = '',
    this.progres = 0, 
    required this.predmet,
    this.posledniUprava,
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
      posledniUprava: (data['lastUpdate'] as Timestamp?)?.toDate(), // PŘEVOD Z FIREBASE
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

// --- SEZNAM OTÁZEK ---
class SeznamOtazekObrazovka extends StatelessWidget {
  final String predmet;
  const SeznamOtazekObrazovka({super.key, required this.predmet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Otázky: $predmet')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('otazky')
            .where('predmet', isEqualTo: predmet)
            .orderBy('cislo')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    int cislo = index + 1;
                    Otazka otazka;
                    var existingDoc = docs.where((d) => d['cislo'] == cislo);
                    if (existingDoc.isNotEmpty) {
                      otazka = Otazka.fromFirestore(existingDoc.first);
                    } else {
                      otazka = Otazka(id: '$predmet-$cislo', cislo: cislo, nazev: 'Otázka č. $cislo', predmet: predmet);
                    }

                    return ListTile(
                      leading: CircleAvatar(child: Text('${otazka.cislo}')),
                      title: Text(otazka.nazev, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: otazka.progres / 100.0,
                            color: otazka.progres > 70 ? Colors.green : (otazka.progres > 30 ? Colors.orange : Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            otazka.posledniUprava != null 
                              ? "Naposledy upraveno: ${otazka.posledniUprava!.day}. ${otazka.posledniUprava!.month}. ${otazka.posledniUprava!.year}"
                              : "Zatím neotevřeno",
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      trailing: Text('${otazka.progres}%'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditorObrazovka(otazka: otazka))),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text("Zpět do menu")),
              )
            ],
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
  late double _progres;

  @override
  void initState() {
    super.initState();
    _nazevCtrl = TextEditingController(text: widget.otazka.nazev);
    _popisCtrl = TextEditingController(text: widget.otazka.popis);
    _progres = widget.otazka.progres.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Úprava: ${widget.otazka.cislo}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nazevCtrl, decoration: const InputDecoration(labelText: "Název")),
            const SizedBox(height: 15),
            TextField(controller: _popisCtrl, decoration: const InputDecoration(labelText: "Poznámky"), maxLines: 5),
            const SizedBox(height: 25),
            Text("Naučeno: ${_progres.round()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(value: _progres, min: 0, max: 100, divisions: 20, onChanged: (v) => setState(() => _progres = v)),
            const Spacer(),
            SizedBox(
              width: double.infinity, 
              child: FilledButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('otazky').doc(widget.otazka.id).set({
                    'cislo': widget.otazka.cislo,
                    'nazev': _nazevCtrl.text,
                    'popis': _popisCtrl.text,
                    'progres': _progres.round(),
                    'predmet': widget.otazka.predmet,
                    'lastUpdate': FieldValue.serverTimestamp(), // TADY SE UKLÁDÁ ČAS
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
            leading: Icon(Icons.cloud_done_outlined),
            title: Text("Cloud synchronizace"),
            trailing: Icon(Icons.check, color: Colors.green),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Verze aplikace"),
            trailing: Text("1.2.0"),
          ),
        ],
      ),
    );
  }
}