import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_header_brand.dart';
import 'rewards_provider.dart';
import '../../data/services/card_rules_registry.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String _currentTab = 'cashback'; // Default tab

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    final current = ref.read(rewardsMonthProvider);
    ref.read(rewardsMonthProvider.notifier).state =
        DateTime(current.year, current.month + delta);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(rewardsMonthProvider);
    final cardsAsync = ref.watch(rewardsCardsProvider);
    final monthLabel = "${DateFormat('MMM yyyy').format(selectedMonth)} statement";

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
                child: const AppHeaderBrand(),
              ),
              // ── Header ───────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                child: Text(
                  'Rewards',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // ── Month Selector ───────────────────────────
              _MonthSelector(
                monthLabel: monthLabel,
                onPrev: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),

              const SizedBox(height: 12),

              // Tab Selector (Cashback / Miles)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentTab = 'cashback';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _currentTab == 'cashback'
                                  ? AppColors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _currentTab == 'cashback'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cashback',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _currentTab == 'cashback'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentTab = 'miles';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _currentTab == 'miles'
                                  ? AppColors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _currentTab == 'miles'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Miles',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _currentTab == 'miles'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'REWARDS CALCULATION BY CARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Cards List ───────────────────────────────
              Expanded(
                child: cardsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error: $e')),
                  data: (cards) {
                    if (cards.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'No cards yet.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RecentActivitySection(),
                        ],
                      );
                    }

                    // Filter cards based on local tab switcher state
                    final filteredCards = _filterCardsForFocus(cards, _currentTab);

                    if (filteredCards.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'No ${_currentTab == "miles" ? "miles" : "cashback"} cards found.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RecentActivitySection(),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredCards.length + 1, // +1 for activity
                      itemBuilder: (context, index) {
                        if (index < filteredCards.length) {
                          return _RewardCardTile(
                            card: filteredCards[index],
                            rewardFocus: _currentTab,
                            index: index,
                          );
                        }
                        return _RecentActivitySection();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RewardCardData> _filterCardsForFocus(
      List<RewardCardData> cards, String focus) {
    if (focus == 'both') return cards;
    return cards.where((c) {
      if (focus == 'miles') {
        return c.rewardType == 'miles' || c.rewardType == 'points';
      } else {
        return c.rewardType == 'cashback';
      }
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// Month Selector Widget
// ─────────────────────────────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
          const SizedBox(width: 12),
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
          const Spacer(),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryLight,
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reward Card Tile — the main card per credit card
// ─────────────────────────────────────────────────────────────
class _RewardCardTile extends StatefulWidget {
  final RewardCardData card;
  final String rewardFocus;
  final int index;

  const _RewardCardTile({
    required this.card,
    required this.rewardFocus,
    required this.index,
  });

  @override
  State<_RewardCardTile> createState() => _RewardCardTileState();
}

class _RewardCardTileState extends State<_RewardCardTile> {
  bool _isExpanded = false; // Default: minimised

  bool get _showMiles =>
      widget.rewardFocus == 'miles' ||
      (widget.rewardFocus == 'both' &&
          (widget.card.rewardType == 'miles' || widget.card.rewardType == 'points'));

  bool get _showCashback =>
      widget.rewardFocus == 'cashback' ||
      (widget.rewardFocus == 'both' && widget.card.rewardType == 'cashback');

  bool get _showBothColumns =>
      widget.rewardFocus == 'both' &&
      (widget.card.rewardType != 'miles' && widget.card.rewardType != 'cashback');

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card Header ──────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _CardHeader(card: widget.card),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
              
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),

                // ── Conditional Reward Sections ──────────
                if (_showMiles && _showCashback) ...[
                  _DualColumnRewards(card: widget.card),
                ] else if (_showMiles) ...[
                  _MilesOnlySection(card: widget.card),
                ] else if (_showCashback) ...[
                  _CashbackOnlySection(card: widget.card),
                ] else if (_showBothColumns) ...[
                  _DualColumnRewards(card: widget.card),
                ] else ...[
                  if (widget.card.rewardType == 'miles' || widget.card.rewardType == 'points')
                    _MilesOnlySection(card: widget.card)
                  else
                    _CashbackOnlySection(card: widget.card),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card Header (Icon + Name + Bank + Last4)
// ─────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final RewardCardData card;
  const _CardHeader({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.credit_card_rounded,
            color: AppColors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.cardName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${card.bankName} · •••• ${card.lastFour}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Reward type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: card.rewardType == 'miles' || card.rewardType == 'points'
                ? const Color(0xFFE8F4FF)
                : const Color(0xFFE8FFE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            card.rewardType == 'miles'
                ? '✈ Miles'
                : card.rewardType == 'points'
                    ? '⭐ Points'
                    : '💰 Cashback',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: card.rewardType == 'miles' || card.rewardType == 'points'
                  ? AppColors.primary
                  : AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MILES-ONLY Section (when user chose "miles" focus)
// ─────────────────────────────────────────────────────────────
class _MilesOnlySection extends StatelessWidget {
  final RewardCardData card;
  const _MilesOnlySection({required this.card});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0', 'en_SG');
    final cf = NumberFormat('#,##0.00', 'en_SG');

    return Column(
      children: [
        _MetricRow(
          icon: Icons.flight_takeoff_rounded,
          iconColor: AppColors.primary,
          label: 'OPENING BALANCE MILES',
          value: '${nf.format(card.milesOpening)} mi',
          valueColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 14),
        _MetricRow(
          icon: Icons.add_circle_outline_rounded,
          iconColor: AppColors.primary,
          label: 'MILES EARNED THIS MONTH (STATEMENT)',
          value: '${nf.format(card.milesEarnedStatement)} mi',
          valueColor: AppColors.primary,
          highlighted: card.milesEarnedStatement > 0,
        ),
        const SizedBox(height: 14),
        _MetricRow(
          icon: Icons.star_border_rounded,
          iconColor: AppColors.primary,
          label: 'BONUS MILES EARNED THIS MONTH',
          value: '${nf.format(card.milesBonus)} mi',
          valueColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 14),
        _MetricRow(
          icon: Icons.remove_circle_outline_rounded,
          iconColor: AppColors.warning,
          label: 'MILES REDEEMED / ADJUSTED',
          value: '${nf.format(card.milesRedeemed)} mi',
          valueColor: AppColors.textSecondary,
        ),
        const SizedBox(height: 14),
        _MetricRow(
          icon: Icons.sports_score_rounded,
          iconColor: AppColors.success,
          label: 'ENDING BALANCE MILES',
          value: '${nf.format(card.milesEnding)} mi',
          valueColor: AppColors.success,
        ),
        const SizedBox(height: 14),
        
        if (card.milesRates.isNotEmpty) ...[
          for (final rate in card.milesRates) ...[
            _MetricRow(
              icon: Icons.speed_rounded,
              iconColor: AppColors.primary,
              label: 'MILES EARNED RATE (S\$1)',
              value: '${rate['rate']} miles',
              sublabel: rate['category']?.toString() ?? 'All Spend',
              valueColor: AppColors.textPrimary,
            ),
            const SizedBox(height: 14),
          ],
          _MetricRow(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.warning,
            label: 'MIN SPEND TO EARN MILES',
            value: (double.tryParse(card.milesRates.first['minSpend']?.toString() ?? '') ?? card.milesMinSpend) > 0
                ? 'S\$${cf.format(double.tryParse(card.milesRates.first['minSpend']?.toString() ?? '') ?? card.milesMinSpend)}'
                : '—',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.error,
            label: 'MAX SPEND CAP TO EARN MILES',
            value: (double.tryParse(card.milesRates.first['maxSpend']?.toString() ?? '') ?? card.milesMaxSpend) > 0
                ? 'S\$${cf.format(double.tryParse(card.milesRates.first['maxSpend']?.toString() ?? '') ?? card.milesMaxSpend)}'
                : '—',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
        ] else ...[
          _MetricRow(
            icon: Icons.speed_rounded,
            iconColor: AppColors.primary,
            label: 'MILES EARNED RATE',
            value: '${card.milesEarnedRate} miles per S\$1',
            sublabel: card.milesRateType,
            valueColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.warning,
            label: 'MIN SPEND TO EARN MILES',
            value: card.milesMinSpend > 0 ? 'S\$${cf.format(card.milesMinSpend)}' : '—',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.error,
            label: 'MAX SPEND CAP TO EARN MILES',
            value: card.milesMaxSpend > 0 ? 'S\$${cf.format(card.milesMaxSpend)}' : '—',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
        ],

        _MetricRow(
          icon: Icons.shopping_bag_rounded,
          iconColor: AppColors.primary,
          label: 'TOTAL SPEND THIS MONTH',
          value: 'S\$${cf.format(card.cardSpendThisMonth)}',
          valueColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 20),

        _CalculatedResultBox(
          icon: Icons.flight_rounded,
          label: 'CALCULATED MILES FOR THE MONTH',
          formula: 'Sum of all eligible miles transactions',
          result: '= ${nf.format(card.calculatedMiles.round())} mi',
          color: AppColors.primary,
        ),
        
        if (card.transactions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: const [
              Icon(Icons.list_alt_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'CALCULATED MILES BREAKDOWN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: card.transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final tx = card.transactions[index];
                final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000));
                final rule = CardRulesRegistry.getRule(card.bankName, card.cardName);
                
                double amt = tx.amount.abs();
                if (rule.floorSpendToDollar) {
                  amt = (amt / rule.spendBlock).floorToDouble() * rule.spendBlock;
                }
                final rate = card.getMilesRateForTx(tx);
                final rawMiles = amt * rate;
                double finalMiles = rawMiles;
                switch (rule.roundingMethod) {
                  case RoundingMethod.nearest:
                    finalMiles = rawMiles.roundToDouble();
                    break;
                  case RoundingMethod.floor:
                    finalMiles = rawMiles.floorToDouble();
                    break;
                  case RoundingMethod.ceil:
                    finalMiles = rawMiles.ceilToDouble();
                    break;
                  case RoundingMethod.keepDecimal:
                    finalMiles = double.parse(rawMiles.toStringAsFixed(2));
                    break;
                }
                final calculatedTxMiles = finalMiles.round();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.merchant,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dateStr · Rate: ${rate.toStringAsFixed(1)} mi/S\$1',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${nf.format(calculatedTxMiles)} mi',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'S\$${cf.format(amt)}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CASHBACK-ONLY Section (when user chose "cashback" focus)
// ─────────────────────────────────────────────────────────────
class _CashbackOnlySection extends StatelessWidget {
  final RewardCardData card;
  const _CashbackOnlySection({required this.card});

  @override
  Widget build(BuildContext context) {
    final cf = NumberFormat('#,##0.00', 'en_SG');
    final pf = NumberFormat('#,##0.0', 'en_SG');

    return Column(
      children: [
        _MetricRow(
          icon: Icons.monetization_on_rounded,
          iconColor: AppColors.success,
          label: 'CASHBACK EARNED (STATEMENT)',
          value: card.cashbackEarnedStatement > 0
              ? 'S\$${cf.format(card.cashbackEarnedStatement)}'
              : '—',
          valueColor: AppColors.success,
          highlighted: card.cashbackEarnedStatement > 0,
        ),
        const SizedBox(height: 14),
        if (card.cardName.toLowerCase().contains('yuu')) ...[
          // Clean single summary section for DBS Yuu Cards
          for (final rate in card.cashbackRates) ...[
            _MetricRow(
              icon: Icons.speed_rounded,
              iconColor: AppColors.success,
              label: 'CASHBACK EARNED RATE',
              value: '${rate['rate']} yuu points',
              sublabel: rate['category']?.toString() == 'Base Reward' ? 'all spend' : 'Others',
              valueColor: AppColors.textPrimary,
            ),
            const SizedBox(height: 14),
          ],
          _MetricRow(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.warning,
            label: 'MIN SPEND TO EARN CASHBACK FOR OTHERS',
            value: 'S\$800.00',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.error,
            label: 'MAX SPEND CAPPED TO EARN CASHBACK',
            value: '0',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
        ] else if (card.cashbackRates.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(flex: 3, child: Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text('RATE (% CASHBACK)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                ...card.cashbackRates.map((rate) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            rate['category']?.toString() ?? 'All Spend',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${rate['rate']}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (card.cashbackRates.any((r) => (double.tryParse(r['minSpend']?.toString() ?? '') ?? 0.0) > 0)) ...[
            _MetricRow(
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.warning,
              label: 'MIN SPEND TO EARN CASHBACK',
              value: 'S\$${cf.format(double.tryParse(card.cashbackRates.firstWhere((r) => (double.tryParse(r['minSpend']?.toString() ?? '') ?? 0.0) > 0)['minSpend'].toString()) ?? 0.0)}',
              valueColor: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
          ],
          if (card.cashbackRates.any((r) => (double.tryParse(r['maxSpend']?.toString() ?? '') ?? 0.0) > 0)) ...[
            _MetricRow(
              icon: Icons.arrow_upward_rounded,
              iconColor: AppColors.error,
              label: 'MAX SPEND CAP TO EARN CASHBACK',
              value: 'S\$${cf.format(double.tryParse(card.cashbackRates.firstWhere((r) => (double.tryParse(r['maxSpend']?.toString() ?? '') ?? 0.0) > 0)['maxSpend'].toString()) ?? 0.0)}',
              valueColor: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
          ],
        ] else ...[
          _MetricRow(
            icon: Icons.percent_rounded,
            iconColor: AppColors.success,
            label: 'CASHBACK EARNED RATE (%)',
            value: card.cashbackRate > 0
                ? '${pf.format(card.cashbackRate * 100)}%'
                : '—',
            sublabel: _cashbackCategoryLabel(card.cashbackRateCategory),
            valueColor: AppColors.textPrimary,
            editable: true,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.warning,
            label: 'MIN SPEND TO EARN CASHBACK',
            value: card.cashbackMinSpend > 0
                ? 'S\$${cf.format(card.cashbackMinSpend)}'
                : '—',
            valueColor: AppColors.textSecondary,
            editable: true,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.error,
            label: 'MAX SPEND CAPPED TO EARN CASHBACK',
            value: card.cashbackMaxSpend > 0
                ? 'S\$${cf.format(card.cashbackMaxSpend)}'
                : '—',
            valueColor: AppColors.textSecondary,
            editable: true,
          ),
          const SizedBox(height: 14),
        ],
        _MetricRow(
          icon: Icons.shopping_bag_rounded,
          iconColor: AppColors.primary,
          label: 'CARD SPEND THIS MONTH',
          value: 'S\$${cf.format(card.cardSpendThisMonth)}',
          valueColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 16),
        // Calculated Cashback highlight box
        if (card.cardName.toLowerCase().contains('yuu'))
          _CalculatedResultBox(
            icon: Icons.savings_rounded,
            label: 'CALCULATED CASHBACK',
            formula: 'Sum of all eligible yuu points',
            result: '= ${NumberFormat('#,##0.00', 'en_SG').format(card.calculatedCashback)} yuu pts',
            color: AppColors.success,
          )
        else
          _CalculatedResultBox(
            icon: Icons.savings_rounded,
            label: 'CALCULATED CASHBACK',
            formula: card.cashbackRate > 0
                ? 'S\$${cf.format(card.cardSpendThisMonth)} × ${pf.format(card.cashbackRate * 100)}%'
                : 'Set cashback rate to calculate',
            result: card.cashbackRate > 0
                ? '= S\$${cf.format(card.calculatedCashback)}'
                : '—',
            color: AppColors.success,
          ),
        if (card.transactions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'CALCULATED CASHBACK BREAKDOWN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                if (card.cardName.toLowerCase().contains('yuu'))
                  Builder(
                    builder: (context) {
                      final yuuMerchantKeywords = [
                        '7-eleven', '7eleven', 'chagee', 'charge+', 'cold storage',
                        'foodpanda', 'giant', 'guardian', 'gojek', 'singtel', 'simplygo'
                      ];

                      double basePointsSum = 0.0;
                      double bonus1PointsSum = 0.0;
                      double bonus2PointsSum = 0.0;

                      List<Widget> baseRewardItems = [];
                      List<Widget> bonus1RewardItems = [];
                      List<Widget> bonus2RewardItems = [];

                      final validTxs = card.transactions.where((t) => t.amount < 0).toList();

                      // 1. Group all Base Rewards together:
                      for (final tx in validTxs) {
                        final amt = tx.amount.abs();
                        final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000));
                        final basePts = double.parse((amt * 1.0).toStringAsFixed(2));
                        basePointsSum += basePts;

                        baseRewardItems.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Base Reward: ${tx.merchant}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('$dateStr · Rate: 1.0 yuu pts/S\$1', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('+${cf.format(basePts)} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                                    const SizedBox(height: 2),
                                    Text('S\$${cf.format(amt)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // 2. Group all Bonus Reward 1 together:
                      for (final tx in validTxs) {
                        final amt = tx.amount.abs();
                        final merchantLower = tx.merchant.toLowerCase();
                        final isYuuMerchant = yuuMerchantKeywords.any((kw) => merchantLower.contains(kw));
                        final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000));

                        if (isYuuMerchant) {
                          final bonus1Pts = double.parse((amt * 9.0).toStringAsFixed(2));
                          bonus1PointsSum += bonus1Pts;

                          bonus1RewardItems.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bonus Reward 1: ${tx.merchant}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text('$dateStr · Rate: 9.0 yuu pts/S\$1', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('+${cf.format(bonus1Pts)} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                                      const SizedBox(height: 2),
                                      Text('S\$${cf.format(amt)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }

                      // 3. Group all Bonus Reward 2 together:
                      for (final tx in validTxs) {
                        final amt = tx.amount.abs();
                        final merchantLower = tx.merchant.toLowerCase();
                        final isYuuMerchant = yuuMerchantKeywords.any((kw) => merchantLower.contains(kw));
                        final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000));

                        if (isYuuMerchant && card.cardSpendThisMonth >= 800.0) {
                          final bonus2Pts = double.parse((amt * 26.0).toStringAsFixed(2));
                          bonus2PointsSum += bonus2Pts;

                          bonus2RewardItems.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bonus Reward 2 (Min S\$800 met): ${tx.merchant}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text('$dateStr · Rate: 26.0 yuu pts/S\$1', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('+${cf.format(bonus2Pts)} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                                      const SizedBox(height: 2),
                                      Text('S\$${cf.format(amt)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }

                      List<Widget> txListItems = [
                        ...baseRewardItems,
                        ...bonus1RewardItems,
                        ...bonus2RewardItems,
                      ];

                      return Column(
                        children: [
                          ...txListItems,
                          const Divider(height: 1, color: AppColors.divider),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Base Reward Points:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('${cf.format(basePointsSum)} pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Bonus Reward 1 Points:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('${cf.format(bonus1PointsSum)} pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      card.cardSpendThisMonth >= 800.0 ? 'Total Bonus Reward 2 Points:' : 'Total Bonus Reward 2 Points (Below S\$800 threshold):',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    Text('${cf.format(bonus2PointsSum)} pts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bonus2PointsSum > 0 ? AppColors.primary : AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  ...card.transactions.map((tx) {
                    final txRate = card.getRateForTx(tx);
                    final txCashback = tx.amount.abs() * txRate;
                    final formattedDate = DateFormat('dd MMM yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(tx.date * 1000),
                    );
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.merchant,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$formattedDate · ${tx.category}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'S\$${cf.format(tx.amount.abs())}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '@ ${(txRate * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 10, color: AppColors.success),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '+S\$${cf.format(txCashback)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                    ],
                  );
                }).toList(),
                // Summary Total row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Calculated Cashback:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'S\$${cf.format(card.calculatedCashback)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DUAL COLUMN — both Miles & Cashback side by side
// ─────────────────────────────────────────────────────────────
class _DualColumnRewards extends StatelessWidget {
  final RewardCardData card;
  const _DualColumnRewards({required this.card});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0', 'en_SG');
    final cf = NumberFormat('#,##0.00', 'en_SG');

    return Column(
      children: [
        // Side-by-side metrics
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Cashback column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SmallMetric(
                    icon: Icons.monetization_on_rounded,
                    iconColor: AppColors.success,
                    label: 'CASHBACK EARNED\n(STATEMENT)',
                    value: card.cashbackEarnedStatement > 0
                        ? 'S\$${cf.format(card.cashbackEarnedStatement)}'
                        : '—',
                  ),
                  const SizedBox(height: 16),
                  _SmallMetric(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: AppColors.primary,
                    label: 'CARD SPEND THIS MONTH',
                    value: 'S\$${cf.format(card.cardSpendThisMonth)}',
                  ),
                  const SizedBox(height: 16),
                  _SmallMetric(
                    icon: Icons.percent_rounded,
                    iconColor: AppColors.success,
                    label: 'CASHBACK EARNED RATE',
                    value: card.cashbackRate > 0
                        ? '${(card.cashbackRate * 100).toStringAsFixed(1)}%'
                        : '—',
                  ),
                  const SizedBox(height: 16),
                  _SmallMetric(
                    icon: Icons.savings_rounded,
                    iconColor: AppColors.success,
                    label: 'CALCULATED CASHBACK',
                    value: card.cashbackRate > 0
                        ? 'S\$${cf.format(card.calculatedCashback)}'
                        : '—',
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 200,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            // Right: Miles column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SmallMetric(
                    icon: Icons.flight_takeoff_rounded,
                    iconColor: AppColors.primary,
                    label: 'MILES EARNED\n(STATEMENT)',
                    value: card.milesEarnedStatement > 0
                        ? '${nf.format(card.milesEarnedStatement)} mi'
                        : '—',
                  ),
                  const SizedBox(height: 16),
                  _SmallMetric(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: AppColors.primary,
                    label: 'CARD SPEND THIS MONTH',
                    value: 'S\$${cf.format(card.cardSpendThisMonth)}',
                  ),
                  const SizedBox(height: 16),
                  _SmallMetric(
                    icon: Icons.speed_rounded,
                    iconColor: AppColors.primary,
                    label: 'MILES EARNED RATE',
                    value: card.milesEarnedRate > 0
                        ? '${card.milesEarnedRate} miles per S\$1'
                        : '—',
                  ),
                  const SizedBox(height: 16),
                  _SmallMetric(
                    icon: Icons.flight_rounded,
                    iconColor: AppColors.primary,
                    label: 'CALCULATED MILES',
                    value: card.milesEarnedRate > 0
                        ? 'S\$${cf.format(card.cardSpendThisMonth)} × ${card.milesEarnedRate} mi/S\$1 = ${nf.format(card.calculatedMiles.round())} mi'
                        : '—',
                    isHighlighted: card.milesEarnedRate > 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Metric Row (full-width, for single-column layouts)
// ─────────────────────────────────────────────────────────────
class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sublabel;
  final Color valueColor;
  final bool highlighted;
  final bool editable;

  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sublabel,
    required this.valueColor,
    this.highlighted = false,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? iconColor.withOpacity(0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? Border.all(color: iconColor.withOpacity(0.15))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: iconColor.withOpacity(0.8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              highlighted ? FontWeight.w700 : FontWeight.w600,
                          color: valueColor,
                        ),
                      ),
                    ),
                    if (sublabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sublabel!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (editable)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small Metric (for dual-column layout)
// ─────────────────────────────────────────────────────────────
class _SmallMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isHighlighted;

  const _SmallMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: iconColor.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 13 : 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? iconColor : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Calculated Result Highlight Box
// ─────────────────────────────────────────────────────────────
class _CalculatedResultBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String formula;
  final String result;
  final Color color;

  const _CalculatedResultBox({
    required this.icon,
    required this.label,
    required this.formula,
    required this.result,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formula,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recent Activity Section
// ─────────────────────────────────────────────────────────────
class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'RECENT REWARD ACTIVITY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 36,
                color: AppColors.textHint.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No reward earnings recorded for this month yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  context.go('/home/cashflow/upload');
                },
                icon: const Icon(Icons.upload_file_rounded,
                    size: 18, color: AppColors.primary),
                label: const Text(
                  'Upload a card statement',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100), // Bottom padding for tab bar
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'No reward cards yet.\nUpload a credit card statement to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to statement upload
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text(
                'Upload Card Statement',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Functions ────────────────────────────────────────
String _rateTypeLabel(String rateType) {
  switch (rateType) {
    case 'local_spend':
      return 'Local Spend';
    case 'foreign_spend':
      return 'Foreign Spend';
    default:
      return 'All Spend';
  }
}

String _cashbackCategoryLabel(String category) {
  switch (category) {
    case 'groceries':
      return 'Groceries';
    case 'travel':
      return 'Travel';
    case 'dining':
      return 'Dining';
    case 'transport':
      return 'Transport';
    case 'online':
      return 'Online';
    default:
      return 'All Spend';
  }
}
