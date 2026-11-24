import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MacrosApp());
}

const Color _background = Color(0xFF090711);
const Color _surface = Color(0xFF171222);
const Color _surface2 = Color(0xFF21172F);
const Color _muted = Color(0xFFB7AFC6);

class MacrosApp extends StatefulWidget {
  const MacrosApp({super.key});

  @override
  State<MacrosApp> createState() => _MacrosAppState();
}

class _MacrosAppState extends State<MacrosApp> {
  Color _accent = const Color(0xFFB45CFF);
  bool _loading = true;

  static const List<Color> _accents = [
    Color(0xFFB45CFF),
    Color(0xFFFF5EBB),
    Color(0xFF8C72FF),
    Color(0xFF55C8FF),
    Color(0xFFE8DDF7),
  ];

  @override
  void initState() {
    super.initState();
    _loadAccent();
  }

  Future<void> _loadAccent() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('macros_accent');
    if (!mounted) return;
    setState(() {
      if (saved != null) _accent = Color(saved);
      _loading = false;
    });
  }

  Future<void> _setAccent(Color color) async {
    setState(() => _accent = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('macros_accent', color.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MACROS',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
          surface: _surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF120D1B),
          indicatorColor: _accent.withValues(alpha: 0.22),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          hintStyle: const TextStyle(color: _muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : MacrosShell(
              accent: _accent,
              accents: _accents,
              onAccentChanged: _setAccent,
            ),
    );
  }
}

class MacrosShell extends StatefulWidget {
  const MacrosShell({
    super.key,
    required this.accent,
    required this.accents,
    required this.onAccentChanged,
  });

  final Color accent;
  final List<Color> accents;
  final ValueChanged<Color> onAccentChanged;

  @override
  State<MacrosShell> createState() => _MacrosShellState();
}

class _MacrosShellState extends State<MacrosShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(accent: widget.accent, onNavigate: (i) => setState(() => _index = i)),
      const TransferPage(),
      const SearchPage(),
      SettingsPage(
        accent: widget.accent,
        accents: widget.accents,
        onAccentChanged: widget.onAccentChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MACROS',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Icon(Icons.graphic_eq_rounded, color: widget.accent, size: 30),
          ),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), label: 'Перенос'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Поиск'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Настройки'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.accent, required this.onNavigate});

  final Color accent;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ТВОЯ МУЗЫКА', style: TextStyle(color: _muted, letterSpacing: 2.2, fontSize: 11, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Моя волна', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(Icons.graphic_eq_rounded, color: accent, size: 26),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF38204F), Color(0xFF21152F), Color(0xFF171020)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.13), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(30)),
                    child: Text('ПОД ТВОЁ НАСТРОЕНИЕ', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const Spacer(),
                  Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Поймай свою\\nволну.', style: TextStyle(fontSize: 30, height: 1.05, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Подборка музыки, которая постепенно подстраивается под твои предпочтения.', style: TextStyle(color: Color(0xFFD1C4DE), height: 1.4, fontSize: 13)),
              const SizedBox(height: 22),
              SizedBox(
                height: 58,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(31, (i) {
                    final heights = [13, 22, 34, 18, 43, 28, 52, 24, 37, 17, 46, 29, 55, 20, 39, 26, 48, 16, 33, 51, 23, 41, 18, 35, 54, 27, 44, 19, 37, 24, 47];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [accent, const Color(0xFFFF69BD)]),
                          ),
                          child: SizedBox(height: heights[i].toDouble()),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onNavigate(2),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Открыть музыкальный поиск'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF170D20),
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Text('Твоя коллекция', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            TextButton(onPressed: () => onNavigate(1), child: Text('Перенос', style: TextStyle(color: accent))),
          ],
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.library_music_rounded,
          title: 'Любимый плейлист',
          subtitle: 'Здесь появится твоя самая часто прослушиваемая подборка',
          accent: accent,
          onTap: () => onNavigate(1),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Твои инструменты'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.swap_horiz_rounded,
                title: 'Перенос',
                subtitle: 'Плейлисты между сервисами',
                accent: accent,
                onTap: () => onNavigate(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.explore_rounded,
          title: 'Открыть сервисы',
          subtitle: 'Поиск в Spotify, VK, Яндекс Музыке и SoundCloud',
          accent: accent,
          onTap: () => onNavigate(2),
        ),
        const SizedBox(height: 18),
        const _NoticeCard(
          title: 'MACROS в разработке',
          message: 'Персональная волна и рекомендации пока представлены интерфейсом. Для реального подбора музыки ещё предстоит подключить музыкальные источники и алгоритм предпочтений.',
        ),
      ],
    );
  }
}

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController _controller = TextEditingController();
  String _message = 'Вставь ссылку на плейлист Spotify, VK или другой сервис.';
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _prepare() {
    final value = _controller.text.trim();
    setState(() {
      _submitted = value.isNotEmpty;
      _message = value.isEmpty
          ? 'Сначала вставь ссылку на плейлист.'
          : 'Ссылка сохранена в этом окне. Автоматическое чтение треков и перенос пока не подключены.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Перенос плейлистов', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Начни со ссылки на исходный плейлист.', style: TextStyle(color: _muted)),
        const SizedBox(height: 22),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.link_rounded),
            hintText: 'Вставь ссылку на плейлист',
          ),
          onChanged: (_) => setState(() => _submitted = false),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _prepare,
          icon: const Icon(Icons.playlist_add_check_rounded),
          label: const Text('Проверить ссылку'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 16),
        _NoticeCard(title: _submitted ? 'Ссылка принята' : 'Статус', message: _message),
        const SizedBox(height: 24),
        const _SectionTitle('Следующие этапы'),
        const SizedBox(height: 10),
        const _StepTile(number: '1', title: 'Импорт метаданных', subtitle: 'Получить названия треков и исполнителей через разрешённый API.'),
        const _StepTile(number: '2', title: 'Поиск совпадений', subtitle: 'Найти доступные версии треков в других каталогах.'),
        const _StepTile(number: '3', title: 'Создание плейлиста', subtitle: 'Добавить найденные треки через официальный API сервиса.'),
      ],
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      ('Spotify', 'https://open.spotify.com/search'),
      ('VK Музыка', 'https://vk.com/music'),
      ('Яндекс Музыка', 'https://music.yandex.ru'),
      ('SoundCloud', 'https://soundcloud.com/search'),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Поиск музыки', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Выбери сервис. Сейчас MACROS открывает его официальный сайт или приложение.', style: TextStyle(color: _muted)),
        const SizedBox(height: 20),
        for (final service in services)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActionCard(
              icon: Icons.open_in_new_rounded,
              title: service.$1,
              subtitle: 'Открыть поиск',
              accent: Theme.of(context).colorScheme.primary,
              onTap: () => _openUrl(context, service.$2),
            ),
          ),
        const SizedBox(height: 10),
        const _NoticeCard(
          title: 'Важно',
          message: 'Встроенный единый поиск и воспроизведение появятся после подключения API и источников аудио с соответствующими правами.',
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.accent,
    required this.accents,
    required this.onAccentChanged,
  });

  final Color accent;
  final List<Color> accents;
  final ValueChanged<Color> onAccentChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Настройки', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 22),
        const Text('Цвет акцента', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: accents.map((color) {
            final selected = color.value == accent.value;
            return InkWell(
              onTap: () => onAccentChanged(color),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: selected ? const Icon(Icons.check, color: Colors.black, size: 28) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        const _InfoRow(icon: Icons.cloud_sync_outlined, title: 'Синхронизация', subtitle: 'Пока не подключена'),
        const SizedBox(height: 22),
        const _InfoRow(icon: Icons.info_outline_rounded, title: 'MACROS 0.5', subtitle: 'Обновлённый интерфейс. Интеграции музыкальных сервисов ещё предстоит добавить.'),
        const SizedBox(height: 26),
        const _NoticeCard(
          title: 'О версии',
          message: '0.5 — это новая версия интерфейса приложения, а не готовая интеграция со Spotify или VK.',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.name, required this.icon, required this.color, required this.onTap});
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.accent, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: _muted, height: 1.4)),
      ]),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.title, required this.subtitle});
  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: Text(number, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _muted, height: 1.35)),
        ])),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _muted, size: 27),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, height: 1.4)),
      ])),
    ]);
  }
}

Future<void> _openUrl(BuildContext context, String value) async {
  final uri = Uri.parse(value);
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку.')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку.')));
    }
  }
}
