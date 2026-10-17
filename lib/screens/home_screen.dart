import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import 'breathe_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Widget screen)? onOpenSubsection;
  final VoidCallback? onCloseSubsection;

  const HomeScreen({super.key, this.onOpenSubsection, this.onCloseSubsection});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Random _random = Random();

  String _selectedMood = 'Happy';
  late String _encouragement;

  final List<String> _encouragements = [
    'You’re doing better than you think. 💗',
    'Small steps still count.',
    'Be gentle with yourself today. 🦋',
    'You deserve the same kindness you give to others.',
    'Rest is not something you have to earn.',
    'You don’t have to be perfect to be proud of yourself.',
    'You’ve made it through difficult days before.',
    'You are growing, even when you can’t see it.',
    'Take a breath. You’re here, and that is enough.',
    'You’re allowed to begin again.',
    'Something good can still find you today. 🌸',
    'Give yourself permission to simply be.',
  ];

  final List<Map<String, String>> _moods = [
    {'name': 'Happy', 'emoji': '😊'},
    {'name': 'Sad', 'emoji': '😔'},
    {'name': 'Emotional', 'emoji': '🥹'},
    {'name': 'Angry', 'emoji': '😠'},
    {'name': 'Anxious', 'emoji': '😰'},
    {'name': 'Calm', 'emoji': '😌'},
    {'name': 'Tired', 'emoji': '😴'},
    {'name': 'Okay', 'emoji': '😐'},
    {'name': 'Loved', 'emoji': '💗'},
  ];

  final Map<String, List<String>> _moodMessages = {
    'Happy': [
      'Hold onto this little moment of happiness. You deserve to enjoy it fully. 🌸',
      'There is something beautiful about feeling good today. Let yourself enjoy it. 🦋',
      'You don’t need a reason to smile. Let yourself have this moment. 💗',
      'Whatever brought this happiness, take a moment to appreciate it. 🌷',
      'Let this little bit of joy stay with you for a while. You deserve it. ☀️',
      'You are allowed to celebrate the small things too. They matter. 🦋',
    ],
    'Sad': [
      'It’s okay not to feel okay today. You don’t have to rush yourself out of it. 🌷',
      'You don’t have to pretend to be fine. Give yourself permission to feel what you feel. 💗',
      'Some days are heavier than others. Be especially gentle with yourself today. 🌿',
      'You can take today slowly. There is no prize for rushing through difficult feelings. 🦋',
      'Whatever is hurting right now deserves kindness, not criticism. 🌸',
      'You are allowed to have a difficult day without letting it define you. 🌿',
    ],
    'Emotional': [
      'Whatever you’re feeling right now is allowed to be here. Be gentle with yourself. 💗',
      'You don’t have to explain every feeling. Sometimes you can simply let it exist. 🌷',
      'Take a moment to notice what your heart is trying to tell you. 🦋',
      'Being emotional doesn’t mean you are weak. It means something matters to you. 💕',
      'You can feel deeply and still be okay. Let yourself move through it gently. 💗',
      'Your emotions deserve compassion, especially from you. 🌿',
    ],
    'Angry': [
      'You don’t have to solve everything while you’re feeling overwhelmed. Give yourself a moment. 🌿',
      'Before reacting, give yourself permission to pause. You can choose your next step later. 🦋',
      'It’s okay to be angry. Give yourself some space before deciding what to do with the feeling. 💗',
      'Take a slow breath and let the intensity settle before you make any decisions. 🌷',
      'You can acknowledge your anger without letting it decide everything for you. 🌿',
      'Breathe first. Decide later. You don’t have to figure everything out in this moment. 🦋',
    ],
    'Anxious': [
      'You don’t have to figure everything out right now. Come back to this moment, one breath at a time. 🦋',
      'You only need to deal with what is in front of you right now. The rest can wait. 🌿',
      'Take one slow breath. You are here, and this moment is enough for now. 💗',
      'You don’t need to know exactly what happens next. Let yourself take things step by step. 🌷',
      'Not every thought needs an answer immediately. Let some thoughts pass by. 🌿',
      'You are allowed to slow down even when your thoughts feel fast. 🌷',
    ],
    'Calm': [
      'Let yourself enjoy this quiet moment. There is no need to rush. 🌿',
      'Stay here for a little while. You deserve moments that feel peaceful. 🌸',
      'Notice how it feels when you give yourself permission to slow down. 🦋',
      'Sometimes simply being is enough. You don’t always need to be doing something. 💗',
      'Nothing needs to happen right this second. Just breathe and be here. 🌸',
      'Let your shoulders soften and your breathing slow. You have time. 💗',
    ],
    'Tired': [
      'Maybe today doesn’t need your maximum effort. It’s okay to move a little slower. 🌙',
      'You are allowed to rest without feeling guilty about it. 💗',
      'Your energy matters too. Give yourself permission to conserve some of it today. 🌿',
      'Rest is part of taking care of yourself. You don’t have to be productive every moment. 🦋',
      'Sometimes the kindest thing you can do is pause. Give yourself that permission. 🌙',
      'There will be another day for doing more. For now, take care of yourself. 🌷',
    ],
    'Okay': [
      'You don’t have to feel amazing every day. Being okay is enough for today. 🌸',
      'Maybe today is simply an ordinary day. Ordinary days deserve kindness too. 🌿',
      'You don’t have to force yourself to feel happier than you do. 🌷',
      'Sometimes “I’m okay” is more than enough. Give yourself credit for that. 🌸',
      'Not every day needs to be memorable. Some days can simply be gentle. 🦋',
      'Whatever today becomes, you can meet it one moment at a time. 🌿',
    ],
    'Loved': [
      'Let yourself receive the warmth around you. You deserve to feel loved and cared for. 💗',
      'You deserve relationships where you can feel safe, valued, and appreciated. 🦋',
      'Love can be found in the little things too: a message, a smile, a kind word. 🌷',
      'You deserve kindness, tenderness, and patience — including from yourself. 🌿',
      'Sometimes love is quiet. A small gesture can still mean a lot. 🦋',
      'You are worthy of being cared for exactly as you are. 💕',
    ],
  };

  final Map<String, Set<String>> _seenMoodMessages = {};

  @override
  void initState() {
    super.initState();

    _encouragement = _encouragements[_random.nextInt(_encouragements.length)];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'Bree';

    if (hour >= 5 && hour < 12) {
      return 'Good morning, $name 🌷';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $name ☀️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening, $name 🌸';
    }

    return 'Good night, $name 🌙';
  }

  String _getMoodMessage() {
    final messages = _moodMessages[_selectedMood] ?? [];

    if (messages.isEmpty) {
      return 'Take today one gentle moment at a time. 🌷';
    }

    final seen = _seenMoodMessages.putIfAbsent(_selectedMood, () => <String>{});

    var available = messages
        .where((message) => !seen.contains(message))
        .toList();

    if (available.isEmpty) {
      seen.clear();
      available = List<String>.from(messages);
    }

    final message = available[_random.nextInt(available.length)];
    seen.add(message);

    return message;
  }

  void _selectMood(String mood) {
    if (_selectedMood == mood) return;

    setState(() {
      _selectedMood = mood;
    });
  }

  /// Opens BreatheScreen through MainNavigationScreen.
  void _openBreatheScreen() {
    final openSubsection = widget.onOpenSubsection;
    final closeSubsection = widget.onCloseSubsection;

    if (openSubsection == null || closeSubsection == null) {
      debugPrint(
        'Cannot open BreatheScreen: navigation callbacks are missing.',
      );
      return;
    }

    openSubsection(BreatheScreen(onBack: closeSubsection));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BrieThemeController.instance,
      builder: (context, child) {
        final palette = BrieThemeController.instance.currentPalette;

        return Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(fontSize: 16, color: palette.muted),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Choose what feels closest 💗',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mood selector
                  SizedBox(
                    height: 126,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _moods.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final mood = _moods[index];
                        final name = mood['name']!;
                        final emoji = mood['emoji']!;
                        final isSelected = _selectedMood == name;

                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: '$name mood',
                          child: GestureDetector(
                            onTap: () => _selectMood(name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              width: 105,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.card
                                    : palette.surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? palette.accent
                                      : palette.muted.withValues(alpha: 0.35),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.08 : 1,
                                    duration: const Duration(milliseconds: 250),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 34),
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: palette.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Mood message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Container(
                      key: ValueKey(_selectedMood),
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🌸', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Today’s gentle message',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: palette.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _getMoodMessage(),
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: palette.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        'Feeling ${_selectedMood.toLowerCase()} today',
                        key: ValueKey(_selectedMood),
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Green breathing card — independent of app theme
                  Semantics(
                    button: true,
                    label: 'Take a moment. Open breathing exercise.',
                    child: GestureDetector(
                      onTap: _openBreatheScreen,
                      child: Container(
                        width: double.infinity,
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 167, 252, 207),
                              Color.fromARGB(255, 175, 255, 255),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 18,
                              top: 18,
                              child: Icon(
                                Icons.spa_rounded,
                                size: 82,
                                color: const Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ).withValues(alpha: 0.45),
                              ),
                            ),
                            Positioned(
                              right: 34,
                              bottom: 20,
                              child: Icon(
                                Icons.air_rounded,
                                size: 55,
                                color: const Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '🌿 Take a moment',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF385A45),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const SizedBox(
                                    width: 250,
                                    child: Text(
                                      'Pause, breathe, and give yourself a little space.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 15,
                                        height: 1.45,
                                        color: Color.fromARGB(255, 0, 138, 69),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Tap to begin',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 15, 17, 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Encouragement card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💗', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A little encouragement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _encouragement,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
