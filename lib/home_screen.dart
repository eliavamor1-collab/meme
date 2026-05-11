import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sound_model.dart';
import 'sounds_provider.dart';
import 'settings_provider.dart';
import 'settings_drawer.dart';
import 'audio_cache.dart';
import 'web_audio_player.dart';

// הקטגוריות הקבועות לתצוגה מחולקת
const List<String> kDisplayCategories = ['שיר', 'פלוץ', 'קול', 'עברית'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // מובייל: just_audio | Web: WebAudioPlayer
  final AudioPlayer? _mobilePlayer = kIsWeb ? null : AudioPlayer();
  final WebAudioPlayer _webPlayer = WebAudioPlayer();
  String? _playingId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
    _mobilePlayer?.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _playingId = null);
      }
    });
  }

  @override
  void dispose() {
    _mobilePlayer?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _playSound(SoundModel sound) async {
    if (_playingId == sound.id) {
      // עצור
      if (kIsWeb) {
        _webPlayer.stop();
      } else {
        await _mobilePlayer?.stop();
      }
      if (mounted) setState(() => _playingId = null);
      return;
    }
    if (mounted) setState(() => _playingId = sound.id);
    try {
      if (kIsWeb) {
        _webPlayer.play(
          sound.filePath,
          onEnded: () {
            if (mounted) setState(() => _playingId = null);
          },
        );
      } else {
        if (sound.isBuiltIn) {
          await _mobilePlayer?.setAudioSource(
            AudioSource.asset(sound.filePath),
          );
        } else {
          final cached = AudioCacheManager().getLocalPath(sound.filePath);
          final path = cached ?? sound.filePath;
          await _mobilePlayer?.setAudioSource(AudioSource.file(path));
        }
        await _mobilePlayer?.play();
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _addSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['opus', 'ogg', 'mp3', 'wav', 'm4a'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    final appDir = await getApplicationDocumentsDirectory();
    if (!mounted) return;
    final soundsDir = Directory('${appDir.path}/sounds');
    if (!await soundsDir.exists()) await soundsDir.create(recursive: true);
    if (!mounted) return;
    final provider = context.read<SoundsProvider>();
    const uuid = Uuid();
    for (final file in result.files) {
      if (file.path == null) continue;
      final id = uuid.v4();
      final ext = file.extension ?? 'opus';
      final destPath = '${soundsDir.path}/$id.$ext';
      await File(file.path!).copy(destPath);
      final name = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      await provider.addSound(
        SoundModel(id: id, name: name, filePath: destPath),
      );
    }
  }

  void _showSortMenu() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'מיון לפי',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // שדה מיון
                  Row(
                    children: [
                      _sortChip(
                        ctx,
                        'שם',
                        SortField.name,
                        settings,
                        setModalState,
                      ),
                      const SizedBox(width: 8),
                      _sortChip(
                        ctx,
                        'אורך',
                        SortField.duration,
                        settings,
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'כיוון',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dirChip(
                        ctx,
                        '(עולה)',
                        SortDirection.asc,
                        settings,
                        setModalState,
                      ),
                      const SizedBox(width: 8),
                      _dirChip(
                        ctx,
                        '(יורד)',
                        SortDirection.desc,
                        settings,
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sortChip(
    BuildContext ctx,
    String label,
    SortField field,
    SettingsProvider settings,
    StateSetter setModalState,
  ) {
    final selected = settings.sortField == field;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        settings.setSortField(field);
        setModalState(() {});
        setState(() {});
      },
    );
  }

  Widget _dirChip(
    BuildContext ctx,
    String label,
    SortDirection dir,
    SettingsProvider settings,
    StateSetter setModalState,
  ) {
    final selected = settings.sortDirection == dir;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        settings.setSortDirection(dir);
        setModalState(() {});
        setState(() {});
      },
    );
  }

  List<SoundModel> _getSortedFiltered(
    SoundsProvider soundsProvider,
    SettingsProvider settings,
  ) {
    var sounds = soundsProvider.allSounds;
    // סינון חיפוש
    if (_searchQuery.isNotEmpty) {
      sounds = sounds
          .where(
            (s) =>
                s.name.toLowerCase().contains(_searchQuery) ||
                (s.nameHe?.toLowerCase().contains(_searchQuery) ?? false) ||
                s.tags.any((t) => t.toLowerCase().contains(_searchQuery)),
          )
          .toList();
    }
    // מיון
    sounds = List.from(sounds);
    if (settings.sortField == SortField.name) {
      sounds.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
    // SortField.duration — ללא מידע על אורך בזמן ריצה, נשאיר כסדר ברירת מחדל
    if (settings.sortDirection == SortDirection.desc) {
      sounds = sounds.reversed.toList();
    }
    return sounds;
  }

  void _showRenameDialog(SoundModel sound) {
    final controller = TextEditingController(text: sound.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('שנה שם'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'שם הסאונד'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                context.read<SoundsProvider>().renameSound(sound.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(SoundModel sound) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחק סאונד'),
        content: Text('האם למחוק את "${sound.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<SoundsProvider>().removeSound(sound.id);
              if (_playingId == sound.id) {
                if (kIsWeb) {
                  _webPlayer.stop();
                } else {
                  _mobilePlayer?.stop();
                }
                setState(() => _playingId = null);
              }
              Navigator.pop(ctx);
            },
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(SoundModel sound) {
    final provider = context.read<SoundsProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              sound.displayName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (sound.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Wrap(
                  spacing: 6,
                  children: sound.tags
                      .map(
                        (t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 4),
            // מועדפים
            ListenableBuilder(
              listenable: provider,
              builder: (ctx, _) {
                final isFav = provider.isFavorite(sound.id);
                return ListTile(
                  leading: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(isFav ? 'הסר ממועדפים' : 'הוסף למועדפים'),
                  onTap: () {
                    provider.toggleFavorite(sound.id);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
            if (!sound.isBuiltIn) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('שנה שם'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(sound);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('מחק', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteDialog(sound);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    List<SoundModel> sounds,
    SoundsProvider provider,
    SettingsProvider settings,
    int crossAxisCount,
    ColorScheme colorScheme,
  ) {
    final userSounds = provider.userSounds;
    final favSounds = provider.favoriteSounds;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // חלק ראשי — גריד רגיל או קטגוריות
        if (settings.groupByCategory)
          _buildCategoryViewInline(sounds, crossAxisCount, colorScheme)
        else
          _buildGridInline(sounds, crossAxisCount),

        // קטגוריה קבועה: הסאונדים שלי
        if (userSounds.isNotEmpty) ...[
          _categoryHeader('🎵הסאונדים שלי🎵', colorScheme),
          _buildGridInline(userSounds, crossAxisCount),
          const SizedBox(height: 8),
        ],

        // קטגוריה קבועה: מועדפים
        if (favSounds.isNotEmpty) ...[
          _categoryHeader('⭐מועדפים⭐', colorScheme),
          _buildGridInline(favSounds, crossAxisCount),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _categoryHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildGridInline(List<SoundModel> sounds, int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        final isPlaying = _playingId == sound.id;
        return _SoundButton(
          sound: sound,
          isPlaying: isPlaying,
          player: isPlaying ? _mobilePlayer : null,
          onTap: () => _playSound(sound),
          onLongPress: () => _showOptionsMenu(sound),
        );
      },
    );
  }

  Widget _buildCategoryViewInline(
    List<SoundModel> sounds,
    int crossAxisCount,
    ColorScheme colorScheme,
  ) {
    final categorized = <String, List<SoundModel>>{};
    final uncategorized = <SoundModel>[];
    for (final cat in kDisplayCategories) {
      final inCat = sounds.where((s) => s.tags.contains(cat)).toList();
      if (inCat.isNotEmpty) categorized[cat] = inCat;
    }
    for (final s in sounds) {
      if (!kDisplayCategories.any((cat) => s.tags.contains(cat))) {
        uncategorized.add(s);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categorized.entries.map(
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _categoryHeader(e.key, colorScheme),
              _buildGridInline(e.value, crossAxisCount),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (uncategorized.isNotEmpty) ...[
          _categoryHeader('אחר', colorScheme),
          _buildGridInline(uncategorized, crossAxisCount),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final soundsProvider = context.watch<SoundsProvider>();
    final settings = context.watch<SettingsProvider>();
    final sounds = _getSortedFiltered(soundsProvider, settings);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 6 : 3;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '✨Meme✨',
          style: GoogleFonts.pacifico(
            fontSize: 26,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'הגדרות',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          // כפתור מיון
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'מיון',
            onPressed: _showSortMenu,
          ),
          // כפתור הוספה
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'הוסף סאונד',
            onPressed: _addSound,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'חיפוש...',
                hintTextDirection: TextDirection.rtl,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/BG Image.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: sounds.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 80,
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'לא נמצאו סאונדים'
                          : 'אין סאונדים עדיין',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'לחץ על + כדי להוסיף סאונדים',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                        ),
                      ),
                  ],
                ),
              )
            : _buildMainContent(
                sounds,
                soundsProvider,
                settings,
                crossAxisCount,
                colorScheme,
              ),
      ),
      floatingActionButton: null,
    );
  }
}

class _SoundButton extends StatefulWidget {
  final SoundModel sound;
  final bool isPlaying;
  final AudioPlayer? player; // null כשלא מתנגן או ב-Web
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SoundButton({
    required this.sound,
    required this.isPlaying,
    required this.player,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<_SoundButton> {
  Duration _position = Duration.zero;
  StreamSubscription? _positionSub;

  @override
  void didUpdateWidget(_SoundButton old) {
    super.didUpdateWidget(old);
    if (!widget.isPlaying) {
      _position = Duration.zero;
      _positionSub?.cancel();
      _positionSub = null;
    }
    if (widget.player != old.player && widget.player != null) {
      _positionSub?.cancel();
      _positionSub = widget.player!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalDur = AudioCacheManager().getDuration(widget.sound.filePath);
    final isPlaying = widget.isPlaying;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isPlaying
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // שמאל — זמן שעבר (רק כשמתנגן)
                  SizedBox(
                    width: 36,
                    child: isPlaying
                        ? Text(
                            _fmt(_position),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const SizedBox.shrink(),
                  ),
                  // אייקון באמצע
                  Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 28,
                    color: isPlaying
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  // ימין — אורך כולל (תמיד)
                  SizedBox(
                    width: 36,
                    child: totalDur != null
                        ? Text(
                            _fmt(totalDur),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isPlaying
                                  ? colorScheme.onPrimary.withValues(
                                      alpha: 0.85,
                                    )
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // שמות ממורכזים
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      widget.sound.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPlaying
                            ? colorScheme.onPrimary.withValues(alpha: 0.85)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ),
                  if (widget.sound.nameHe != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        widget.sound.nameHe!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPlaying
                              ? colorScheme.onPrimary.withValues(alpha: 0.85)
                              : const Color(0xFF43A047),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
