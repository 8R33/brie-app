import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'breathe_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Widget screen)? onOpenSubsection;

  const HomeScreen({super.key, this.onOpenSubsection});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressTime;

  // ===============================================================
  // ENCOURAGEMENT MESSAGES
  // ===============================================================

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

  // ===============================================================
  // MOODS
  // ===============================================================

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

  // ===============================================================
  // MOOD MESSAGE LIBRARY
  // ===============================================================

  final Map<String, List<String>> _moodMessages = {
    'Happy': [
      'Hold onto this little moment of happiness. You deserve to enjoy it fully. 🌸',
      'There is something beautiful about feeling good today. Let yourself enjoy it. 🦋',
      'You don’t need a reason to smile. Let yourself have this moment. 💗',
      'Whatever brought this happiness, take a moment to appreciate it. 🌷',
      'Let this little bit of joy stay with you for a while. You deserve it. ☀️',
      'It’s okay to simply enjoy feeling good. You don’t have to make it complicated. 🌸',
      'Something feels a little lighter today. Let yourself notice that. 🌿',
      'Keep a little space in your day for the things that make you smile. 💗',
      'You are allowed to celebrate the small things too. They matter. 🦋',
      'Let today be a reminder that beautiful moments can find you unexpectedly. 🌷',
      'Take a mental picture of this feeling. It is worth remembering. ☀️',
      'You don’t have to hold onto happiness tightly. Just let yourself experience it. 💕',
    ],
    'Sad': [
      'It’s okay not to feel okay today. You don’t have to rush yourself out of it. 🌷',
      'You don’t have to pretend to be fine. Give yourself permission to feel what you feel. 💗',
      'Some days are heavier than others. Be especially gentle with yourself today. 🌿',
      'You can take today slowly. There is no prize for rushing through difficult feelings. 🦋',
      'Whatever is hurting right now deserves kindness, not criticism. 🌸',
      'You don’t have to figure everything out today. One gentle moment is enough. 💕',
      'It’s okay if all you can do today is take things one step at a time. 🌷',
      'Your feelings are not a failure. They are simply asking to be acknowledged. 💗',
      'You are allowed to have a difficult day without letting it define you. 🌿',
      'Be patient with yourself. Some feelings need time before they become lighter. 🦋',
      'If today feels heavy, you don’t have to carry everything at once. 🌸',
      'Tonight or tomorrow may feel different. For now, just be gentle with yourself. 🌙',
    ],
    'Emotional': [
      'Whatever you’re feeling right now is allowed to be here. Be gentle with yourself. 💗',
      'You don’t have to explain every feeling. Sometimes you can simply let it exist. 🌷',
      'Take a moment to notice what your heart is trying to tell you. 🦋',
      'Being emotional doesn’t mean you are weak. It means something matters to you. 💕',
      'Give yourself some space today. You don’t have to process everything at once. 🌿',
      'It’s okay if your feelings feel bigger than usual today. Take things slowly. 🌸',
      'You can feel deeply and still be okay. Let yourself move through it gently. 💗',
      'There is no need to judge yourself for having feelings. You are human. 🦋',
      'If you need to pause, pause. If you need to breathe, breathe. 🌷',
      'Your emotions deserve compassion, especially from you. 💕',
      'Some feelings arrive without warning. You can meet them without rushing them away. 🌿',
      'Whatever today brings emotionally, you don’t have to face every feeling at once. 🌸',
    ],
    'Angry': [
      'You don’t have to solve everything while you’re feeling overwhelmed. Give yourself a moment. 🌿',
      'Before reacting, give yourself permission to pause. You can choose your next step later. 🦋',
      'It’s okay to be angry. Give yourself some space before deciding what to do with the feeling. 💗',
      'Take a slow breath and let the intensity settle before you make any decisions. 🌷',
      'You can acknowledge your anger without letting it decide everything for you. 🌿',
      'Sometimes a little distance can make a difficult situation feel clearer. Take your space. 💕',
      'You don’t have to respond immediately. A pause is allowed. 🦋',
      'Let yourself cool down. You can come back to the situation when you feel ready. 🌸',
      'Your feelings are valid, and you can still choose how you respond to them. 💗',
      'Give yourself a few quiet moments before carrying the conversation forward. 🌿',
      'You are allowed to step away from what is frustrating you for a little while. 🌷',
      'Breathe first. Decide later. You don’t have to figure everything out in this moment. 🦋',
    ],
    'Anxious': [
      'You don’t have to figure everything out right now. Come back to this moment, one breath at a time. 🦋',
      'You only need to deal with what is in front of you right now. The rest can wait. 🌿',
      'Take one slow breath. You are here, and this moment is enough for now. 💗',
      'You don’t need to know exactly what happens next. Let yourself take things step by step. 🌷',
      'Your mind may be thinking far ahead. Gently bring yourself back to where you are. 🦋',
      'You can take a pause before dealing with whatever comes next. 🌸',
      'Not every thought needs an answer immediately. Let some thoughts pass by. 🌿',
      'Focus on this breath, this moment, and this small space around you. 💕',
      'You are allowed to slow down even when your thoughts feel fast. 🌷',
      'Take today one manageable moment at a time. You don’t need to solve the whole day. 🦋',
      'It’s okay not to have everything under control. Give yourself some breathing room. 💗',
      'Come back to your senses: notice what you can see, hear, and feel right now. 🌿',
    ],
    'Calm': [
      'Let yourself enjoy this quiet moment. There is no need to rush. 🌿',
      'Stay here for a little while. You deserve moments that feel peaceful. 🌸',
      'Notice how it feels when you give yourself permission to slow down. 🦋',
      'You don’t always need to be doing something. Sometimes simply being is enough. 💗',
      'Let this peaceful moment be exactly what it is. You don’t have to ask more from it. 🌷',
      'There is beauty in a quiet mind and a slower moment. Take it in. 🌿',
      'You found a little stillness. Give yourself permission to enjoy it. 🦋',
      'Keep a little of this calm with you as you move through the rest of your day. 💕',
      'Nothing needs to happen right this second. Just breathe and be here. 🌸',
      'Peace doesn’t always have to be a big moment. Sometimes it is simply a quiet breath. 🌿',
      'Let your shoulders soften and your breathing slow. You have time. 💗',
      'This moment doesn’t need to be productive. Let it simply be peaceful. 🌷',
    ],
    'Tired': [
      'Maybe today doesn’t need your maximum effort. It’s okay to move a little slower. 🌙',
      'You are allowed to rest without feeling guilty about it. 💗',
      'Your energy matters too. Give yourself permission to conserve some of it today. 🌿',
      'You don’t have to be productive every moment. Rest is part of taking care of yourself. 🦋',
      'Move gently today. You don’t need to push yourself beyond what you have. 🌷',
      'Sometimes the kindest thing you can do is pause. Give yourself that permission. 🌙',
      'You can take things one small task at a time. Everything doesn’t need to happen today. 💕',
      'Your body and mind deserve moments of quiet too. Be gentle with them. 🌿',
      'It’s okay if today feels slower than usual. Slow is still moving. 🦋',
      'You don’t have to earn your rest. You are allowed to need it. 💗',
      'If you can, give yourself something simple today: water, food, rest, or a quiet moment. 🌷',
      'There will be another day for doing more. For now, take care of yourself. 🌙',
    ],
    'Okay': [
      'You don’t have to feel amazing every day. Being okay is enough for today. 🌸',
      'Maybe today is simply an ordinary day. Ordinary days deserve kindness too. 🌿',
      'You don’t need a big feeling to make this moment meaningful. 💗',
      'Being somewhere in the middle is completely okay. You can simply be here. 🦋',
      'You don’t have to force yourself to feel happier than you do. 🌷',
      'Take the day as it comes. There is no need to create a perfect feeling. 💕',
      'Sometimes “I’m okay” is more than enough. Give yourself credit for that. 🌸',
      'You can let today unfold without asking too much of yourself. 🌿',
      'Not every day needs to be memorable. Some days can simply be gentle. 🦋',
      'Give yourself room to feel exactly where you are today. 💗',
      'You are allowed to have an ordinary day and still take good care of yourself. 🌷',
      'Whatever today becomes, you can meet it one moment at a time. 🌿',
    ],
    'Loved': [
      'Let yourself receive the warmth around you. You deserve to feel loved and cared for. 💗',
      'Someone thinking of you, caring for you, or simply being there matters. Let it in. 🌸',
      'You deserve relationships where you can feel safe, valued, and appreciated. 🦋',
      'Let yourself enjoy the feeling of being cared for. You don’t have to question it. 💕',
      'Love can be found in the little things too: a message, a smile, a kind word. 🌷',
      'Hold onto the people and moments that make your heart feel a little lighter. 💗',
      'You deserve kindness, tenderness, and patience — including from yourself. 🌿',
      'Let yourself appreciate the love that exists in your life today. 🌸',
      'Sometimes love is quiet. A small gesture can still mean a lot. 🦋',
      'You are worthy of being cared for exactly as you are. 💕',
      'Allow yourself to feel grateful for the people who bring warmth into your life. 🌷',
      'Carry a little of that love with you wherever you go today. 💗',
    ],
  };

  // ===============================================================
  // TRACK MESSAGES ALREADY SHOWN
  // ===============================================================

  final Map<String, Set<String>> _seenMoodMessages = {};

  // ===============================================================
  // STATE
  // ===============================================================

  late String _encouragement;

  String _selectedMood = 'Happy';

  // ===============================================================
  // INIT
  // ===============================================================

  @override
  void initState() {
    super.initState();

    final random = Random();

    _encouragement = _encouragements[random.nextInt(_encouragements.length)];
  }

  // ===============================================================
  // GREETING
  // ===============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    final user = FirebaseAuth.instance.currentUser;

    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Bree';

    if (hour >= 5 && hour < 12) {
      return 'Good morning, $name 🌷';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $name ☀️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening, $name 🌸';
    } else {
      return 'Good night, $name 🌙';
    }
  }

  // ===============================================================
  // CURRENT MOOD MESSAGE
  // ===============================================================

  String _getMoodMessage() {
    final messages = _moodMessages[_selectedMood] ?? [];

    if (messages.isEmpty) {
      return 'Take today one gentle moment at a time. 🌷';
    }

    final seenMessages = _seenMoodMessages[_selectedMood] ?? <String>{};

    final availableMessages = messages
        .where((message) => !seenMessages.contains(message))
        .toList();

    if (availableMessages.isEmpty) {
      seenMessages.clear();
      availableMessages.addAll(messages);
    }

    final random = Random();

    final message = availableMessages[random.nextInt(availableMessages.length)];

    seenMessages.add(message);

    _seenMoodMessages[_selectedMood] = seenMessages;

    return message;
  }

  // ===============================================================
  // SELECT MOOD
  // ===============================================================

  void _selectMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
  }

  // ===============================================================
  // OPEN BREATHE SCREEN
  // ===============================================================
  //
  // IMPORTANT:
  // We no longer use Navigator.push().
  //
  // MainNavigationScreen receives this request and temporarily
  // replaces the main navigation with BreatheScreen.
  // ===============================================================

  void _openBreatheScreen() {
    widget.onOpenSubsection?.call(const BreatheScreen());
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFFFF4F7),

        // =========================================================
        // HOME CONTENT
        // =========================================================
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // GREETING
                // =================================================

                Text(
                  _getGreeting(),

                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A4050),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'How are you feeling today?',

                  style: TextStyle(fontSize: 16, color: Color(0xFF806873)),
                ),

                const SizedBox(height: 28),

                // =================================================
                // MOOD SELECTION
                // =================================================
                const Text(
                  'Choose what feels closest 💗',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A4050),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 126,

                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,

                    physics: const BouncingScrollPhysics(),

                    itemCount: _moods.length,

                    separatorBuilder: (context, index) {
                      return const SizedBox(width: 12);
                    },

                    itemBuilder: (context, index) {
                      final mood = _moods[index];

                      final name = mood['name']!;
                      final emoji = mood['emoji']!;

                      final isSelected = _selectedMood == name;

                      return GestureDetector(
                        onTap: () {
                          _selectMood(name);
                        },

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
                                ? const Color(0xFFFFE0EA)
                                : Colors.white,

                            borderRadius: BorderRadius.circular(22),

                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC75D83)
                                  : const Color(0xFFF0E3E8),

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
                                scale: isSelected ? 1.08 : 1.0,

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

                                  color: const Color(0xFF5A4050),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // TODAY'S GENTLE MESSAGE
                // =================================================
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),

                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,

                  child: Container(
                    key: ValueKey(_selectedMood),

                    width: double.infinity,

                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8EF),

                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            const Text('🌸', style: TextStyle(fontSize: 22)),

                            const SizedBox(width: 10),

                            const Text(
                              'Today’s gentle message',

                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A5368),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          _getMoodMessage(),

                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5A4050),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // SELECTED MOOD INDICATOR
                // =================================================
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),

                    child: Text(
                      'Feeling ${_selectedMood.toLowerCase()} today',

                      key: ValueKey(_selectedMood),

                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9A8991),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // TAKE A MOMENT / BREATHE
                // =================================================
                GestureDetector(
                  onTap: _openBreatheScreen,

                  child: Container(
                    width: double.infinity,
                    height: 190,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),

                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,

                        colors: [Color(0xFFDCEFE5), Color(0xFFCFE5DC)],
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

                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),

                        Positioned(
                          right: 34,
                          bottom: 20,

                          child: Icon(
                            Icons.air_rounded,

                            size: 55,

                            color: Colors.white.withValues(alpha: 0.35),
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
                                    fontSize: 15,
                                    height: 1.45,
                                    color: Color(0xFF527061),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                'Tap anywhere to begin',

                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6D8876),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // ENCOURAGEMENT
                // =================================================
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D9),

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
                            const Text(
                              'A little encouragement',

                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF76563D),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              _encouragement,

                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Color(0xFF80664F),
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
      ),
    );
  }
}
