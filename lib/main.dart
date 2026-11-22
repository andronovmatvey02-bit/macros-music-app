import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MacrosApp());

class MusicService {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String searchUrl;
  const MusicService(this.name, this.subtitle, this.icon, this.color, this.searchUrl);
}

const services = <MusicService>[
  MusicService('Spotify', 'Музыка и плейлисты', Icons.music_note, Color(0xFF1DB954), 'https://open.spotify.com/search/'),
  MusicService('VK Музыка', 'Музыка ВКонтакте', Icons.graphic_eq, Color(0xFF2787F5), 'https://vk.com/audio'),
  MusicService('Яндекс Музыка', 'Каталог Яндекса', Icons.album, Color(0xFFFFCC00), 'https://music.yandex.ru/search?text='),
  MusicService('SoundCloud', 'Независимые исполнители', Icons.cloud, Color(0xFFFF6A00), 'https://soundcloud.com/search?q='),
];

class MacrosApp extends StatefulWidget {
  const MacrosApp({super.key});
  @override
  State<MacrosApp> createState() => _MacrosAppState();
}

class _MacrosAppState extends State<MacrosApp> {
  Color accent = const Color(0xFFB7D34B);
  int tab = 0;
  final searchController = TextEditingController();
  final playlistController = TextEditingController();
  final discoveryController = TextEditingController();
  final selected = <String>{};
  String destination = 'Spotify';
  String status = 'Демо-режим: сервисы пока не подключены';

  @override
  void initState() {
    super.initState();
    _loadAccent();
  }

  Future<void> _loadAccent() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('accent');
    if (value != null && mounted) setState(() => accent = Color(value));
  }

  Future<void> _setAccent(Color color) async {
    setState(() => accent = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent', color.value);
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) setState(() => status = 'Не удалось открыть ссылку на этом устройстве');
    }
  }

  Future<void> _searchAll() async {
    final q = searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => status = 'Выбери сервис, чтобы открыть поиск: $q');
  }

  void _recognize() {
    setState(() => status = 'Распознавание музыки пока демонстрационное и не подключено');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Распознавание музыки'),
        content: const Text('Кнопка распознавания пока является макетом. Для настоящего распознавания понадобится подключить разрешённый сервис и доступ к микрофону.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MACROS',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF101114),
        useMaterial3: true,
        cardTheme: CardThemeData(color: const Color(0xFF1B1D22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MACROS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
          actions: [IconButton(onPressed: _recognize, icon: const Icon(Icons.graphic_eq)), const SizedBox(width: 8)],
        ),
        body: IndexedStack(index: tab, children: [_home(), _transfer(), _discover(), _settings()]),
        floatingActionButton: FloatingActionButton(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          onPressed: _recognize,
          child: const Icon(Icons.mic),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
            NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Перенос'),
            NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Поиск'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Настройки'),
          ],
        ),
      ),
    );
  }

  Widget _home() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Открой музыку по-новому', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(status, style: TextStyle(color: Colors.white.withValues(alpha: .65))),
      const SizedBox(height: 18),
      TextField(
        controller: searchController,
        onSubmitted: (_) => _searchAll(),
        decoration: InputDecoration(
          hintText: 'Трек, исполнитель или альбом',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(onPressed: _searchAll, icon: const Icon(Icons.arrow_forward)),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 18),
      const Text('Музыкальные сервисы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...services.map((s) => Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: s.color.withValues(alpha: .18), child: Icon(s.icon, color: s.color)),
          title: Text(s.name),
          subtitle: Text(s.subtitle),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(s.searchUrl + Uri.encodeComponent(searchController.text.trim())),
        ),
      )),
      const SizedBox(height: 12),
      const Text('Подключение аккаунтов и персональные рекомендации появятся после интеграции API.', style: TextStyle(color: Colors.white60)),
    ],
  );

  Widget _transfer() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Перенос плейлиста', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Вставь ссылку на публичный плейлист. В этой версии поле и список ниже демонстрационные.'),
      const SizedBox(height: 14),
      TextField(controller: playlistController, decoration: const InputDecoration(labelText: 'Ссылка на плейлист', hintText: 'https://...', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: destination,
        decoration: const InputDecoration(labelText: 'Сервис назначения', border: OutlineInputBorder()),
        items: services.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
        onChanged: (v) => setState(() => destination = v ?? destination),
      ),
      const SizedBox(height: 18),
      const Text('Пример треков для демонстрации', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ...['Artist — Example Track', 'Another Artist — Demo Song', 'MACROS — Preview'].map((track) => CheckboxListTile(
        value: selected.contains(track),
        activeColor: accent,
        title: Text(track),
        onChanged: (v) => setState(() { if (v == true) { selected.add(track); } else { selected.remove(track); } }),
      )),
      FilledButton.icon(
        onPressed: () => setState(() => status = 'Выбрано ${selected.length} демо-трек(ов). Реальный перенос ещё не подключён.'),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Подготовить перенос (демо)'),
      ),
      const SizedBox(height: 8),
      Text(status, style: const TextStyle(color: Colors.white60)),
    ],
  );

  Widget _discover() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Открытие новой музыки', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Опиши, что хочешь послушать. Пока запрос можно открыть в поиске выбранного сервиса.'),
      const SizedBox(height: 14),
      TextField(controller: discoveryController, decoration: const InputDecoration(hintText: 'Например: спокойный инди-поп', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => _open('https://music.yandex.ru/search?text=${Uri.encodeComponent(discoveryController.text)}'), child: const Text('Искать в Яндекс Музыке')),
      const SizedBox(height: 12),
      const Text('Умные рекомендации и анализ вкуса пока не реализованы.', style: TextStyle(color: Colors.white60)),
    ],
  );

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Настройки', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      const Text('Цвет акцента', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Wrap(spacing: 12, children: [
        const Color(0xFFB7D34B), const Color(0xFF6C8CFF), const Color(0xFFFF8A50), const Color(0xFFCB82FF), const Color(0xFF48C9B0)
      ].map((c) => InkWell(onTap: () => _setAccent(c), child: CircleAvatar(backgroundColor: c, child: accent.value == c.value ? const Icon(Icons.check, color: Colors.black) : null))).toList()),
      const SizedBox(height: 24),
      const ListTile(leading: Icon(Icons.cloud_sync), title: Text('Синхронизация'), subtitle: Text('Пока не подключена')),
      const ListTile(leading: Icon(Icons.info_outline), title: Text('MACROS 0.4'), subtitle: Text('Стартовый интерфейс. Реальные API-интеграции ещё предстоит добавить.')),
    ],
  );
}
