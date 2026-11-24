import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.background,
    required this.surface,
    required this.accent,
    required this.accent2,
  });

  final Color background;
  final Color surface;
  final Color accent;
  final Color accent2;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogTrack {
  const _CatalogTrack(this.title, this.artist, this.album, this.genre);
  final String title;
  final String artist;
  final String album;
  final String genre;
}

const _starterTracks = <_CatalogTrack>[
  _CatalogTrack('Луна', 'Баста', 'Баста 5', 'Русский хип-хоп'),
  _CatalogTrack('Комета', 'JONY', 'Комета', 'Поп'),
  _CatalogTrack('Птичка', 'HammAli & Navai', 'Птичка', 'Поп'),
  _CatalogTrack('Камин', 'EMIN', 'Камин', 'Поп'),
  _CatalogTrack('Пыяла', 'АИГЕЛ', 'Музыка', 'Электроника'),
  _CatalogTrack('Судно', 'Молчат Дома', 'Этажи', 'Пост-панк'),
  _CatalogTrack('Малиновая лада', 'GAYAZOV$ BROTHER$', 'Малиновая лада', 'Поп'),
  _CatalogTrack('На заре', 'Альянс', 'На заре', 'Рок'),
  _CatalogTrack('Blinding Lights', 'The Weeknd', 'After Hours', 'Поп'),
  _CatalogTrack('Shape of You', 'Ed Sheeran', '÷', 'Поп'),
  _CatalogTrack('Starboy', 'The Weeknd', 'Starboy', 'Поп / R&B'),
  _CatalogTrack('Believer', 'Imagine Dragons', 'Evolve', 'Рок'),
  _CatalogTrack('Do I Wanna Know?', 'Arctic Monkeys', 'AM', 'Инди-рок'),
  _CatalogTrack('Another Love', 'Tom Odell', 'Long Way Down', 'Инди-поп'),
  _CatalogTrack('Sweater Weather', 'The Neighbourhood', 'I Love You.', 'Инди-рок'),
  _CatalogTrack('After Dark', 'Mr.Kitty', 'Time', 'Электроника'),
];

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();
  String _genre = 'Все';
  static const _genres = ['Все', 'Поп', 'Русский хип-хоп', 'Рок', 'Инди-рок', 'Электроника'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final tracks = _starterTracks.where((track) {
      final matchesQuery = q.isEmpty ||
          track.title.toLowerCase().contains(q) ||
          track.artist.toLowerCase().contains(q) ||
          track.album.toLowerCase().contains(q);
      final matchesGenre = _genre == 'Все' ||
          track.genre == _genre ||
          (_genre == 'Поп' && track.genre.startsWith('Поп'));
      return matchesQuery && matchesGenre;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        const Text('Музыкальный каталог',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Исполнители, альбомы и популярные треки в одном месте.',
          style: TextStyle(color: Color(0xFFAAA2B9)),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Найти трек, исполнителя или альбом',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _genres.map((genre) {
              final selected = genre == _genre;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(genre),
                  selected: selected,
                  onSelected: (_) => setState(() => _genre = genre),
                  selectedColor: widget.accent.withValues(alpha: .22),
                  side: BorderSide(
                    color: selected ? widget.accent : widget.surface,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text('Треки каталога',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ),
            Text('${tracks.length}',
                style: TextStyle(color: widget.accent, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text('Ничего не найдено',
                  style: TextStyle(color: Color(0xFFAAA2B9))),
            ),
          ),
        for (var i = 0; i < tracks.length; i++)
          _trackTile(tracks[i], i),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: widget.surface.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.accent.withValues(alpha: .2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Первый этап каталога',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text(
                'Это стартовый набор метаданных для проверки поиска и интерфейса. Аудиофайлы не скопированы: кнопка у трека открывает поиск официального источника. Каталог можно будет расширять отдельно от подключения воспроизведения.',
                style: TextStyle(
                    color: Color(0xFFAAA2B9), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trackTile(_CatalogTrack track, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: widget.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(17),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                colors: [widget.accent, widget.accent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          title: Text(track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            '${track.artist}  •  ${track.album}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFAAA2B9), fontSize: 12),
          ),
          trailing: IconButton(
            tooltip: 'Найти официальный источник',
            icon: Icon(Icons.open_in_new_rounded, color: widget.accent),
            onPressed: () => _openTrack(track),
          ),
          onTap: () => _openTrack(track),
        ),
      ),
    );
  }

  Future<void> _openTrack(_CatalogTrack track) async {
    final query = Uri.encodeComponent('${track.artist} ${track.title} official audio');
    final uri = Uri.parse('https://www.youtube.com/results?search_query=$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
