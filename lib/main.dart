import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MacrosApp());

const bg = Color(0xFF090B12);
const panel = Color(0xFF151927);
const accent = Color(0xFFB7F36B);
const muted = Color(0xFF9299AA);

class MacrosApp extends StatefulWidget {
  const MacrosApp({super.key});
  @override
  State<MacrosApp> createState() => _MacrosAppState();
}

class _MacrosAppState extends State<MacrosApp> {
  Color tint = accent;
  bool glow = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MACROS',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: accent, surface: panel),
      useMaterial3: true,
      fontFamily: 'Roboto',
    ),
    home: HomeScreen(
      tint: tint,
      onTint: (c) => setState(() => tint = c),
      glow: glow,
      onGlow: (v) => setState(() => glow = v),
    ),
  );
}

class MusicService {
  final String id, name, subtitle;
  final IconData icon;
  final Color color;
  final String searchUrl;
  const MusicService(this.id, this.name, this.subtitle, this.icon, this.color, this.searchUrl);
}

const services = <MusicService>[
  MusicService('spotify', 'Spotify', 'Global catalogue', Icons.graphic_eq, Color(0xFF1DB954), 'https://open.spotify.com/search/'),
  MusicService('vk', 'VK Музыка', 'Музыка и лайки', Icons.music_note, Color(0xFF4C8BF5), 'https://vk.com/audio'),
  MusicService('yandex', 'Яндекс Музыка', 'Подборки и альбомы', Icons.waves, Color(0xFFFFCC00), 'https://music.yandex.ru/search?text='),
  MusicService('soundcloud', 'SoundCloud', 'Независимые релизы', Icons.cloud, Color(0xFFFF6A2B), 'https://soundcloud.com/search?q='),
];

class Track {
  final String title, artist;
  final String source;
  bool selected;
  Track(this.title, this.artist, this.source, {this.selected = true});
}

class HomeScreen extends StatefulWidget {
  final Color tint;
  final ValueChanged<Color> onTint;
  final bool glow;
  final ValueChanged<bool> onGlow;
  const HomeScreen({super.key, required this.tint, required this.onTint, required this.glow, required this.onGlow});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final search = TextEditingController();
  final playlist = TextEditingController();
  final query = TextEditingController();
  final clipQuery = TextEditingController();
  final clipUrl = TextEditingController();
  final List<String> recentClips = [];
  String status = 'Подключи сервисы, чтобы начать перенос';
  final Set<String> connected = {};
  final List<String> savedLinks = [];
  final List<Track> tracks = [];
  final List<String> likes = ['Любимые треки', 'Новые открытия', 'В дорогу'];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      connected.addAll(p.getStringList('connected') ?? []);
      savedLinks.addAll(p.getStringList('links') ?? []);
      recentClips.addAll(p.getStringList('recent_clips') ?? []);
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('connected', connected.toList());
    await p.setStringList('links', savedLinks);
    await p.setStringList('recent_clips', recentClips);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      setState(() => status = 'Не удалось открыть ссылку');
    }
  }

  Future<void> _searchAll() async {
    final q = search.text.trim();
    if (q.isEmpty) return;
    for (final s in services) {
      final url = s.id == 'yandex'
          ? 'https://music.yandex.ru/search?text=${Uri.encodeComponent(q)}'
          : s.id == 'soundcloud'
              ? 'https://soundcloud.com/search?q=${Uri.encodeComponent(q)}'
              : s.id == 'spotify'
                  ? 'https://open.spotify.com/search/${Uri.encodeComponent(q)}'
                  : 'https://vk.com/audio?q=${Uri.encodeComponent(q)}';
      await _open(url);
    }
    setState(() => status = 'Открыл поиск по запросу «$q» в доступных приложениях/сайтах');
  }

  Future<void> _importPlaylist() async {
    final url = playlist.text.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !(url.startsWith('https://') || url.startsWith('http://'))) {
      setState(() => status = 'Вставь корректную ссылку на плейлист');
      return;
    }
    setState(() {
      if (!savedLinks.contains(url)) savedLinks.insert(0, url);
      tracks
        ..clear()
        ..addAll([
          Track('Пример найденного трека 1', 'Демо-исполнитель', 'Источник плейлиста'),
          Track('Пример найденного трека 2', 'Демо-исполнитель', 'Источник плейлиста'),
          Track('Пример найденного трека 3', 'Демо-исполнитель', 'Источник плейлиста'),
        ]);
      status = 'Ссылка сохранена. Реальное чтение треков включается после подключения API источника.';
    });
    await _save();
  }

  Future<void> _connect(MusicService s) async {
    // OAuth/API login must be implemented with each provider's approved developer flow.
    setState(() => status = '${s.name}: для реального подключения нужен OAuth/API доступ. Пока доступен переход к сервису.');
    final urls = {
      'spotify': 'https://developer.spotify.com/dashboard',
      'vk': 'https://dev.vk.com/',
      'yandex': 'https://yandex.ru/dev/music/',
      'soundcloud': 'https://developers.soundcloud.com/',
    };
    await _open(urls[s.id]!);
  }


  Future<void> _searchClips() async {
    final q = clipQuery.text.trim();
    if (q.isEmpty) {
      setState(() => status = 'Введи название песни и исполнителя');
      return;
    }
    final url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$q official music video')}';
    await _open(url);
    setState(() => status = 'Открыл поиск официальных клипов для «$q»');
  }

  Future<void> _openClipLink([String? value]) async {
    final raw = (value ?? clipUrl.text).trim();
    final uri = Uri.tryParse(raw);
    final host = uri?.host.toLowerCase() ?? '';
    final allowed = host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be' ||
        host == 'm.youtube.com';
    if (uri == null || uri.scheme != 'https' || !allowed) {
      setState(() => status = 'Вставь HTTPS-ссылку на YouTube или youtu.be');
      return;
    }
    if (!recentClips.contains(raw)) {
      recentClips.insert(0, raw);
      if (recentClips.length > 8) recentClips.removeLast();
      await _save();
    }
    await _open(raw);
    setState(() => status = 'Открыл клип во внешнем видеоплеере');
  }

  Widget _clips() => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
    children: [
      const Text('Клипы', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text(
        'Найди официальный клип или открой ссылку на видео. Просмотр запускается в YouTube или браузере.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: clipQuery,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchClips(),
        decoration: InputDecoration(
          hintText: 'Название песни и исполнитель',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _searchClips,
        icon: const Icon(Icons.video_library_outlined),
        label: const Text('Найти клип'),
      ),
      const SizedBox(height: 22),
      const Text('Открыть ссылку на клип', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 9),
      TextField(
        controller: clipUrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: 'https://youtu.be/…',
          prefixIcon: const Icon(Icons.link),
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => _openClipLink(),
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Открыть видео'),
      ),
      if (recentClips.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Недавно открытые', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        ...recentClips.map((url) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.ondemand_video, color: muted),
          title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openClipLink(url),
          ),
        )),
      ],
      const SizedBox(height: 18),
      const Text(
        'Примечание: эта экспериментальная версия не скачивает видео и не встраивает чужие ролики. Она открывает поиск и ссылки через официальный видеосервис. Встроенный просмотр можно добавить отдельно через поддерживаемый SDK или разрешённый embed-плеер.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      Text(status, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );

  void _recognize() {
    setState(() => status = 'Распознавание подготовлено как отдельный модуль. Для реального Shazam-подобного поиска нужен аудио-recognition API и разрешение на микрофон.');
    showModalBottomSheet(
      context: context, backgroundColor: panel,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.graphic_eq, size: 48, color: widget.tint),
          const SizedBox(height: 12),
          const Text('Распознать музыку', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Следующий этап: микрофон, аудио-отпечаток и запрос к распознающему сервису. Эта сборка пока не записывает звук.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно')),
        ]),
      ),
    );
  }

  Widget _serviceTile(MusicService s) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      CircleAvatar(backgroundColor: s.color.withOpacity(.16), child: Icon(s.icon, color: s.color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(s.subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      ])),
      TextButton(onPressed: () => _connect(s), child: Text(connected.contains(s.id) ? 'Подключён' : 'Подключить')),
    ]),
  );

  Widget _home() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 100), children: [
    Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: widget.tint, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.all_inclusive, color: bg)),
      const SizedBox(width: 11),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MACROS', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 2)),
        Text('Вся музыка. Одно место.', style: TextStyle(color: muted, fontSize: 12)),
      ]),
      const Spacer(),
      IconButton(onPressed: () => setState(() => tab = 5), icon: const Icon(Icons.tune)),
    ]),
    const SizedBox(height: 24),
    const Text('Слушай. Ищи. Переноси.', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
    const SizedBox(height: 7),
    const Text('Музыкальные сервисы — в одном интерфейсе', style: TextStyle(color: muted)),
    const SizedBox(height: 18),
    TextField(controller: search, onSubmitted: (_) => _searchAll(), decoration: InputDecoration(
      hintText: 'Песня, исполнитель или альбом',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(onPressed: _searchAll, icon: const Icon(Icons.arrow_forward)),
      filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    )),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _actionCard(Icons.compare_arrows, 'Перенести плейлист', 'Ссылка → новый сервис', () => setState(() => tab = 1))),
      const SizedBox(width: 10),
      Expanded(child: _actionCard(Icons.graphic_eq, 'Что играет?', 'Распознать трек', _recognize)),
    ]),
    const SizedBox(height: 10),
    _actionCard(Icons.ondemand_video, 'Музыкальные клипы', 'Найти и открыть видео к треку', () => setState(() => tab = 4)),
    const SizedBox(height: 23),
    _sectionTitle('Подключённые сервисы', 'Все'),
    const SizedBox(height: 10),
    ...services.map(_serviceTile),
    const SizedBox(height: 12),
    _sectionTitle('Для тебя', 'Обновить'),
    const SizedBox(height: 10),
    _recommendation('Похожие на любимое', 'Подборка на основе твоих лайков', Icons.favorite),
    _recommendation('Новые открытия', 'Музыка за пределами привычного', Icons.explore),
    _recommendation('Вернуться к плейлисту', 'Продолжи перенос с последнего шага', Icons.playlist_play),
    const SizedBox(height: 12),
    Text(status, style: const TextStyle(color: muted, fontSize: 12)),
  ]);

  Widget _actionCard(IconData icon, String title, String sub, VoidCallback tap) => InkWell(
    onTap: tap, borderRadius: BorderRadius.circular(18),
    child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
      gradient: LinearGradient(colors: [widget.tint.withOpacity(.20), panel], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.tint.withOpacity(.18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: widget.tint, size: 25), const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4), Text(sub, style: const TextStyle(color: muted, fontSize: 11)),
      ]),
    ),
  );

  Widget _sectionTitle(String title, String action) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const Spacer(), TextButton(onPressed: () {}, child: Text(action)),
  ]);

  Widget _recommendation(String title, String sub, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [Icon(icon, color: widget.tint), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(sub, style: const TextStyle(color: muted, fontSize: 12))])), const Icon(Icons.chevron_right, color: muted)]),
  );

  Widget _transfer() => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), children: [
    const Text('Перенос плейлиста', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Вставь ссылку, проверь найденные песни и выбери, куда их перенести.', style: TextStyle(color: muted)),
    const SizedBox(height: 20),
    TextField(controller: playlist, decoration: InputDecoration(hintText: 'Ссылка на Spotify / VK / Яндекс / SoundCloud', prefixIcon: const Icon(Icons.link), filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _importPlaylist, icon: const Icon(Icons.travel_explore), label: const Text('Найти песни в плейлисте')),
    const SizedBox(height: 18),
    if (tracks.isNotEmpty) ...[
      const Text('Песни для переноса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...tracks.map((t) => CheckboxListTile(
        value: t.selected, activeColor: widget.tint, contentPadding: EdgeInsets.zero,
        title: Text(t.title), subtitle: Text('${t.artist} · ${t.source}', style: const TextStyle(color: muted)),
        onChanged: (v) => setState(() => t.selected = v ?? false),
      )),
      const SizedBox(height: 8),
      const Text('Куда перенести?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...services.map((s) => ListTile(
        leading: Icon(s.icon, color: s.color), title: Text(s.name),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => status = 'Цель выбрана: ${s.name}. Реальная запись плейлиста заработает после OAuth/API-интеграции.'),
      )),
      TextButton.icon(onPressed: () => setState(() => status = 'Выбрано ${tracks.where((t) => t.selected).length} треков. Целевая запись пока демонстрационная.'), icon: const Icon(Icons.playlist_add), label: const Text('Подготовить перенос')),
    ],
    const SizedBox(height: 14),
    Text(status, style: const TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 18),
    const Text('Поддерживается выбор отдельных песен. Чтение настоящего списка и создание плейлиста требуют разрешённого доступа к API источника и аккаунту назначения.', style: TextStyle(color: muted, fontSize: 12)),
  ]);

  Widget _discover() => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), children: [
    const Text('Открытия', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8), const Text('Опиши, что хочешь послушать — MACROS подготовит запрос для поиска.', style: TextStyle(color: muted)),
    const SizedBox(height: 18),
    TextField(controller: query, maxLines: 3, decoration: InputDecoration(hintText: 'Например: добавь в мои лайки все доступные треки исполнителя ...', filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: () {
      final q = query.text.trim();
      if (q.isNotEmpty) setState(() => status = 'Запрос сохранён: «$q». Поиск по каталогам и добавление в лайки будут подключены через API сервисов.');
    }, icon: const Icon(Icons.auto_awesome), label: const Text('Сформировать подборку')),
    const SizedBox(height: 22),
    _recommendation('Похожие исполнители', 'Найти артистов с похожим звучанием', Icons.people_alt),
    _recommendation('По настроению', 'Спокойно · энергично · атмосферно', Icons.mood),
    _recommendation('Из моего вкуса', 'На основе сохранённых предпочтений', Icons.insights),
    Text(status, style: const TextStyle(color: muted, fontSize: 12)),
  ]);

  Widget _settings() => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), children: [
    const Text('Настройки', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 18),
    const Text('Внешний вид', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    const SizedBox(height: 10),
    Wrap(spacing: 12, children: [
      for (final c in [accent, const Color(0xFF7C9CFF), const Color(0xFFFF7C9D), const Color(0xFFB18CFF), const Color(0xFFFFB45C)])
        InkWell(onTap: () => widget.onTint(c), child: CircleAvatar(backgroundColor: c, radius: 19, child: widget.tint == c ? const Icon(Icons.check, color: bg) : null)),
    ]),
    SwitchListTile(value: widget.glow, onChanged: widget.onGlow, title: const Text('Акцентное оформление')),
    const SizedBox(height: 20),
    const Text('Аккаунты и сервисы', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    const SizedBox(height: 10),
    ...services.map(_serviceTile),
    const SizedBox(height: 16),
    const Text('Синхронизация', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    const ListTile(leading: Icon(Icons.cloud_sync), title: Text('Синхронизация между устройствами'), subtitle: Text('Каркас интерфейса. Нужен сервер MACROS и вход в аккаунт.')),
    const ListTile(leading: Icon(Icons.lock_outline), title: Text('Конфиденциальность'), subtitle: Text('Токены подключённых сервисов должны храниться безопасно. Не вставляй секреты API в открытый GitHub.')),
  ]);

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _transfer(), _discover(), _home(), _clips(), _settings()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel, indicatorColor: widget.tint.withOpacity(.18),
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.compare_arrows), label: 'Перенос'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Открытия'),
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Shazam'),
          NavigationDestination(icon: Icon(Icons.ondemand_video), label: 'Клипы'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Настройки'),
        ],
      ),
      floatingActionButton: tab == 3 ? FloatingActionButton.large(backgroundColor: widget.tint, foregroundColor: bg, onPressed: _recognize, child: const Icon(Icons.graphic_eq, size: 34)) : null,
    );
  }
}
