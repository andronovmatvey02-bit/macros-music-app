import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'catalog_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MacrosApp());
}

const _muted = Color(0xFF9AAFA8);

class AppPalette {
  const AppPalette(this.name, this.background, this.surface, this.surface2, this.accent, this.accent2, this.light);
  final String name;
  final Color background, surface, surface2, accent, accent2;
  final bool light;
}

const palettes = <AppPalette>[
  AppPalette('Black Mint', Color(0xFF080B0B), Color(0xFF121A18), Color(0xFF1D2925), Color(0xFF70DCC0), Color(0xFF70DCC0), false),
  AppPalette('Monochrome', Color(0xFF090A0D), Color(0xFF191B20), Color(0xFF292C33), Color(0xFFE4E6EC), Color(0xFF9EA3AF), false),
  AppPalette('Pure Light', Color(0xFFF4F1F8), Color(0xFFFFFFFF), Color(0xFFEAE4F2), Color(0xFF8246D8), Color(0xFFE65B9E), true),
  AppPalette('Midnight', Color(0xFF07111D), Color(0xFF101F30), Color(0xFF19334A), Color(0xFF42C8E8), Color(0xFF8B7CFF), false),
];

class MacrosApp extends StatefulWidget {
  const MacrosApp({super.key});
  @override
  State<MacrosApp> createState() => _MacrosAppState();
}

class _MacrosAppState extends State<MacrosApp> {
  int _theme = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _theme = (p.getInt('macros_theme') ?? 0).clamp(0, palettes.length - 1).toInt();
      _ready = true;
    });
  }

  Future<void> _setTheme(int value) async {
    setState(() => _theme = value);
    final p = await SharedPreferences.getInstance();
    await p.setInt('macros_theme', value);
  }

  @override
  Widget build(BuildContext context) {
    final p = palettes[_theme];
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.light ? Brightness.light : Brightness.dark,
      surface: p.surface,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MACROS',
      theme: ThemeData(
        useMaterial3: true,
        brightness: p.light ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: p.background,
        colorScheme: scheme,
        appBarTheme: AppBarTheme(backgroundColor: p.background, foregroundColor: p.light ? const Color(0xFF21182B) : Colors.white, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: p.surface,
          indicatorColor: p.accent.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        cardTheme: CardThemeData(color: p.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: p.surface,
          hintStyle: TextStyle(color: p.light ? Colors.black45 : _muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      home: _ready ? MacrosShell(themeIndex: _theme, onThemeChanged: _setTheme) : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class MacrosShell extends StatefulWidget {
  const MacrosShell({super.key, required this.themeIndex, required this.onThemeChanged});
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;
  @override
  State<MacrosShell> createState() => _MacrosShellState();
}

class _MacrosShellState extends State<MacrosShell> {
  int _tab = 0;
  bool _playing = false;
  String _track = 'Выбери музыку';
  final List<String> _playlists = ['Избранное', 'Ночная поездка', 'На повторе'];
  final List<String> _friends = ['matvey_music', 'violet.wave', 'soundfox'];

  AppPalette get p => palettes[widget.themeIndex];

  void _go(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WavePage(p: p, onPlay: _play, onNavigate: _go, playlists: _playlists),
      CollectionPage(p: p, playlists: _playlists, onChanged: () => setState(() {}), onPlay: _play),
      TransferPage(p: p),
      CatalogPage(background: p.background, surface: p.surface, accent: p.accent, accent2: p.accent2),
      TogetherPage(p: p, friends: _friends),
      ClipsPage(p: p),
      SettingsPage(p: p, selectedTheme: widget.themeIndex, onThemeChanged: widget.onThemeChanged),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('MACROS', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 3, color: p.accent)),
        actions: [
          IconButton(tooltip: 'Клипы', onPressed: () => _go(5), icon: Icon(Icons.smart_display_outlined, color: p.accent)),
          IconButton(tooltip: 'Настройки', onPressed: () => _go(6), icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        _ThemeBackdrop(p: p, themeIndex: widget.themeIndex),
        SafeArea(child: Column(children: [
          Expanded(child: IndexedStack(index: _tab, children: pages)),
          if (_track != 'Выбери музыку') _MiniPlayer(p: p, track: _track, playing: _playing, onTap: () => _showPlayer(context), onPlay: () => setState(() => _playing = !_playing)),
        ])),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab > 4 ? 0 : _tab,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.graphic_eq_rounded), label: 'Волна'),
          NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Коллекция'),
          NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), label: 'Перенос'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Открытия'),
          NavigationDestination(icon: Icon(Icons.headphones_rounded), label: 'Вместе'),
        ],
      ),
    );
  }

  void _play(String name) => setState(() { _track = name; _playing = true; });

  void _showPlayer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: p.surface,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 54, height: 5, decoration: BoxDecoration(color: p.accent.withValues(alpha: .5), borderRadius: BorderRadius.circular(9))),
          const SizedBox(height: 24),
          Container(width: 220, height: 220, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [p.accent, p.accent2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: p.accent.withValues(alpha: .25), blurRadius: 40)],
          ), child: const Icon(Icons.graphic_eq_rounded, size: 90, color: Colors.white)),
          const SizedBox(height: 24),
          Text(_track, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('MACROS • демонстрационный плеер', style: TextStyle(color: _muted)),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous_rounded, size: 34)),
            const SizedBox(width: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: Colors.black, shape: const CircleBorder(), padding: const EdgeInsets.all(18)),
              onPressed: () { setState(() => _playing = !_playing); Navigator.pop(ctx); },
              child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34),
            ),
            const SizedBox(width: 18),
            IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next_rounded, size: 34)),
          ]),
          const SizedBox(height: 16),
          const Text('Воспроизведение аудио из музыкальных сервисов ещё не подключено.', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
        ]),
      )),
    );
  }
}

class WavePage extends StatelessWidget {
  const WavePage({super.key, required this.p, required this.onPlay, required this.onNavigate, required this.playlists});
  final AppPalette p;
  final ValueChanged<String> onPlay;
  final ValueChanged<int> onNavigate;
  final List<String> playlists;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [
    const Text('ТВОЯ МУЗЫКА', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
    const SizedBox(height: 5),
    const Text('Моя волна', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.surface2, p.surface, p.background]),
        border: Border.all(color: p.accent.withValues(alpha: .3)),
        boxShadow: [BoxShadow(color: p.accent.withValues(alpha: .12), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Pill(text: 'ПОД ТВОЁ НАСТРОЕНИЕ', color: p.accent),
          const Spacer(),
          Icon(Icons.auto_awesome, color: p.accent),
        ]),
        const SizedBox(height: 16),
        const Text('Поймай свою\nволну.', style: TextStyle(fontSize: 32, height: 1.04, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Музыка, которая должна подстраиваться под твой вкус.', style: TextStyle(color: _muted, height: 1.4)),
        const SizedBox(height: 20),
        SizedBox(height: 58, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: List.generate( thirty, (i) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(height: (12 + ((i * 17 + 13) % 43)).toDouble(), decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: [p.accent, p.accent2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          )),
        ))))),
        const SizedBox(height: 16),
        const Text('Какое настроение сейчас?', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: ['Спокойно', 'Энергично', 'Грустно', 'Вдохновение'].map((s) => _Pill(text: s, color: p.accent, outlined: true)).toList()),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => onPlay('Моя волна • подборка'),
          icon: const Icon(Icons.play_arrow_rounded), label: const Text('Запустить волну'),
          style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.light ? Colors.white : Colors.black, minimumSize: const Size.fromHeight(50)),
        )),
      ]),
    ),
    const SizedBox(height: 22),
    Row(children: [const Expanded(child: Text('Твоя коллекция', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), TextButton(onPressed: () => onNavigate(1), child: Text('Все', style: TextStyle(color: p.accent)))]),
    _PlaylistTile(p: p, title: playlists.isNotEmpty ? playlists.first : 'Избранное', subtitle: 'Твой плейлист', onTap: () => onNavigate(1)),
    const SizedBox(height: 18),
    const Text('Быстрый доступ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    _ActionTile(p: p, icon: Icons.swap_horiz_rounded, title: 'Перенести музыку', subtitle: 'Между музыкальными сервисами', onTap: () => onNavigate(2)),
    _ActionTile(p: p, icon: Icons.headphones_rounded, title: 'Слушать вместе', subtitle: 'Общая музыкальная комната', onTap: () => onNavigate(4)),
    _ActionTile(p: p, icon: Icons.explore_rounded, title: 'Открытия', subtitle: 'Новые треки и исполнители', onTap: () => onNavigate(3)),
    const SizedBox(height: 12),
    const _InfoNote(title: 'Статус волны', text: 'Экран и выбор настроения работают. Персональные рекомендации требуют подключения музыкальных источников и алгоритма предпочтений.'),
  ]);
}

const int thirty = 30;

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.p, required this.playlists, required this.onChanged, required this.onPlay});
  final AppPalette p;
  final List<String> playlists;
  final VoidCallback onChanged;
  final ValueChanged<String> onPlay;
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Коллекция', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
    const SizedBox(height: 14),
    TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск плейлистов и треков')),
    const SizedBox(height: 16),
    Row(children: [const Expanded(child: Text('Плейлисты', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), FilledButton.tonalIcon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Создать'))]),
    const SizedBox(height: 10),
    for (final name in widget.playlists.where((x) => x.toLowerCase().contains(query.toLowerCase())))
      _PlaylistTile(p: widget.p, title: name, subtitle: 'Локальная подборка • треки можно добавить позже', onTap: () => widget.onPlay(name)),
    if (widget.playlists.where((x) => x.toLowerCase().contains(query.toLowerCase())).isEmpty)
      const _InfoNote(title: 'Ничего не найдено', text: 'Попробуй изменить запрос или создай новый плейлист.'),
    const SizedBox(height: 16),
    const _InfoNote(title: 'Синхронизация', text: 'Плейлисты пока хранятся в текущем сеансе приложения. Подключение облачного хранения и реальных каталогов будет отдельным этапом.'),
  ]);

  Future<void> _create() async {
    final c = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Новый плейлист'),
      content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Название')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Создать'))],
    ));
    if (name != null && name.isNotEmpty) {
      setState(() => widget.playlists.add(name));
      widget.onChanged();
    }
    c.dispose();
  }
}

class TransferPage extends StatefulWidget {
  const TransferPage({super.key, required this.p});
  final AppPalette p;
  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  String source = 'Spotify';
  String destination = 'VK Музыка';
  final url = TextEditingController();
  bool playlists = true, likes = false, history = false;
  @override
  void dispose() { url.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Перенос музыки', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    const Text('Выбери откуда и куда переносить свою музыкальную коллекцию.', style: TextStyle(color: _muted)),
    const SizedBox(height: 20),
    _SelectCard(title: 'Откуда', value: source, options: const ['Spotify', 'VK Музыка', 'Яндекс Музыка', 'SoundCloud'], onChanged: (v) => setState(() => source = v)),
    const SizedBox(height: 10),
    _SelectCard(title: 'Куда', value: destination, options: const ['Spotify', 'VK Музыка', 'Яндекс Музыка', 'SoundCloud'], onChanged: (v) => setState(() => destination = v)),
    const SizedBox(height: 18),
    const Text('Что переносим?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    CheckboxListTile(value: playlists, onChanged: (v) => setState(() => playlists = v ?? false), title: const Text('Плейлисты'), contentPadding: EdgeInsets.zero),
    CheckboxListTile(value: likes, onChanged: (v) => setState(() => likes = v ?? false), title: const Text('Понравившиеся треки'), contentPadding: EdgeInsets.zero),
    CheckboxListTile(value: history, onChanged: (v) => setState(() => history = v ?? false), title: const Text('История прослушиваний'), contentPadding: EdgeInsets.zero),
    const SizedBox(height: 12),
    TextField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(prefixIcon: Icon(Icons.link), hintText: 'Ссылка на плейлист (если есть)')),
    const SizedBox(height: 14),
    FilledButton.icon(onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Подключение сервисов'),
      content: Text('Маршрут $source → $destination выбран. Реальный перенос пока недоступен: OAuth и API этих сервисов ещё не подключены. Ссылки и музыка не будут изменены.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
    )), icon: const Icon(Icons.compare_arrows), label: const Text('Проверить возможность переноса'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
    const SizedBox(height: 16),
    const _InfoNote(title: 'Умный поиск', text: 'В полной версии MACROS будет искать совпадения в подключённых сервисах и отдельно показывать оригиналы, ремиксы, live-версии и каверы. Сейчас интеграции ещё не подключены.'),
  ]);
}

class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({super.key, required this.p, required this.onPlay});
  final AppPalette p;
  final ValueChanged<String> onPlay;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Открытия', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    const Text('Новые звуки, исполнители и настроения.', style: TextStyle(color: _muted)),
    const SizedBox(height: 18),
    _DiscoveryCard(p: p, icon: Icons.favorite_outline, title: 'Для тебя', subtitle: 'Подборка на основе настроек твоей волны', onTap: () => onPlay('Открытия • Для тебя')),
    _DiscoveryCard(p: p, icon: Icons.fiber_new, title: 'Новые релизы', subtitle: 'Свежие альбомы и синглы', onTap: () => onPlay('Открытия • Новые релизы')),
    _DiscoveryCard(p: p, icon: Icons.category_outlined, title: 'Жанры', subtitle: 'Исследуй звучание разных направлений', onTap: () => onPlay('Открытия • Жанры')),
    _DiscoveryCard(p: p, icon: Icons.mood, title: 'Настроения', subtitle: 'Музыка под состояние и момент', onTap: () => onPlay('Открытия • Настроения')),
    _DiscoveryCard(p: p, icon: Icons.people_outline, title: 'Похожие исполнители', subtitle: 'Найди артистов рядом с любимыми', onTap: () => onPlay('Открытия • Артисты')),
    const SizedBox(height: 10),
    const _InfoNote(title: 'Важно', text: 'Прослушивание раздела «Открытия» не должно менять предпочтения «Моей волны», пока ты явно не добавишь трек в свою коллекцию. Реальные каталоги пока не подключены.'),
  ]);
}

class TogetherPage extends StatefulWidget {
  const TogetherPage({super.key, required this.p, required this.friends});
  final AppPalette p;
  final List<String> friends;
  @override
  State<TogetherPage> createState() => _TogetherPageState();
}

class _TogetherPageState extends State<TogetherPage> {
  final search = TextEditingController();
  bool roomCreated = false;
  @override
  void dispose() { search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final online = widget.friends.take(2).where((f) => f.toLowerCase().contains(search.text.toLowerCase())).toList();
    final offline = widget.friends.skip(2).where((f) => f.toLowerCase().contains(search.text.toLowerCase())).toList();
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Слушать вместе', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Создавай музыкальные комнаты и собирай общую очередь.', style: TextStyle(color: _muted)),
      const SizedBox(height: 16),
      TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Найти друга по имени или @нику')),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: _createRoom, icon: const Icon(Icons.headphones), label: const Text('Начать слушать вместе'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: widget.p.accent, foregroundColor: widget.p.light ? Colors.white : Colors.black)),
      if (roomCreated) ...[
        const SizedBox(height: 12),
        const _InfoNote(title: 'Комната создана на этом устройстве', text: 'Пока это демонстрация интерфейса. Для приглашений и синхронизации между телефонами нужен сервер и аккаунты.'),
      ],
      const SizedBox(height: 24),
      const Text('В сети', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (online.isEmpty) const Text('Пока никого нет в сети', style: TextStyle(color: _muted)),
      for (final f in online) _FriendTile(name: f, online: true, p: widget.p, onTap: _createRoom),
      const SizedBox(height: 18),
      const Text('Недавно были', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (offline.isEmpty) const Text('Нет совпадений', style: TextStyle(color: _muted)),
      for (final f in offline) _FriendTile(name: f, online: false, p: widget.p, onTap: _createRoom),
      const SizedBox(height: 18),
      const _InfoNote(title: 'Синхронизация', text: 'Совместная очередь, управление воспроизведением у обоих участников, статусы друзей и приглашения требуют серверной части. Этот экран пока демонстрирует будущий сценарий, а не реальную сетевую комнату.'),
    ]);
  }
  Future<void> _createRoom() async {
    final c = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Новая комната'),
      content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Название комнаты')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Создать'))],
    ));
    c.dispose();
    if (name != null && name.isNotEmpty) setState(() => roomCreated = true);
  }
}

class ClipsPage extends StatelessWidget {
  const ClipsPage({super.key, required this.p});
  final AppPalette p;
  @override
  Widget build(BuildContext context) {
    final c = TextEditingController();
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Клипы', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Ищи музыкальные видео и открывай их в официальном сервисе.', style: TextStyle(color: _muted)),
      const SizedBox(height: 18),
      TextField(controller: c, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Трек или исполнитель')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () {
        final q = c.text.trim();
        if (q.isNotEmpty) _open("https://www.youtube.com/results?search_query=${Uri.encodeComponent('$q official music video')}");
      }, icon: const Icon(Icons.smart_display), label: const Text('Найти клип')),
      const SizedBox(height: 16),
      const _InfoNote(title: 'Как это работает', text: 'Поиск открывается на YouTube. MACROS не скачивает и не копирует видео; просмотр и доступность регулируются самим сервисом.'),
    ]);
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.p, required this.selectedTheme, required this.onThemeChanged});
  final AppPalette p;
  final int selectedTheme;
  final ValueChanged<int> onThemeChanged;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Настройки', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5),
    const Text('MACROS 0.8.0 (сборка 9)', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
    const SizedBox(height: 18),
    const Text('Оформление и фон', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    for (var i = 0; i < palettes.length; i++)
      _ThemeTile(palette: palettes[i], selected: selectedTheme == i, onTap: () => onThemeChanged(i)),
    const SizedBox(height: 20),
    const Text('Музыка и интерфейс', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    const _SettingsInfo(icon: Icons.graphic_eq, title: 'Эквалайзер', subtitle: 'Появится после подключения аудиодвижка'),
    const _SettingsInfo(icon: Icons.animation, title: 'Анимации', subtitle: 'Визуальные эффекты интерфейса'),
    const _SettingsInfo(icon: Icons.privacy_tip_outlined, title: 'Приватность', subtitle: 'Управление видимостью профиля будет добавлено с аккаунтами'),
    const SizedBox(height: 18),
    const _InfoNote(title: 'Фоновые темы', text: 'Каждая тема меняет не только акцентные цвета, но и градиентный фон, световые пятна и декоративные элементы. Социальная синхронизация, музыкальные API и реальное воспроизведение ещё требуют серверной и интеграционной разработки.'),
  ]);
}

class _ThemeBackdrop extends StatelessWidget {
  const _ThemeBackdrop({required this.p, required this.themeIndex});
  final AppPalette p;
  final int themeIndex;

  @override
  Widget build(BuildContext context) {
    final gradients = <List<Color>>[
      [const Color(0xFF080B0B), const Color(0xFF101A17), const Color(0xFF080B0B)],
      [const Color(0xFF050608), const Color(0xFF20232A), const Color(0xFF090A0D)],
      [const Color(0xFFF9F6FF), const Color(0xFFE8DDF8), const Color(0xFFF4F1F8)],
      [const Color(0xFF06101C), const Color(0xFF0B2940), const Color(0xFF07111D)],
    ];
    final glow = <Color>[
      const Color(0xFF70DCC0), const Color(0xFFB8C0D0),
      const Color(0xFFC9A5FF), const Color(0xFF24BFE5),
    ][themeIndex];
    return IgnorePointer(child: Stack(fit: StackFit.expand, children: [
      DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradients[themeIndex]),
      )),
      Positioned(top: -105, right: -85, child: _GlowOrb(color: glow.withValues(alpha: themeIndex == 2 ? .20 : .24), size: 300)),
      Positioned(top: 260, left: -155, child: _GlowOrb(color: p.accent2.withValues(alpha: .13), size: 270)),
      Positioned(bottom: -150, right: -90, child: _GlowOrb(color: p.accent.withValues(alpha: .14), size: 320)),
      if (themeIndex == 0) Positioned(top: 150, right: 18, child: Icon(Icons.auto_awesome, size: 18, color: p.accent.withValues(alpha: .22))),
      if (themeIndex == 1) Positioned(top: 90, left: 24, child: Icon(Icons.blur_circular, size: 110, color: Colors.white.withValues(alpha: .035))),
      if (themeIndex == 2) Positioned(top: 35, right: 22, child: Icon(Icons.wb_sunny_outlined, size: 82, color: p.accent.withValues(alpha: .10))),
      if (themeIndex == 3) Positioned(top: 115, right: 20, child: Icon(Icons.blur_on, size: 100, color: p.accent.withValues(alpha: .10))),
    ]));
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
  );
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.palette, required this.selected, required this.onTap});
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(
      color: palette.surface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: selected ? palette.accent : palette.surface2, width: selected ? 2 : 1),
    ), child: Row(children: [
      Container(width: 52, height: 42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [palette.background, palette.surface2, palette.accent]))),
      const SizedBox(width: 14),
      Expanded(child: Text(palette.name, style: const TextStyle(fontWeight: FontWeight.w800))),
      if (selected) Icon(Icons.check_circle, color: palette.accent),
    ])),
  ));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.outlined = false});
  final String text;
  final Color color;
  final bool outlined;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: outlined ? Colors.transparent : color.withValues(alpha: .16), borderRadius: BorderRadius.circular(30), border: outlined ? Border.all(color: color.withValues(alpha: .5)) : null),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.p, required this.title, required this.subtitle, required this.onTap});
  final AppPalette p;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(
    color: p.surface, borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [p.accent, p.accent2])), child: const Icon(Icons.music_note, color: Colors.white, size: 27)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12))])),
      const Icon(Icons.chevron_right, color: _muted),
    ]))),
  ));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.p, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final AppPalette p;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Material(
    color: p.surface, borderRadius: BorderRadius.circular(17),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: ListTile(
      leading: Icon(icon, color: p.accent, size: 27), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)), trailing: const Icon(Icons.chevron_right, color: _muted),
    )),
  ));
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.title, required this.text});
  final String title, text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: _muted, height: 1.4, fontSize: 12))]),
  );
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({required this.title, required this.value, required this.options, required this.onChanged});
  final String title, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(17)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(
    isExpanded: true, value: value, onChanged: (v) { if (v != null) onChanged(v); },
    items: options.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
    hint: Text(title),
  )));
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.p, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final AppPalette p;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(
    color: p.surface, borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: ListTile(
      leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: p.accent.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: p.accent)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)), trailing: const Icon(Icons.chevron_right),
    )),
  ));
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.name, required this.online, required this.p, required this.onTap});
  final String name;
  final bool online;
  final AppPalette p;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Stack(children: [
      CircleAvatar(backgroundColor: p.surface2, child: Icon(Icons.person, color: p.accent)),
      if (online) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF36D98A), shape: BoxShape.circle, border: Border.all(color: p.background, width: 2)))),
    ]),
    title: Text('@$name', style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(online ? 'В сети' : 'Не в сети', style: const TextStyle(color: _muted, fontSize: 12)),
    trailing: IconButton(onPressed: onTap, icon: Icon(Icons.headphones, color: p.accent)),
  );
}

class _SettingsInfo extends StatelessWidget {
  const _SettingsInfo({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)));
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.p, required this.track, required this.playing, required this.onTap, required this.onPlay});
  final AppPalette p;
  final String track;
  final bool playing;
  final VoidCallback onTap, onPlay;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 6), child: Material(
    color: p.surface2, borderRadius: BorderRadius.circular(16),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(gradient: LinearGradient(colors: [p.accent, p.accent2]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.graphic_eq, color: Colors.white)),
      const SizedBox(width: 10), Expanded(child: Text(track, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
      IconButton(onPressed: onPlay, icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: p.accent)),
    ]))),
  ));
}

Future<void> _open(String value) async {
  final uri = Uri.parse(value);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
