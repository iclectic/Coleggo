import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/mock/mock_data.dart';
import '../state/providers.dart';

class CommuteFormScreen extends ConsumerStatefulWidget {
  const CommuteFormScreen({super.key});
  @override
  ConsumerState<CommuteFormScreen> createState() => _CommuteFormScreenState();
}

class _CommuteFormScreenState extends ConsumerState<CommuteFormScreen> {
  late String _area;
  late Set<int> _days;
  late int _arrival;
  late int _departure;

  @override
  void initState() {
    super.initState();
    final commute = ref.read(appControllerProvider).commute!;
    _area = commute.homeArea;
    _days = Set.of(commute.days);
    _arrival = commute.arrivalMinutes;
    _departure = commute.departureMinutes;
  }

  Future<void> _pick(bool arrival) async {
    final current = arrival ? _arrival : _departure;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (time != null) {
      setState(
        () => arrival
            ? _arrival = time.hour * 60 + time.minute
            : _departure = time.hour * 60 + time.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commute = ref.watch(appControllerProvider).commute!;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit commute')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _area,
            decoration: const InputDecoration(
              labelText: 'Approximate home area',
            ),
            items: MockData.areas
                .map((area) => DropdownMenuItem(value: area, child: Text(area)))
                .toList(),
            onChanged: (value) => setState(() => _area = value!),
          ),
          const SizedBox(height: 22),
          Text(
            'Commuting days',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: weekdayLabels.entries
                .map(
                  (entry) => FilterChip(
                    label: Text(entry.value),
                    selected: _days.contains(entry.key),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _days.add(entry.key)
                          : _days.remove(entry.key),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: const Icon(Icons.login_rounded),
            title: const Text('Preferred arrival'),
            trailing: Text(
              formatMinutes(_arrival),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () => _pick(true),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Preferred departure'),
            trailing: Text(
              formatMinutes(_departure),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () => _pick(false),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: _days.isEmpty
                ? null
                : () async {
                    await ref
                        .read(appControllerProvider.notifier)
                        .updateCommute(
                          commute.copyWith(
                            homeArea: _area,
                            days: _days,
                            arrivalMinutes: _arrival,
                            departureMinutes: _departure,
                            publicMeetingPoint: '$_area public transport stop',
                          ),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Save commute'),
          ),
        ],
      ),
    );
  }
}
