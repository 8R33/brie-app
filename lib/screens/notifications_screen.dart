import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _background = Color(0xFFFFF4F7);
  static const Color _pink = Color(0xFFC75D83);
  static const Color _text = Color(0xFF5A4050);
  static const Color _muted = Color(0xFF9C8A92);
  static const Color _softPink = Color(0xFFFFE9EF);

  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final Map<String, _Reminder> _reminders = {
    'encouragement': _Reminder(
      title: 'Daily encouragement',
      description: 'A gentle message to remind you that you matter.',
      icon: Icons.favorite_border_rounded,
      hour: 8,
      minute: 0,
    ),
    'breathing': _Reminder(
      title: 'Breathing reminders',
      description: 'Take a pause and make room for a calmer moment.',
      icon: Icons.air_rounded,
      hour: 12,
      minute: 0,
    ),
    'checkin': _Reminder(
      title: 'Evening check-in',
      description: 'A quiet invitation to notice how you are feeling.',
      icon: Icons.nights_stay_outlined,
      hour: 20,
      minute: 0,
    ),
    'milestones': _Reminder(
      title: 'Personal milestones',
      description: 'Celebrate the small steps you take for yourself.',
      icon: Icons.auto_awesome_outlined,
      hour: 18,
      minute: 0,
    ),
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in _reminders.entries) {
        final key = entry.key;
        final reminder = entry.value;

        // Reminders remain off unless the user enabled them.
        reminder.enabled =
            prefs.getBool('brie_notification_${key}_enabled') ?? false;

        reminder.hour =
            prefs.getInt('brie_notification_${key}_hour') ?? reminder.hour;

        reminder.minute =
            prefs.getInt('brie_notification_${key}_minute') ?? reminder.minute;

        final savedDays = prefs.getStringList('brie_notification_${key}_days');

        reminder.days = savedDays == null
            ? {0, 1, 2, 3, 4, 5, 6}
            : savedDays
                  .map(int.tryParse)
                  .whereType<int>()
                  .where((day) => day >= 0 && day <= 6)
                  .toSet();
      }
    } catch (error) {
      debugPrint('Could not load brié notification preferences: $error');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReminder(String key) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final reminder = _reminders[key]!;

      await prefs.setBool('brie_notification_${key}_enabled', reminder.enabled);

      await prefs.setInt('brie_notification_${key}_hour', reminder.hour);

      await prefs.setInt('brie_notification_${key}_minute', reminder.minute);

      await prefs.setStringList(
        'brie_notification_${key}_days',
        reminder.days.map((day) => day.toString()).toList(),
      );

      // Schedule or cancel this reminder on the device.
      await NotificationService.instance.syncReminder(
        key: key,
        enabled: reminder.enabled,
        hour: reminder.hour,
        minute: reminder.minute,
        days: reminder.days,
      );
    } catch (error) {
      debugPrint('Could not save or schedule brié reminder: $error');

      if (mounted) {
        _showMessage('Could not schedule this reminder. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleReminder(String key, bool value) async {
    if (_isSaving) return;

    if (value) {
      bool granted;

      try {
        granted = await NotificationService.instance.requestPermission();
      } catch (error) {
        debugPrint('Could not request notification permission: $error');

        if (mounted) {
          _showMessage('Could not request notification permission.');
        }
        return;
      }

      if (!granted) {
        if (mounted) {
          _showMessage(
            'Notifications are not allowed. Enable them in your phone settings.',
          );
        }
        return;
      }
    }

    setState(() {
      _reminders[key]!.enabled = value;
    });

    await _saveReminder(key);

    if (!mounted) return;

    _showMessage(
      value
          ? 'Your reminder preferences have been saved.'
          : 'Reminder turned off.',
    );
  }

  Future<void> _chooseTime(String key) async {
    if (_isSaving) return;

    final reminder = _reminders[key]!;

    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme
                .copyWith(primary: _pink, surface: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      reminder.hour = selected.hour;
      reminder.minute = selected.minute;
    });

    await _saveReminder(key);
  }

  Future<void> _toggleDay(String key, int day) async {
    if (_isSaving) return;

    final reminder = _reminders[key]!;

    setState(() {
      if (reminder.days.contains(day)) {
        reminder.days.remove(day);
      } else {
        reminder.days.add(day);
      }
    });

    await _saveReminder(key);
  }

  String _formatTime(_Reminder reminder) {
    return TimeOfDay(
      hour: reminder.hour,
      minute: reminder.minute,
    ).format(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _text,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _text, size: 27),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _text,
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'GENTLE REMINDERS',
                    style: TextStyle(
                      color: _pink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                for (final entry in _reminders.entries) ...[
                  _buildReminderCard(entry.key, entry.value),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                _buildPrivacyNote(),
                if (_isSaving) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    color: _pink,
                    backgroundColor: _softPink,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: _softPink,
            child: Icon(Icons.spa_outlined, color: _pink, size: 27),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little reminder, just for you',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'You deserve moments of peace, even on your '
                  'busiest days. Choose what feels right for you.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(String key, _Reminder reminder) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _softPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(reminder.icon, color: _pink, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Switch.adaptive(
                value: reminder.enabled,
                activeTrackColor: _pink,
                onChanged: _isSaving
                    ? null
                    : (value) => _toggleReminder(key, value),
              ),
            ],
          ),
          if (reminder.enabled) ...[
            const SizedBox(height: 16),
            const Divider(color: _softPink, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: _pink, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Reminder time',
                    style: TextStyle(
                      fontSize: 13,
                      color: _text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isSaving ? null : () => _chooseTime(key),
                  style: TextButton.styleFrom(foregroundColor: _pink),
                  child: Text(
                    _formatTime(reminder),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Repeat on',
                style: TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final selected = reminder.days.contains(index);

                return FilterChip(
                  label: Text(_dayNames[index]),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: _softPink,
                  backgroundColor: const Color(0xFFF8F4F6),
                  side: BorderSide(
                    color: selected
                        ? _pink.withValues(alpha: 0.45)
                        : Colors.transparent,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? _pink : _muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: _isSaving ? null : (_) => _toggleDay(key, index),
                );
              }),
            ),
            if (reminder.days.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose at least one day for this reminder.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _softPink.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: _pink, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your routine should work for you. Your reminder '
              'preferences are saved on this device, and you can '
              'change or turn them off whenever you like. '
              'Reminders are scheduled on this device. Delivery '
              'may depend on your phone notification settings.',
              style: TextStyle(color: _text, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Reminder {
  _Reminder({
    required this.title,
    required this.description,
    required this.icon,
    required this.hour,
    required this.minute,
  });

  final String title;
  final String description;
  final IconData icon;

  bool enabled = false;
  int hour;
  int minute;
  Set<int> days = {0, 1, 2, 3, 4, 5, 6};
}
