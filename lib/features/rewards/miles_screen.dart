import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/app_header_brand.dart';
import '../../../shared/widgets/app_footer_brand.dart';
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
                      ...data.airlinePrograms.map((prog) => _buildProgramTile(context, prog, nf, operations)),
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
                      ...data.bankPrograms.map((prog) => _buildProgramTile(context, prog, nf, operations)),
                    const SizedBox(height: 28),

                    // 5. Other Programs Section
                    _buildSectionHeader(
                      title: 'OTHER PROGRAMS',
                      onAdd: () => _showAddProgramDialog(context, 'other', operations),
                    ),
                    const SizedBox(height: 12),
                    if (data.otherPrograms.isEmpty)
                      _buildEmptyState(
                        'No other programs yet — tap + to add one (e.g. Heymax Max Miles).',
                      )
                    else
                      ...data.otherPrograms.map((prog) => _buildProgramTile(context, prog, nf, operations)),
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
                  const SizedBox(height: 16),
                  const AppFooterBrand(),
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

  Widget _buildProgramTile(BuildContext context, MilesWalletData prog, NumberFormat nf, MilesOperations ops) {
    final lastUpdatedDate = DateTime.fromMillisecondsSinceEpoch(prog.lastUpdated * 1000);
    final asOfStr = 'as of ${DateFormat('d MMM yyyy').format(lastUpdatedDate)}';

    return GestureDetector(
      onTap: () => _showEditProgramDialog(context, prog, ops),
      child: Container(
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
                prog.programType == 'airline'
                    ? Icons.flight_takeoff
                    : (prog.programType == 'other' ? Icons.loyalty_rounded : Icons.stars_rounded),
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
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  InputDecoration _buildDialogInputDecoration({
    required String hintText,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _showEditProgramDialog(BuildContext context, MilesWalletData prog, MilesOperations ops) {
    final balCtrl = TextEditingController(text: prog.balance.toInt().toString());
    final nf = NumberFormat('#,##0');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        prog.programType == 'airline'
                            ? Icons.flight_takeoff
                            : (prog.programType == 'other' ? Icons.loyalty_rounded : Icons.stars_rounded),
                        size: 20,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current balance: ${nf.format(prog.balance)} miles',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 20),

                // ── Input Field ──
                _buildFieldLabel('UPDATED MILES BALANCE'),
                TextField(
                  controller: balCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  decoration: _buildDialogInputDecoration(
                    hintText: 'Enter new balance',
                    suffixText: 'mi',
                  ),
                ),
                const SizedBox(height: 24),

                // ── Action Buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirmDialog(context, prog, ops);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final newBal = double.tryParse(balCtrl.text) ?? prog.balance;
                            ops.updateLoyaltyProgram(
                              id: prog.id,
                              userId: prog.userId,
                              programName: prog.programName,
                              programType: prog.programType,
                              balance: newBal,
                            );
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: const Size(100, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MilesWalletData prog, MilesOperations ops) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 28, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Loyalty Program?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to remove "${prog.programName}"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ops.deleteLoyaltyProgram(prog.id);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(80, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  static const List<String> kAirlineProgramsList = [
    'Air Canada Aeroplan',
    'Air China PhoenixMiles',
    'Air France/KLM Flying Blue',
    'Air New Zealand Airpoints',
    'Alaska Airlines Atmos Rewards Points',
    'All Nippon Airways ANA Mileage Club',
    'American Airlines AAdvantage',
    'Avianca LifeMiles',
    'British Airways Executive Club Mileage Avios',
    'Cathay Pacific Asia Miles',
    'China Airlines Dynasty Flyer',
    'China Eastern Airlines Eastern Miles',
    'Delta Airlines SkyMiles',
    'Emirates Skywards',
    'Etihad Airways Guest',
    'EVA Air Infinity MileageLands',
    'Finnair Plus Avios',
    'Garuda Indonesia GarudaMiles',
    'Hawaiian Airlines (Alaska Atmos as of 2026)',
    'Iberia Plus Mileage Avios',
    'Japan Airlines JAL Mileage Bank',
    'JetBlue TrueBlue points',
    'Korean Air Skypass',
    'Lufthansa Miles & More',
    'Malaysia Airlines Enrich',
    'Qantas Frequent Flyer points',
    'Qatar Airways Privilege Club Avios',
    'Singapore Airlines KrisFlyer',
    'Southwest Rapid Rewards',
    'Thai Airways Royal Orchid Plus',
    'Turkish Airlines Miles&Smiles Frequent Flyer',
    'United Airlines MileagePlus',
    'Vietnam Airlines Lotusmiles',
    'Virgin Atlantic Flying Club',
  ];

  static const List<String> kOtherProgramsList = [
    'Heymax Max Miles',
  ];

  void _showAddProgramDialog(BuildContext context, String type, MilesOperations ops) {
    String selectedProgram = type == 'airline' 
        ? kAirlineProgramsList[27] 
        : (type == 'other' ? kOtherProgramsList[0] : '');
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController();

    final dialogTitle = type == 'airline' 
        ? 'Add Airline Program' 
        : (type == 'other' ? 'Add Other Program' : 'Add Bank Program');

    final iconData = type == 'airline' 
        ? Icons.flight_takeoff 
        : (type == 'other' ? Icons.loyalty_rounded : Icons.stars_rounded);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          dialogTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 20),

                  // ── Program Selector / Input ──
                  if (type == 'airline') ...[
                    _buildFieldLabel('AIRLINE FREQUENT FLYER PROGRAM'),
                    DropdownButtonFormField<String>(
                      value: selectedProgram,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: _buildDialogInputDecoration(hintText: 'Select Program'),
                      items: kAirlineProgramsList.map((prog) {
                        return DropdownMenuItem<String>(
                          value: prog,
                          child: Text(prog, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedProgram = val);
                        }
                      },
                    ),
                  ] else if (type == 'other') ...[
                    _buildFieldLabel('LOYALTY PROGRAM'),
                    DropdownButtonFormField<String>(
                      value: selectedProgram,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: _buildDialogInputDecoration(hintText: 'Select Program'),
                      items: kOtherProgramsList.map((prog) {
                        return DropdownMenuItem<String>(
                          value: prog,
                          child: Text(prog, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedProgram = val);
                        }
                      },
                    ),
                  ] else ...[
                    _buildFieldLabel('PROGRAM NAME'),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: _buildDialogInputDecoration(hintText: 'e.g. Citi Rewards, DBS Points'),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Miles Balance Input ──
                  _buildFieldLabel('CURRENT MILES BALANCE'),
                  TextField(
                    controller: balCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: _buildDialogInputDecoration(
                      hintText: 'e.g. 50000',
                      suffixText: 'mi',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Actions ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final name = (type == 'airline' || type == 'other') ? selectedProgram : nameCtrl.text.trim();
                          final bal = int.tryParse(balCtrl.text) ?? 0;
                          if (name.isNotEmpty) {
                            ops.addLoyaltyProgram(programName: name, programType: type, balance: bal);
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          minimumSize: const Size(100, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Add Program', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, MilesOperations ops) {
    final destCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pin_drop, size: 20, color: AppColors.error),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Set Travel Goal',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 20),

                // ── Inputs ──
                _buildFieldLabel('DESTINATION'),
                TextField(
                  controller: destCtrl,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  decoration: _buildDialogInputDecoration(hintText: 'e.g. Tokyo, London, Paris'),
                ),
                const SizedBox(height: 18),
                _buildFieldLabel('REQUIRED MILES TARGET'),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  decoration: _buildDialogInputDecoration(
                    hintText: 'e.g. 120000',
                    suffixText: 'mi',
                  ),
                ),
                const SizedBox(height: 24),

                // ── Actions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final dest = destCtrl.text.trim();
                        final target = int.tryParse(targetCtrl.text) ?? 0;
                        if (dest.isNotEmpty && target > 0) {
                          ops.upsertTravelGoal(destination: dest, targetMiles: target);
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        minimumSize: const Size(90, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Set Goal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
