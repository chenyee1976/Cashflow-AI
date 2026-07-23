import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/app_header_brand.dart';
import 'miles_provider.dart';

class MilesScreen extends ConsumerWidget {
  const MilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milesDataAsync = ref.watch(milesScreenProvider);
    final operations = ref.read(milesOperationsProvider);
    final nf = NumberFormat('#,##0', 'en_SG');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeaderBrand(),
              const SizedBox(height: 16),
              // 1. Header Title & Subtitle
              const Text(
                'Miles',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Track loyalty balances and travel goals',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              milesDataAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Total Miles Blue Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF0073E6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.wallet_travel_rounded, color: AppColors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'TOTAL MILES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nf.format(data.totalMiles),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Across ${data.programCount} ${data.programCount == 1 ? "program" : "programs"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. Airline Loyalty Programs Section
                    _buildSectionHeader(
                      title: 'AIRLINE LOYALTY PROGRAMS',
                      onAdd: () => _showAddProgramDialog(context, 'airline', operations),
                    ),
                    const SizedBox(height: 12),
                    if (data.airlinePrograms.isEmpty)
                      _buildEmptyState(
                        'No airline programs yet — tap + to add one (e.g. KrisFlyer, Asia Miles).',
                      )
                    else
                      ...data.airlinePrograms.map((prog) => _buildProgramTile(prog, nf)),
                    const SizedBox(height: 28),

                    // 4. Bank Loyalty Programs Section
                    _buildSectionHeader(
                      title: 'BANK LOYALTY PROGRAMS',
                      onAdd: () => _showAddProgramDialog(context, 'bank', operations),
                    ),
                    const SizedBox(height: 12),
                    if (data.bankPrograms.isEmpty)
                      _buildEmptyState(
                        'No bank programs yet — tap + to add one (e.g. DBS Points, UOB Rewards).',
                      )
                    else
                      ...data.bankPrograms.map((prog) => _buildProgramTile(prog, nf)),
                    const SizedBox(height: 28),

                    // 5. Travel Goals Section
                    _buildSectionHeader(
                      title: 'TRAVEL GOALS',
                      onAdd: () => _showAddGoalDialog(context, operations),
                    ),
                    const SizedBox(height: 12),
                    if (data.travelGoal == null)
                      _buildEmptyState(
                        'Set a destination and miles target to track progress.',
                      )
                    else
                      _buildGoalCard(data.travelGoal!, data.totalMiles, nf),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  Widget _buildProgramTile(MilesWalletData prog, NumberFormat nf) {
    final lastUpdatedDate = DateTime.fromMillisecondsSinceEpoch(prog.lastUpdated * 1000);
    final asOfStr = 'as of ${DateFormat('d MMM yyyy').format(lastUpdatedDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              prog.programType == 'airline' ? Icons.flight_takeoff : Icons.stars_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prog.programName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  asOfStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${nf.format(prog.balance)} mi',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(TravelGoal goal, double currentTotal, NumberFormat nf) {
    final double percent = goal.milesRequired > 0 ? (currentTotal / goal.milesRequired).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    goal.destination,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${nf.format(currentTotal)} mi accumulated',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'Goal: ${nf.format(goal.milesRequired)} mi',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddProgramDialog(BuildContext context, String type, MilesOperations ops) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${type == "airline" ? "Airline" : "Bank"} Program'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Program Name (e.g. KrisFlyer)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: balCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current Miles Balance'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final bal = int.tryParse(balCtrl.text) ?? 0;
              if (name.isNotEmpty) {
                ops.addLoyaltyProgram(programName: name, programType: type, balance: bal);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, MilesOperations ops) {
    final destCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Travel Goal'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: destCtrl,
              decoration: const InputDecoration(labelText: 'Destination (e.g. London)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Required Miles'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final dest = destCtrl.text.trim();
              final target = int.tryParse(targetCtrl.text) ?? 0;
              if (dest.isNotEmpty && target > 0) {
                ops.upsertTravelGoal(destination: dest, targetMiles: target);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}
