import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaturitniApp());
}

// 1. DATOVÝ MODEL
class Otazka {
  String id;
  int cislo;
  String nazev;
  String popis;
  int progres; 
  String predmet;

  Otazka({
    required this.id,
    required this.cislo,
    this.nazev = '',
    this.popis = '',
    this.progres = 0, 
    required this.predmet,
  });
}

class MaturitniApp extends StatefulWidget {
  const MaturitniApp({super.key});

  @override
  State<MaturitniApp> createState() => _MaturitniAppState();
}

class _MaturitniAppState extends State<MaturitniApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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

// --- HLAVNÍ MENU S ODPOČTEM ---
class MenuObrazovka extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const MenuObrazovka({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<MenuObrazovka> createState() => _MenuObrazovkaState();
}

class _MenuObrazovkaState extends State<MenuObrazovka> {
  late List<Otazka> vsechnyOtazky;
  late Timer _timer;
  DateTime maturitaDatum = DateTime(2026, 5, 25, 8, 0); // 25.5.2026 v 8:00

  @override
  void initState() {
    super.initState();
    vsechnyOtazky = _generujOtazky();
    // Aktualizace odpočtu každou minutu
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  List<Otazka> _generujOtazky() {
    List<Otazka> list = [];
    Map<String, int> limity = {'ČJ': 25, 'IT': 25, 'EKO': 20};
    limity.forEach((predmet, max) {
      for (int i = 1; i <= max; i++) {
        list.add(Otazka(id: '$predmet-$i', cislo: i, nazev: 'Otázka č. $i', predmet: predmet));
      }
    });
    return list;
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
              MaterialPageRoute(builder: (context) => NastaveniObrazovka(
                onThemeToggle: widget.onThemeToggle, 
                isDarkMode: widget.isDarkMode
              )),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // --- KARTA S ODPOČTEM ---
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text("Čas do ústních maturit:", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(
                        _vypocitejOdpocet(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
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
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => SeznamOtazekObrazovka(predmet: kod, vsechnyOtazky: vsechnyOtazky)));
          setState(() {}); 
        },
        child: Text(nazev, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// --- OBRAZOVKA NASTAVENÍ ---
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
            trailing: Text("1.0.0"),
          ),
        ],
      ),
    );
  }
}

// --- SEZNAM OTÁZEK ---
class SeznamOtazekObrazovka extends StatefulWidget {
  final String predmet;
  final List<Otazka> vsechnyOtazky;
  const SeznamOtazekObrazovka({super.key, required this.predmet, required this.vsechnyOtazky});

  @override
  State<SeznamOtazekObrazovka> createState() => _SeznamOtazekObrazovkaState();
}

class _SeznamOtazekObrazovkaState extends State<SeznamOtazekObrazovka> {
  @override
  Widget build(BuildContext context) {
    final filtrovane = widget.vsechnyOtazky.where((o) => o.predmet == widget.predmet).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Otázky: ${widget.predmet}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: filtrovane.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final o = filtrovane[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${o.cislo}')),
                  title: Text(o.nazev, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: LinearProgressIndicator(
                    value: o.progres / 100.0,
                    color: o.progres > 70 ? Colors.green : (o.progres > 30 ? Colors.orange : Colors.red),
                  ),
                  trailing: Text('${o.progres}%'),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => EditorObrazovka(otazka: o)));
                    setState(() {});
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text("Zpět do menu")),
          )
        ],
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
      appBar: AppBar(title: Text('Otázka č. ${widget.otazka.cislo}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nazevCtrl, decoration: const InputDecoration(labelText: "Název")),
            const SizedBox(height: 15),
            TextField(controller: _popisCtrl, decoration: const InputDecoration(labelText: "Poznámky"), maxLines: 3),
            const SizedBox(height: 25),
            Text("Naučeno: ${_progres.round()}%"),
            Slider(value: _progres, min: 0, max: 100, divisions: 20, onChanged: (v) => setState(() => _progres = v)),
            const Spacer(),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
              widget.otazka.nazev = _nazevCtrl.text;
              widget.otazka.popis = _popisCtrl.text;
              widget.otazka.progres = _progres.round();
              Navigator.pop(context);
            }, child: const Text("Uložit"))),
          ],
        ),
      ),
    );
  }
}