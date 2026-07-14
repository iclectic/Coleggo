import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/commuter_profile.dart';
import '../state/providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _vehicle = TextEditingController();
  CommuteRole _role = CommuteRole.passenger;
  String _area = MockData.areas.first;
  final Set<int> _days = {1, 2, 3};
  int _arrival = 510;
  int _departure = 1050;
  int _seats = 2;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(appControllerProvider).profile;
    if (existing != null) {
      _name.text = existing.firstName;
      _vehicle.text = existing.vehicleSummary ?? '';
      _role = existing.role;
      _area = existing.homeArea;
      _days
        ..clear()
        ..addAll(existing.days);
      _arrival = existing.arrivalMinutes;
      _departure = existing.departureMinutes;
      _seats = existing.availableSeats;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<int?> _pickTime(int current) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    return result == null ? null : result.hour * 60 + result.minute;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one commuting day.')),
      );
      return;
    }
    setState(() => _saving = true);
    final state = ref.read(appControllerProvider);
    final name = _name.text.trim();
    final words = name.split(RegExp(r'\s+'));
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    final profile = CommuterProfile(
      id: 'local-user',
      firstName: words.first,
      initials: initials,
      role: _role,
      workplaceId: state.selectedWorkplaceId!,
      worksiteId: state.selectedWorksiteId!,
      homeArea: _area,
      corridor: MockData.areaCorridors[_area]!,
      days: Set.of(_days),
      arrivalMinutes: _arrival,
      departureMinutes: _departure,
      availableSeats: _role.canDrive ? _seats : 0,
      vehicleSummary: _role.canDrive && _vehicle.text.trim().isNotEmpty
          ? _vehicle.text.trim()
          : null,
    );
    await ref
        .read(appControllerProvider.notifier)
        .saveProfileAndCommute(profile);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final worksite = MockData.worksite(
      state.selectedWorksiteId ?? 'central_exchange',
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.setupComplete ? 'Edit commuter profile' : 'Set up your commute',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxFormWidth,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                Text(
                  'A few details for better matches',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use a broad home area. Coleggo does not need your exact address for this prototype.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    helperText: 'Only your first name and initials are shown',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'How will you commute?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<CommuteRole>(
                  segments: CommuteRole.values
                      .map(
                        (role) => ButtonSegment(
                          value: role,
                          label: Text(role.label),
                          icon: Icon(switch (role) {
                            CommuteRole.driver => Icons.directions_car_rounded,
                            CommuteRole.passenger =>
                              Icons.airline_seat_recline_normal_rounded,
                            CommuteRole.both => Icons.swap_horiz_rounded,
                          }),
                        ),
                      )
                      .toList(),
                  selected: {_role},
                  onSelectionChanged: (value) =>
                      setState(() => _role = value.first),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _area,
                  decoration: const InputDecoration(
                    labelText: 'Approximate home area',
                    prefixIcon: Icon(Icons.near_me_outlined),
                  ),
                  items: MockData.areas
                      .map(
                        (area) =>
                            DropdownMenuItem(value: area, child: Text(area)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _area = value!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.apartment_rounded),
                  title: Text(worksite.name),
                  subtitle: Text('Worksite · ${worksite.area}'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Commuting days',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _TimeTile(
                        label: 'Arrive by',
                        minutes: _arrival,
                        icon: Icons.login_rounded,
                        onTap: () async {
                          final value = await _pickTime(_arrival);
                          if (value != null) setState(() => _arrival = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeTile(
                        label: 'Leave around',
                        minutes: _departure,
                        icon: Icons.logout_rounded,
                        onTap: () async {
                          final value = await _pickTime(_departure);
                          if (value != null) setState(() => _departure = value);
                        },
                      ),
                    ),
                  ],
                ),
                if (_role.canDrive) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Driver details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _seats,
                    decoration: const InputDecoration(
                      labelText: 'Seats available',
                    ),
                    items: [1, 2, 3, 4]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _seats = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicle,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle summary',
                      hintText: 'For example, blue compact hybrid',
                      helperText: 'Do not enter a registration number',
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.route_rounded),
                  label: Text(
                    state.setupComplete ? 'Save changes' : 'Create my commute',
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

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.minutes,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final int minutes;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(
            formatMinutes(minutes),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
