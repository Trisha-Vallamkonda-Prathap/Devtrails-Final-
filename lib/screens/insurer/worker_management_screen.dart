import 'package:flutter/material.dart';

import '../../data/insurer/mock_data.dart';
import '../../models/insurer_models.dart';
import '../../theme/insurer_colors.dart';
import '../../widgets/insurer/worker_list_tile.dart';
import 'worker_profile_sheet.dart';

enum WorkerFilterMode { all, flagged, lowTrust, byCity }

class WorkerManagementScreen extends StatefulWidget {
  const WorkerManagementScreen({super.key});

  @override
  State<WorkerManagementScreen> createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  WorkerFilterMode _mode = WorkerFilterMode.all;
  String? _city;

  List<InsurerWorker> get _workers {
    var items = mockWorkers;
    switch (_mode) {
      case WorkerFilterMode.flagged:
        items = items.where((worker) => worker.isFlagged).toList();
        break;
      case WorkerFilterMode.lowTrust:
        items = items.where((worker) => worker.trustScore < 40).toList();
        break;
      case WorkerFilterMode.byCity:
        if (_city != null) {
          items = items.where((worker) => worker.city == _city).toList();
        }
        break;
      case WorkerFilterMode.all:
        break;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cities = mockWorkers.map((worker) => worker.city).toSet().toList()..sort();
    return Scaffold(
      backgroundColor: InsurerColors.background,
      appBar: AppBar(
        backgroundColor: InsurerColors.background,
        elevation: 0,
        title: const Text(
          'Worker Management',
          style: TextStyle(color: InsurerColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: _mode == WorkerFilterMode.all,
                onTap: () => setState(() {
                  _mode = WorkerFilterMode.all;
                  _city = null;
                }),
              ),
              _FilterChip(
                label: 'Flagged',
                selected: _mode == WorkerFilterMode.flagged,
                onTap: () => setState(() {
                  _mode = WorkerFilterMode.flagged;
                  _city = null;
                }),
              ),
              _FilterChip(
                label: 'Low Trust',
                selected: _mode == WorkerFilterMode.lowTrust,
                onTap: () => setState(() {
                  _mode = WorkerFilterMode.lowTrust;
                  _city = null;
                }),
              ),
              _FilterChip(
                label: 'By City',
                selected: _mode == WorkerFilterMode.byCity,
                onTap: () => setState(() => _mode = WorkerFilterMode.byCity),
              ),
            ],
          ),
          if (_mode == WorkerFilterMode.byCity) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final selected = _city == city;
                  return ChoiceChip(
                    label: Text(city),
                    selected: selected,
                    onSelected: (_) => setState(() => _city = city),
                    selectedColor: InsurerColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected ? InsurerColors.textPrimary : InsurerColors.textSecondary,
                    ),
                    backgroundColor: InsurerColors.surface,
                    side: const BorderSide(color: InsurerColors.border),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: cities.length,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ..._workers.map(
            (worker) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WorkerListTile(
                worker: worker,
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => WorkerProfileSheet(worker: worker),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: InsurerColors.accent.withValues(alpha: 0.18),
      backgroundColor: InsurerColors.surface,
      side: const BorderSide(color: InsurerColors.border),
      labelStyle: TextStyle(
        color: selected ? InsurerColors.textPrimary : InsurerColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}