import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/category_enum.dart';
import '../../../shared/widgets/app_header_brand.dart';
import '../statement/cashflow_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import '../../../core/constants/category_enum.dart';
import '../../dashboard/dashboard_provider.dart';
import '../upload/upload_provider.dart';
import '../../account/account_provider.dart';
import '../statement/cashflow_provider.dart';
import '../upload/draft_statement_service.dart';
import '../../rewards/card_rewards_store.dart';
import '../../../data/services/card_rules_registry.dart';
import '../../../data/services/user_category_rules_service.dart';
import '../../../data/services/merchant_category_classifier.dart';
import '../../../data/services/analytics_service.dart';

class ExtractedAccountItem {
  final TextEditingController bankCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController numCtrl;
  final TextEditingController currencyCtrl;
  final TextEditingController balanceCtrl;
  final TextEditingController fxRateCtrl;
  DateTime balanceAsOf;

  ExtractedAccountItem({
    required String bank,
    required String name,
    required String num,
    required String currency,
    required String balance,
    required this.balanceAsOf,
    String? fxRate,
  })  : bankCtrl = TextEditingController(text: bank),
        nameCtrl = TextEditingController(text: name),
        numCtrl = TextEditingController(text: num),
        currencyCtrl = TextEditingController(text: currency),
        balanceCtrl = TextEditingController(text: balance),
        fxRateCtrl = TextEditingController(text: fxRate ?? _getDefaultFx(currency));

  static String _getDefaultFx(String currency) {
    final cur = currency.trim().toUpperCase();
    if (cur == 'SGD') return '1.0';
    if (cur == 'USD') return '1.30';
    if (cur == 'JPY') return '0.0080';
    if (cur == 'MYR') return '0.30';
    if (cur == 'IDR') return '0.000083';
    return '1.0';
  }

  void dispose() {
    bankCtrl.dispose();
    nameCtrl.dispose();
    numCtrl.dispose();
    currencyCtrl.dispose();
    balanceCtrl.dispose();
    fxRateCtrl.dispose();
  }
}

class ReviewRateItem {
  String category;
  final TextEditingController rateCtrl;
  final TextEditingController minSpendCtrl;
  final TextEditingController maxSpendCtrl;
  final TextEditingController customCategoryCtrl;

  ReviewRateItem({
    required this.category,
    required String rate,
    required String minSpend,
    required String maxSpend,
  })  : rateCtrl = TextEditingController(text: rate),
        minSpendCtrl = TextEditingController(text: minSpend),
        maxSpendCtrl = TextEditingController(text: maxSpend),
        customCategoryCtrl = TextEditingController(text: category == 'Others' ? '' : category);

  void dispose() {
    rateCtrl.dispose();
    minSpendCtrl.dispose();
    maxSpendCtrl.dispose();
    customCategoryCtrl.dispose();
  }
}

class TransactionReviewScreen extends ConsumerStatefulWidget {
  final String fileType; // 'bank' | 'credit_card'
  final String fileName;
  final String statementId;

  const TransactionReviewScreen({
    super.key,
    required this.fileType,
    required this.fileName,
    required this.statementId,
  });

  @override
  ConsumerState<TransactionReviewScreen> createState() => _TransactionReviewScreenState();
}

class _TransactionReviewScreenState extends ConsumerState<TransactionReviewScreen> {
  final List<ExtractedAccountItem> _accounts = [];
  List<ReviewTransactionItem> _transactions = [];
  bool _isLoading = true;
  bool _isViewOnly = false;

  // Section 1 Controllers
  final TextEditingController _cardIssuerCtrl = TextEditingController();
  String _cardType = 'Mastercard'; // Visa, Mastercard, Amex, JCB
  final TextEditingController _cardNameCtrl = TextEditingController();
  final TextEditingController _cardNumberCtrl = TextEditingController();

  // Section 2 Miles Controllers
  bool _hasMiles = false;
  final TextEditingController _milesOpeningCtrl = TextEditingController();
  final TextEditingController _milesEarnedCtrl = TextEditingController();
  final TextEditingController _milesBonusCtrl = TextEditingController();
  final TextEditingController _milesRedeemedCtrl = TextEditingController();
  final TextEditingController _milesEndingCtrl = TextEditingController();
  final List<ReviewRateItem> _milesRates = [];
  final TextEditingController _milesMinSpendCtrl = TextEditingController();
  final TextEditingController _milesMaxSpendCtrl = TextEditingController();

  // Section 4 Cashback Controllers
  bool _hasCashback = false;
  final TextEditingController _cashbackEarnedCtrl = TextEditingController();
  final List<ReviewRateItem> _cashbackRates = [];
  final TextEditingController _cashbackMinSpendCtrl = TextEditingController();
  final TextEditingController _cashbackMaxSpendCtrl = TextEditingController();

  // Section 6 Controllers
  final TextEditingController _totalSpendCtrl = TextEditingController();
  DateTime _paymentDueDate = DateTime.now();
  late DateTime _statementMonth;

  static const List<String> _categoryOptions = [
    'All spend',
    'Base Rate (All Spend)',
    'SGD Spend',
    'FCY Spend',
    'MYR Spend',
    'IDR Spend',
    'Automobile',
    'Beauty & Wellness',
    'Commute',
    'Dining & Food Delivery',
    'Entertainment',
    'Groceries',
    'Kids & Pets',
    'Online Shopping',
    'Sports & Sports Apparels',
    'Telco & Streaming',
    'SimplyGo',
    'Shopping',
    'Fuel',
    'Others',
  ];

  static const List<String> _ccTransactionCategoryOptions = [
    'Automobile',
    'Beauty & Wellness',
    'Commute',
    'Dining & Food Delivery',
    'Entertainment',
    'Groceries',
    'Kids & Pets',
    'Online Shopping',
    'Sports & Sports Apparels',
    'Telco & Streaming',
    'SimplyGo',
    'Shopping',
    'Fuel',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadDraftOrFallback();
  }

  @override
  void dispose() {
    for (var a in _accounts) {
      a.dispose();
    }
    _cardIssuerCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _milesOpeningCtrl.dispose();
    _milesEarnedCtrl.dispose();
    _milesBonusCtrl.dispose();
    _milesRedeemedCtrl.dispose();
    _milesEndingCtrl.dispose();
    _milesMinSpendCtrl.dispose();
    _milesMaxSpendCtrl.dispose();
    for (var r in _milesRates) {
      r.dispose();
    }
    _cashbackEarnedCtrl.dispose();
    _cashbackMinSpendCtrl.dispose();
    _cashbackMaxSpendCtrl.dispose();
    for (var r in _cashbackRates) {
      r.dispose();
    }
    _totalSpendCtrl.dispose();
    super.dispose();
  }

  DateTime _guessStatementMonth(String fileName) {
    final lower = fileName.toLowerCase();
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    final yearMatch = RegExp(r'20[2-9][0-9]').firstMatch(lower);
    if (yearMatch != null) {
      year = int.parse(yearMatch.group(0)!);
    }

    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    for (int i = 0; i < 12; i++) {
      final monthStr = months[i];
      // Use word boundaries or date separators (e.g. _jun2026, 2026-06, jun_, .jun.)
      // so bank names like 'maribank' don't trigger 'mar' (March)!
      final pattern = RegExp(r'(^|[^a-z])' + monthStr + r'([^a-z]|$)');
      if (pattern.hasMatch(lower)) {
        month = i + 1;
        break;
      }
    }
    return DateTime(year, month);
  }

  Future<void> _loadDraftOrFallback() async {
    setState(() {
      _isLoading = true;
    });

    _statementMonth = _guessStatementMonth(widget.fileName);
    final db = ref.read(appDatabaseProvider);
    if (widget.statementId.isNotEmpty) {
      final stmt = await (db.select(db.statements)..where((t) => t.id.equals(widget.statementId))).getSingleOrNull();
      if (stmt != null && stmt.periodEnd != null) {
        _statementMonth = DateTime.fromMillisecondsSinceEpoch(stmt.periodEnd! * 1000);
      }
    }

    if (widget.statementId.isNotEmpty) {
      final draft = await DraftStatementService.loadDraft(widget.statementId);
      if (draft != null) {
        setState(() {
          _accounts.clear();
          for (var a in draft.accounts) {
            final currencyStr = a.currency.trim().toUpperCase();
            _accounts.add(
              ExtractedAccountItem(
                bank: a.bank,
                name: a.name,
                num: a.num,
                currency: a.currency,
                balance: a.balance,
                balanceAsOf: a.balanceAsOf,
                fxRate: null, // Will fetch inside constructor or defaults
              ),
            );
          }
          
          // Async load stored overrides
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final storage = ref.read(secureStorageProvider);
            for (final acc in _accounts) {
              final currencyStr = acc.currencyCtrl.text.trim().toUpperCase();
              if (currencyStr != 'SGD') {
                final saved = await storage.getFxRate(currencyStr);
                if (saved != null && saved.isNotEmpty) {
                  setState(() {
                    acc.fxRateCtrl.text = saved;
                  });
                }
              }
            }
          });
          if (draft.cardDraft != null) {
            final cd = draft.cardDraft!;
            _cardIssuerCtrl.text = cd.issuer;
            _cardType = cd.cardType;
            _cardNameCtrl.text = cd.cardName;
            _cardNumberCtrl.text = cd.cardNumber;

            final cardNameLower = cd.cardName.toLowerCase();
            final isMaybankFamily = cardNameLower.contains('maybank') && cardNameLower.contains('family');
            final isYuuCard = cardNameLower.contains('yuu');
            final isMilesCard = !isMaybankFamily && (cd.hasMiles || cardNameLower.contains('90') || cardNameLower.contains('miles') || cardNameLower.contains('points') || cardNameLower.contains('voyage') || cardNameLower.contains('altitude') || cardNameLower.contains('prvi')) && !isYuuCard;
            _hasMiles = isMilesCard;
            _hasCashback = isMaybankFamily || isYuuCard || (cd.hasCashback && !isMilesCard);

            _milesOpeningCtrl.text = cd.milesOpening;
            _milesEarnedCtrl.text = cd.milesEarned;
            _milesBonusCtrl.text = cd.milesBonus;
            _milesRedeemedCtrl.text = cd.milesRedeemed;
            _milesEndingCtrl.text = cd.milesEnding;

            _cashbackEarnedCtrl.text = cd.cashbackEarned;

            _totalSpendCtrl.text = cd.totalSpend;
            _paymentDueDate = cd.paymentDueDate;

            // Earn rates: load saved user overrides from draft or CardRulesRegistry
            _milesRates.clear();
            _cashbackRates.clear();

            final rawCashbackRates = cd.cashbackRates;
            final rawMilesRates = cd.milesRates;

            if (rawCashbackRates.isNotEmpty) {
              for (final r in rawCashbackRates) {
                _cashbackRates.add(ReviewRateItem(
                  category: r.category,
                  rate: r.rate,
                  minSpend: r.minSpend ?? '',
                  maxSpend: r.maxSpend ?? '',
                ));
              }
            } else if (isMaybankFamily) {
              _cashbackRates.addAll([
                ReviewRateItem(category: 'Base Rate (All Spend)', rate: '0.22', minSpend: '', maxSpend: ''),
                ReviewRateItem(category: 'MYR Spend', rate: '6.0', minSpend: '800', maxSpend: '333.33'),
                ReviewRateItem(category: 'IDR Spend', rate: '6.0', minSpend: '800', maxSpend: '333.33'),
              ]);
              _cashbackMinSpendCtrl.text = '';
              _cashbackMaxSpendCtrl.text = '333.33';
            } else {
              final rule = CardRulesRegistry.getRule(_cardIssuerCtrl.text, _cardNameCtrl.text);
              for (final r in rule.defaultRatesList) {
                if (_hasMiles) {
                  _milesRates.add(ReviewRateItem(
                    category: r['category']?.toString() ?? 'SGD Spend',
                    rate: r['rate']?.toString() ?? '1.3',
                    minSpend: r['minSpend']?.toString() ?? '',
                    maxSpend: r['maxSpend']?.toString() ?? '',
                  ));
                } else {
                  _cashbackRates.add(ReviewRateItem(
                    category: r['category']?.toString() ?? 'SGD Spend',
                    rate: r['rate']?.toString() ?? '1.0',
                    minSpend: r['minSpend']?.toString() ?? '',
                    maxSpend: r['maxSpend']?.toString() ?? '',
                  ));
                }
              }
            }
          }
        });

        final rulesService = ref.read(userCategoryRulesServiceProvider);
        final tempTxs = <ReviewTransactionItem>[];
        for (final t in draft.transactions) {
          String spendCurr = t.spendCurrency;
          if (t.amount > 0) {
            spendCurr = 'SGD Receipt';
          }
          final classified = await MerchantCategoryClassifier.classify(
            merchant: t.merchant,
            amount: t.amount,
            currentExpenseCategory: t.categoryValue,
            currentMilesCategory: t.milesCashbackCategoryValue,
            rulesService: rulesService,
          );
          tempTxs.add(ReviewTransactionItem(
            dateStr: t.dateStr,
            merchant: t.merchant,
            amount: t.amount,
            categoryStr: classified.milesCategory,
            expenseCategoryStr: classified.expenseCategory,
            spendCurrency: spendCurr,
          ));
        }

        setState(() {
          _transactions = tempTxs;
          if (_transactions.isNotEmpty) {
            _isLoading = false;
          }
        });

        if (_transactions.isNotEmpty) return;
      } else {
        // Draft is deleted (Processed statement). Load from DB!
        _isViewOnly = true;
        final db = ref.read(appDatabaseProvider);
        final storage = ref.read(secureStorageProvider);
        final prefs = await SharedPreferences.getInstance();
        final testerEmail = prefs.getString('tester_email') ?? '';
        var userId = await storage.getUserId();
        if (userId == null || userId.isEmpty || userId == 'unknown_user') {
          userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}' : 'chenyee_user';
        }

        final allTxs = await db.getTransactionsByUser(userId);
        final statementTxs = allTxs.where((t) => t.statementId == widget.statementId).toList();

        if (widget.fileType == 'credit_card') {
          final cards = await db.getCreditCardsByUser(userId);
          CreditCard? matchingCard;
          if (statementTxs.isNotEmpty) {
            final cardId = statementTxs.first.accountId;
            matchingCard = cards.cast<CreditCard?>().firstWhere((c) => c?.id == cardId, orElse: () => null);
          }
          matchingCard ??= cards.cast<CreditCard?>().firstWhere(
            (c) => c?.sourceStatementId == widget.statementId,
            orElse: () => null,
          );
          // Fallback: try to match card by name from the file name
          if (matchingCard == null) {
            final fileNameLower = widget.fileName.toLowerCase();
            matchingCard = cards.cast<CreditCard?>().firstWhere(
              (c) {
                if (c == null) return false;
                final cName = c.cardName.toLowerCase();
                // Match by key words in the file name against the card name
                if (fileNameLower.contains('maybank') && cName.contains('maybank')) return true;
                if (fileNameLower.contains('citi') && cName.contains('citi')) return true;
                if (fileNameLower.contains('dbs') && cName.contains('dbs')) return true;
                if (fileNameLower.contains('uob') && cName.contains('uob')) return true;
                if (fileNameLower.contains('ocbc') && cName.contains('ocbc')) return true;
                if (fileNameLower.contains('hsbc') && cName.contains('hsbc')) return true;
                if (fileNameLower.contains('sc ') && cName.contains('standard chartered')) return true;
                return false;
              },
              orElse: () => null,
            );
          }

          if (matchingCard != null) {
            final savedRewards = await CardRewardsDataStore.loadRewards(matchingCard.id, statementId: widget.statementId);

            setState(() {
              _cardIssuerCtrl.text = matchingCard!.bankName;
              // Capitalize first letter to match dropdown:
              final rawType = matchingCard.cardType;
              _cardType = rawType.isEmpty ? 'Mastercard' : '${rawType[0].toUpperCase()}${rawType.substring(1)}';
              _cardNameCtrl.text = matchingCard.cardName;
              _cardNumberCtrl.text = matchingCard.lastFour != null ? 'xxxx-xxxx-xxxx-${matchingCard.lastFour}' : '';

              final cardNameLower = matchingCard.cardName.toLowerCase();
              final isMaybankFamily = cardNameLower.contains('maybank') && cardNameLower.contains('family');
              final isYuuCard = cardNameLower.contains('yuu');
              final isMilesCard = !isMaybankFamily && (matchingCard.rewardType == 'miles' || matchingCard.rewardType == 'points' || cardNameLower.contains('90') || cardNameLower.contains('miles')) && !isYuuCard;
              _hasMiles = isMilesCard;
              _hasCashback = isMaybankFamily || isYuuCard || (matchingCard.rewardType == 'cashback' && !isMilesCard);

              if (savedRewards != null) {
                if (savedRewards['hasMiles'] != null) {
                  _hasMiles = !isMaybankFamily && (savedRewards['hasMiles'] as bool) && !isYuuCard;
                }
                if (savedRewards['hasCashback'] != null) {
                  _hasCashback = isMaybankFamily || isYuuCard || (savedRewards['hasCashback'] as bool);
                }
                _cashbackEarnedCtrl.text = savedRewards['cashbackEarnedStatement']?.toString() ?? '0.00';
                _totalSpendCtrl.text = savedRewards['totalSpend']?.toString() ?? '0.00';
                if (savedRewards['paymentDueDate'] != null) {
                  try {
                    _paymentDueDate = DateTime.parse(savedRewards['paymentDueDate'] as String);
                  } catch (_) {}
                }
                _milesOpeningCtrl.text = savedRewards['milesOpening']?.toString() ?? '';
                _milesBonusCtrl.text = savedRewards['milesBonus']?.toString() ?? '';
                _milesRedeemedCtrl.text = savedRewards['milesRedeemed']?.toString() ?? '';
                _milesEndingCtrl.text = savedRewards['milesEnding']?.toString() ?? '';
                _milesEarnedCtrl.text = savedRewards['milesEarnedStatement']?.toString() ?? '0';
              }

              // Earn rates: load saved user overrides from DB storage first
              _milesRates.clear();
              _cashbackRates.clear();

              final savedCashbackRates = savedRewards?['cashbackRates'] as List<dynamic>?;
              final savedMilesRates = savedRewards?['milesRates'] as List<dynamic>?;

              if (savedCashbackRates != null && savedCashbackRates.isNotEmpty) {
                for (final r in savedCashbackRates) {
                  _cashbackRates.add(ReviewRateItem(
                    category: r['category']?.toString() ?? 'SGD Spend',
                    rate: r['rate']?.toString() ?? '1.0',
                    minSpend: r['minSpend']?.toString() ?? '',
                    maxSpend: r['maxSpend']?.toString() ?? '',
                  ));
                }
              } else if (savedMilesRates != null && savedMilesRates.isNotEmpty) {
                for (final r in savedMilesRates) {
                  _milesRates.add(ReviewRateItem(
                    category: r['category']?.toString() ?? 'SGD Spend',
                    rate: r['rate']?.toString() ?? '1.3',
                    minSpend: r['minSpend']?.toString() ?? '',
                    maxSpend: r['maxSpend']?.toString() ?? '',
                  ));
                }
              } else if (isMaybankFamily) {
                _cashbackRates.addAll([
                  ReviewRateItem(category: 'Base Rate (All Spend)', rate: '0.22', minSpend: '', maxSpend: ''),
                  ReviewRateItem(category: 'MYR Spend', rate: '6.0', minSpend: '800', maxSpend: '333.33'),
                  ReviewRateItem(category: 'IDR Spend', rate: '6.0', minSpend: '800', maxSpend: '333.33'),
                ]);
                _cashbackMinSpendCtrl.text = '';
                _cashbackMaxSpendCtrl.text = '333.33';
              } else {
                final rule = CardRulesRegistry.getRule(_cardIssuerCtrl.text, _cardNameCtrl.text);
                for (final r in rule.defaultRatesList) {
                  if (_hasMiles) {
                    _milesRates.add(ReviewRateItem(
                      category: r['category']?.toString() ?? 'SGD Spend',
                      rate: r['rate']?.toString() ?? '1.3',
                      minSpend: r['minSpend']?.toString() ?? '',
                      maxSpend: r['maxSpend']?.toString() ?? '',
                    ));
                  } else {
                    _cashbackRates.add(ReviewRateItem(
                      category: r['category']?.toString() ?? 'SGD Spend',
                      rate: r['rate']?.toString() ?? '1.0',
                      minSpend: r['minSpend']?.toString() ?? '',
                      maxSpend: r['maxSpend']?.toString() ?? '',
                    ));
                  }
                }
              }

              final savedTxCategories = (savedRewards?['txRewardCategories'] as Map<String, dynamic>?) ?? {};

              _transactions = statementTxs.map((t) {
                final formattedDate = DateFormat('dd MMM yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(t.date * 1000),
                );
                String spendCurr = t.currency ?? 'SGD Spend';
                if (t.amount > 0) {
                  spendCurr = 'SGD Receipt';
                }
                final savedCat = savedTxCategories[t.id]?.toString() ?? savedTxCategories['${t.merchant}_${t.amount}']?.toString() ?? 'Others';
                return ReviewTransactionItem(
                  dateStr: formattedDate,
                  merchant: t.merchant,
                  amount: t.amount,
                  categoryStr: savedCat,
                  expenseCategoryStr: t.category,
                  spendCurrency: spendCurr,
                );
              }).toList();

              _isLoading = false;
            });
            return;
          } else if (statementTxs.isNotEmpty) {
            // No card matched but we DO have transactions — still show them
            debugPrint('DB: No matching card found, but ${statementTxs.length} transactions exist. Showing them.');
            setState(() {
              _transactions = statementTxs.map((t) {
                final formattedDate = DateFormat('dd MMM yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(t.date * 1000),
                );
                String spendCurr = t.currency ?? 'SGD Spend';
                if (t.amount > 0) {
                  spendCurr = 'SGD Receipt';
                }
                return ReviewTransactionItem(
                  dateStr: formattedDate,
                  merchant: t.merchant,
                  amount: t.amount,
                  categoryStr: 'Others',
                  expenseCategoryStr: t.category,
                  spendCurrency: spendCurr,
                );
              }).toList();
              _isLoading = false;
            });
            return;
          }
        } else {
          // Bank statement loading from DB
          final accounts = await db.getBankAccountsByUser(userId);
          final accountIds = statementTxs.map((t) => t.accountId).toSet();
          final statementAccounts = accounts.where((a) => 
            accountIds.contains(a.id) || a.sourceStatementId == widget.statementId
          ).toList();

          if (statementAccounts.isNotEmpty || statementTxs.isNotEmpty) {
            final statement = await (db.select(db.statements)..where((t) => t.id.equals(widget.statementId))).getSingleOrNull();
            final statementDate = statement?.periodEnd != null
                ? DateTime.fromMillisecondsSinceEpoch(statement!.periodEnd! * 1000)
                : DateTime.now();

            setState(() {
              _accounts.clear();
              for (var a in statementAccounts) {
                _accounts.add(ExtractedAccountItem(
                  bank: a.bankName,
                  name: a.accountType,
                  num: a.accountNumber ?? '',
                  currency: a.currency,
                  balance: a.currentBalance.toString(),
                  balanceAsOf: statementDate,
                ));
              }
              
              // Load custom FX overrides if non-SGD
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final storage = ref.read(secureStorageProvider);
                for (final acc in _accounts) {
                  final currencyStr = acc.currencyCtrl.text.trim().toUpperCase();
                  if (currencyStr != 'SGD') {
                    final saved = await storage.getFxRate(currencyStr);
                    if (saved != null && saved.isNotEmpty) {
                      setState(() {
                        acc.fxRateCtrl.text = saved;
                      });
                    }
                  }
                }
              });
              _transactions = statementTxs.map((t) {
                final formattedDate = DateFormat('dd MMM yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(t.date * 1000),
                );
                return ReviewTransactionItem(
                  dateStr: formattedDate,
                  merchant: t.merchant,
                  amount: t.amount,
                  categoryStr: t.category,
                  spendCurrency: 'SGD Spend',
                );
              }).toList();
              _isLoading = false;
            });
            return;
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }



  void _addNewAccount() {
    setState(() {
      _accounts.add(
        ExtractedAccountItem(
          bank: '',
          name: '',
          num: '',
          currency: 'SGD',
          balance: '0.00',
          balanceAsOf: DateTime.now(),
        ),
      );
    });
    try {
      ref.read(analyticsServiceProvider).logEvent('manual_add_account');
    } catch (_) {}
  }

  void _removeAccount(int index) {
    setState(() {
      _accounts.removeAt(index);
    });
  }

  void _addRate(bool isMiles) {
    setState(() {
      final list = isMiles ? _milesRates : _cashbackRates;
      final existingCats = list.map((e) => e.category).toSet();
      String nextCat = 'Telco & Streaming';
      for (final cat in _categoryOptions) {
        if (cat != 'All spend' && cat != 'SGD Spend' && cat != 'FCY Spend' && !existingCats.contains(cat)) {
          nextCat = cat;
          break;
        }
      }
      list.add(ReviewRateItem(category: nextCat, rate: '6.0', minSpend: '', maxSpend: ''));
    });
  }

  void _removeRate(int index, bool isMiles) {
    setState(() {
      final list = isMiles ? _milesRates : _cashbackRates;
      list[index].dispose();
      list.removeAt(index);
    });
  }

  void _addNewTransaction() {
    setState(() {
      _transactions.add(
        ReviewTransactionItem(
          dateStr: DateFormat('dd MMM yyyy').format(DateTime.now()),
          merchant: 'New Merchant',
          amount: 0.0,
          categoryStr: widget.fileType == 'credit_card' ? 'Shopping' : TransactionCategory.expenseOther.value,
          spendCurrency: 'SGD Spend',
        ),
      );
    });
    try {
      ref.read(analyticsServiceProvider).logEvent('manual_add_transaction');
    } catch (_) {}
  }

  Future<void> _selectDate(BuildContext context, ExtractedAccountItem acc) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: acc.balanceAsOf,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        acc.balanceAsOf = picked;
      });
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _paymentDueDate = picked;
      });
    }
  }

  Future<void> _selectStatementMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _statementMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'SELECT STATEMENT MONTH',
    );
    if (picked != null) {
      setState(() {
        _statementMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  Future<void> _confirmAndSave() async {
    final db = ref.read(appDatabaseProvider);
    final storage = ref.read(secureStorageProvider);

    var userId = await storage.getUserId();
    if (userId == null || userId.isEmpty || userId == 'unknown_user') {
      final prefs = await SharedPreferences.getInstance();
      final testerEmail = prefs.getString('tester_email') ?? '';
      if (testerEmail.contains('@')) {
        userId = 'tester_${testerEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        await storage.saveGoogleUser(userId: userId, googleId: 'web_user_${testerEmail.hashCode}', email: testerEmail);
      } else {
        userId = 'chenyee_user';
        await storage.saveGoogleUser(userId: userId, googleId: 'web_user', email: '');
      }
    }

    final nonNullUserId = userId;
    final statementId = widget.statementId.isNotEmpty ? widget.statementId : const Uuid().v4();

    try {
      // ── Step 1: Ensure user row exists ──
      debugPrint('DB: Getting user row for id $nonNullUserId');
      final user = await db.getUserById(nonNullUserId);
      if (user == null) {
        debugPrint('DB Transaction: Creating user row...');
        final prefs2 = await SharedPreferences.getInstance();
        final fName = prefs2.getString('tester_first_name') ?? '';
        final lName = prefs2.getString('tester_last_name') ?? '';
        final email = await storage.getGoogleEmail() ?? prefs2.getString('tester_email') ?? '';
        await db.upsertUser(
          UsersCompanion.insert(
            id: nonNullUserId,
            firstName: fName,
            lastName: lName,
            email: email,
            googleId: await storage.getGoogleId() ?? 'web_user',
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );
      }

      // ── Step 2: Delete old transactions FIRST ──
      if (widget.statementId.isNotEmpty) {
        debugPrint('DB: Deleting old transactions for statement $statementId...');
        await db.deleteTransactionsByStatement(widget.statementId);
      }

      // ── Step 3: Upsert accounts / credit cards ──
      final bankOrCardName = widget.fileType == 'credit_card' ? _cardIssuerCtrl.text : (_accounts.isNotEmpty ? _accounts[0].bankCtrl.text : 'Unknown');
      final statementMonthTimestamp = _statementMonth.millisecondsSinceEpoch ~/ 1000;

      String? mainAccountId;
      if (widget.fileType == 'credit_card') {
        String accountId;
        final existingCards = await db.getCreditCardsByUser(nonNullUserId);
        
        String _norm(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        final lastFourDigits = _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 4
            ? _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '').substring(_cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '').length - 4)
            : '****';
            
        final cardMatch = existingCards.cast<CreditCard?>().firstWhere(
          (c) {
            if (c == null) return false;
            final matchBank = _norm(c.bankName) == _norm(_cardIssuerCtrl.text);
            final matchLastFour = lastFourDigits != '****' && c.lastFour == lastFourDigits;
            final matchName = _norm(c.cardName) == _norm(_cardNameCtrl.text);
            return matchBank && (matchLastFour || matchName);
          },
          orElse: () => null,
        );

        if (cardMatch != null) {
          accountId = cardMatch.id;
          await (db.update(db.creditCards)..where((t) => t.id.equals(accountId))).write(
            CreditCardsCompanion(
              bankName: drift.Value(_cardIssuerCtrl.text),
              cardName: drift.Value(_cardNameCtrl.text),
              lastFour: drift.Value(lastFourDigits),
              rewardType: drift.Value(_hasMiles ? 'miles' : 'cashback'),
              sourceStatementId: drift.Value(statementId),
            ),
          );
        } else {
          accountId = const Uuid().v4();
          debugPrint('DB Transaction: Inserting new credit card...');
          await db.insertCreditCard(
            CreditCardsCompanion.insert(
              id: accountId,
              userId: nonNullUserId,
              bankName: _cardIssuerCtrl.text,
              cardName: _cardNameCtrl.text,
              cardType: _cardType,
              lastFour: drift.Value(_cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 4
                  ? _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '').substring(_cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '').length - 4)
                  : '****'),
              rewardType: _hasMiles ? 'miles' : 'cashback',
              sourceStatementId: drift.Value(statementId),
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
        }
        mainAccountId = accountId;

        final cashbackRatesList = _cashbackRates.map((r) => {
          'category': r.category == 'Others' && r.customCategoryCtrl.text.trim().isNotEmpty
              ? r.customCategoryCtrl.text.trim()
              : r.category,
          'rate': r.rateCtrl.text,
          'minSpend': _cashbackMinSpendCtrl.text,
          'maxSpend': _cashbackMaxSpendCtrl.text,
        }).toList();

        final milesRatesList = _milesRates.map((r) => {
          'category': r.category == 'Others' && r.customCategoryCtrl.text.trim().isNotEmpty
              ? r.customCategoryCtrl.text.trim()
              : r.category,
          'rate': r.rateCtrl.text,
          'minSpend': _milesMinSpendCtrl.text,
          'maxSpend': _milesMaxSpendCtrl.text,
        }).toList();

        final Map<String, String> txRewardCategories = {};
        for (final tx in _transactions) {
          final cat = tx.categoryStr == 'Others' && tx.customCategoryCtrl.text.trim().isNotEmpty
              ? tx.customCategoryCtrl.text.trim()
              : tx.categoryStr;
          txRewardCategories['${tx.merchant}_${tx.amount}'] = cat;
        }

        await CardRewardsDataStore.saveRewards(
          cardId: accountId,
          statementId: statementId,
          cashbackEarnedStatement: double.tryParse(_cashbackEarnedCtrl.text) ?? 0.0,
          cashbackRates: cashbackRatesList,
          milesEarnedStatement: double.tryParse(_milesEarnedCtrl.text) ?? 0.0,
          milesRates: milesRatesList,
          totalSpend: _totalSpendCtrl.text.trim(),
          paymentDueDate: _paymentDueDate.toIso8601String(),
          milesOpening: _milesOpeningCtrl.text.trim(),
          milesBonus: _milesBonusCtrl.text.trim(),
          milesRedeemed: _milesRedeemedCtrl.text.trim(),
          milesEnding: _milesEndingCtrl.text.trim(),
          hasMiles: _hasMiles,
          hasCashback: _hasCashback,
          txRewardCategories: txRewardCategories,
        );

        // Also save updated draft content so reopening draft shows updated rate categories
        final updatedCardDraft = ExtractedCreditCardDraft(
          issuer: _cardIssuerCtrl.text,
          cardType: _cardType,
          cardName: _cardNameCtrl.text,
          cardNumber: _cardNumberCtrl.text,
          hasMiles: _hasMiles,
          milesOpening: _milesOpeningCtrl.text,
          milesEarned: _milesEarnedCtrl.text,
          milesBonus: _milesBonusCtrl.text,
          milesRedeemed: _milesRedeemedCtrl.text,
          milesEnding: _milesEndingCtrl.text,
          milesRates: milesRatesList.map((m) => ExtractedRewardRate(
            category: m['category'] ?? '',
            rate: m['rate'] ?? '',
            minSpend: m['minSpend'] ?? '',
            maxSpend: m['maxSpend'] ?? '',
          )).toList(),
          hasCashback: _hasCashback,
          cashbackEarned: _cashbackEarnedCtrl.text,
          cashbackRates: cashbackRatesList.map((m) => ExtractedRewardRate(
            category: m['category'] ?? '',
            rate: m['rate'] ?? '',
            minSpend: m['minSpend'] ?? '',
            maxSpend: m['maxSpend'] ?? '',
          )).toList(),
          totalSpend: _totalSpendCtrl.text,
          paymentDueDate: _paymentDueDate,
        );

        final existingDraft = await DraftStatementService.loadDraft(statementId);
        if (existingDraft != null) {
          final updatedTxDrafts = _transactions.map((tx) {
            final cat = tx.categoryStr == 'Others' && tx.customCategoryCtrl.text.trim().isNotEmpty
                ? tx.customCategoryCtrl.text.trim()
                : tx.categoryStr;
            return ExtractedTransactionDraft(
              dateStr: tx.dateStr,
              merchant: tx.merchant,
              amount: tx.amount,
              categoryValue: tx.expenseCategoryStr,
              milesCashbackCategoryValue: cat,
              spendCurrency: tx.spendCurrency,
            );
          }).toList();

          final updatedDraftData = DraftStatementData(
            accounts: existingDraft.accounts,
            transactions: updatedTxDrafts,
            cardDraft: updatedCardDraft,
          );
          await DraftStatementService.saveDraft(statementId, updatedDraftData);
        }

        if (_hasMiles) {
          final milesEnding = double.tryParse(_milesEndingCtrl.text) ?? 0.0;
          // Derive program name from card issuer + card name
          final bankName = _cardIssuerCtrl.text.trim();
          final cardName = _cardNameCtrl.text.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
          final programName = cardName.isNotEmpty ? '$bankName $cardName'.replaceAll(RegExp(r'\s+'), ' ').trim() : (bankName.isNotEmpty ? bankName : 'Unknown Card');
          // Use a stable wallet ID based on normalized card identity
          String _norm2(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
          final walletId = 'bank_miles_${_norm2(programName)}';
          // Use statement month as the "last updated" date
          final statementTimestamp = _statementMonth.millisecondsSinceEpoch ~/ 1000;
          await db.upsertMilesWallet(
            MilesWalletCompanion.insert(
              id: walletId,
              userId: nonNullUserId,
              programName: programName,
              programType: 'bank',
              balance: drift.Value(milesEnding),
              lastUpdated: statementTimestamp,
            ),
          );
        }
      } else {
        final existingAccounts = await db.getBankAccountsByUser(nonNullUserId);
        final statementAccounts = existingAccounts.where((a) => a.sourceStatementId == statementId).toList();
        String _normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

        // Detect and delete accounts that were removed by the user in this screen session:
        final activeAccountNumbers = _accounts.map((a) => _normalize(a.numCtrl.text)).toSet();
        final activeBankNames = _accounts.map((a) => _normalize(a.bankCtrl.text)).toSet();
        for (final sa in statementAccounts) {
          final normNum = _normalize(sa.accountNumber ?? '');
          final normBank = _normalize(sa.bankName);
          if (!activeAccountNumbers.contains(normNum) || !activeBankNames.contains(normBank)) {
            debugPrint('DB: Deleting user-removed bank account: ${sa.bankName} (${sa.accountNumber})');
            await (db.delete(db.bankAccounts)..where((t) => t.id.equals(sa.id))).go();
          }
        }

        // Proceed to update or insert remaining active accounts
        for (int i = 0; i < _accounts.length; i++) {
          final acc = _accounts[i];
          final balance = double.tryParse(acc.balanceCtrl.text) ?? 0.0;
          String accountId;

          // Save FX rate to secure storage if non-SGD
          final currencyStr = acc.currencyCtrl.text.trim().toUpperCase();
          if (currencyStr != 'SGD') {
            await storage.saveFxRate(currencyStr, acc.fxRateCtrl.text.trim());
          }

          final matchIndex = existingAccounts.indexWhere(
            (a) {
              final normAccNum = _normalize(a.accountNumber ?? '');
              final targetAccNum = _normalize(acc.numCtrl.text);
              final normBank = _normalize(a.bankName);
              final targetBank = _normalize(acc.bankCtrl.text);
              final normName = _normalize(a.accountType);
              final targetName = _normalize(acc.nameCtrl.text);
              final isSameStatement = a.sourceStatementId == statementId;

              if (isSameStatement && normBank == targetBank) {
                if (targetAccNum.isNotEmpty && normAccNum == targetAccNum) return true;
                if (targetAccNum.isEmpty && normName == targetName) return true;
              }
              return false;
            },
          );

          final balanceAsOfTs = acc.balanceAsOf.millisecondsSinceEpoch ~/ 1000;
          if (matchIndex != -1) {
            final match = existingAccounts[matchIndex];
            accountId = match.id;
            debugPrint('DB: Updating matching account by account number: ${acc.numCtrl.text}');
            await (db.update(db.bankAccounts)..where((t) => t.id.equals(match.id))).write(
              BankAccountsCompanion(
                currentBalance: drift.Value(balance),
                bankName: drift.Value(acc.bankCtrl.text),
                accountType: drift.Value(acc.nameCtrl.text),
                accountNumber: drift.Value(acc.numCtrl.text),
                currency: drift.Value(acc.currencyCtrl.text),
                sourceStatementId: drift.Value(statementId),
                createdAt: drift.Value(balanceAsOfTs),
              ),
            );
          } else {
            accountId = const Uuid().v4();
            debugPrint('DB: Inserting new bank account with balance $balance');
            await db.insertBankAccount(
              BankAccountsCompanion.insert(
                id: accountId,
                userId: nonNullUserId,
                bankName: acc.bankCtrl.text,
                accountType: acc.nameCtrl.text,
                accountNumber: drift.Value(acc.numCtrl.text),
                currentBalance: drift.Value(balance),
                openingBalance: drift.Value(balance),
                currency: drift.Value(acc.currencyCtrl.text),
                sourceStatementId: drift.Value(statementId),
                createdAt: balanceAsOfTs,
              ),
            );
          }
          mainAccountId ??= accountId;
        }
      }

      // ── Step 4: Insert transactions (with retry) ──
      int insertedCount = 0;
      if (_transactions.isNotEmpty) {
        // Save user learned rules so AI remembers these category assignments for all future bank statements!
        final rulesService = ref.read(userCategoryRulesServiceProvider);
        for (final tx in _transactions) {
          final expCat = widget.fileType == 'credit_card' ? tx.expenseCategoryStr : tx.categoryStr;
          final milesCat = tx.categoryStr;
          await rulesService.saveRule(
            rawMerchant: tx.merchant,
            expenseCategory: expCat,
            milesCategory: milesCat,
          );
        }

        debugPrint('DB Transaction: Inserting ${_transactions.length} transactions...');
        final companions = _transactions.map((tx) {
          int txTimestamp;
          try {
            final parsed = DateFormat('dd MMM yyyy').parse(tx.dateStr.trim());
            txTimestamp = parsed.millisecondsSinceEpoch ~/ 1000;
          } catch (e) {
            txTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          }

          return TransactionsCompanion.insert(
            id: const Uuid().v4(),
            userId: nonNullUserId,
            accountId: mainAccountId ?? const Uuid().v4(),
            accountType: widget.fileType == 'bank' ? 'bank' : 'credit_card',
            date: txTimestamp,
            merchant: tx.merchant,
            description: tx.merchant,
            amount: tx.amount,
            category: widget.fileType == 'credit_card'
                ? tx.expenseCategoryStr
                : tx.categoryStr,
            currency: drift.Value(widget.fileType == 'credit_card' ? tx.spendCurrency : 'SGD'),
            statementId: drift.Value(statementId),
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );
        }).toList();

        // Retry transaction insertion up to 3 times on failure
        int retries = 3;
        while (retries > 0) {
          try {
            await db.insertTransactions(companions);
            insertedCount = companions.length;
            debugPrint('DB: Successfully inserted $insertedCount transactions.');
            break;
          } catch (e) {
            retries--;
            debugPrint('DB: Transaction insert failed (retries left: $retries): $e');
            if (retries <= 0) rethrow;
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }

      // ── Step 5: Update statement row AFTER transactions are inserted ──
      debugPrint('DB: Updating statement row with transactionCount=$insertedCount...');
      final statementsList = await db.getStatementsByUser(nonNullUserId);
      Statement? existing;
      for (var s in statementsList) {
        if (s.id == statementId) {
          existing = s;
          break;
        }
      }

      final effectiveMonthTs = _accounts.isNotEmpty
          ? _accounts.first.balanceAsOf.millisecondsSinceEpoch ~/ 1000
          : statementMonthTimestamp;

      if (existing != null) {
        final statementCompanion = StatementsCompanion(
          id: drift.Value(statementId),
          userId: drift.Value(nonNullUserId),
          fileName: drift.Value(widget.fileName),
          filePath: drift.Value(existing.filePath),
          fileType: drift.Value(widget.fileType),
          fileSizeBytes: drift.Value(existing.fileSizeBytes),
          status: const drift.Value('Processed'),
          bankOrCard: drift.Value(bankOrCardName),
          accountType: drift.Value(widget.fileType),
          transactionCount: drift.Value(insertedCount),
          periodEnd: drift.Value(effectiveMonthTs),
          uploadedAt: drift.Value(existing.uploadedAt),
          processedAt: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        );
        await (db.update(db.statements)..where((t) => t.id.equals(statementId))).write(statementCompanion);
      } else {
        await db.insertStatement(
          StatementsCompanion.insert(
            id: statementId,
            userId: nonNullUserId,
            fileName: widget.fileName,
            filePath: '',
            fileType: widget.fileType,
            fileSizeBytes: 1024 * 50,
            status: const drift.Value('Processed'),
            bankOrCard: drift.Value(bankOrCardName),
            accountType: drift.Value(widget.fileType),
            transactionCount: drift.Value(insertedCount),
            periodEnd: drift.Value(effectiveMonthTs),
            uploadedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            processedAt: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          ),
        );
      }

      debugPrint('DB Save Committed Successfully! Transactions: $insertedCount');

      // ── Step 6: Delete draft ONLY after everything succeeded ──
      await DraftStatementService.deleteDraft(statementId);

      // Log successful save to analytics
      try {
        final analytics = ref.read(analyticsServiceProvider);
        analytics.logEvent('statement_saved', parameters: {
          'type': widget.fileType,
          'fileName': widget.fileName,
          'institution': bankOrCardName,
          'transactionCount': insertedCount,
        });
      } catch (_) {}

      context.showTopSnackBar('Saved $insertedCount transactions successfully!');

      ref.invalidate(cashFlowScreenProvider);
      ref.invalidate(cashPositionProvider);
      ref.invalidate(monthlyIncomeProvider);
      ref.invalidate(monthlyExpensesProvider);
      ref.invalidate(uploadScreenProvider);

      context.pop();
    } catch (e) {
      debugPrint('DB Transaction Failed: $e');

      // Log error to analytics
      try {
        final analytics = ref.read(analyticsServiceProvider);
        analytics.logError('statement_save_error', '$e');
      } catch (_) {}

      context.showTopSnackBar('Error saving statement data: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 2, name: 'S\$');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0),
              child: const AppHeaderBrand(),
            ),
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isViewOnly ? 'Statement details' : 'Review extraction',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.fileName,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info alert box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: Text(
                        _isViewOnly
                            ? 'Below are the details that have been confirmed and saved for this statement. These figures are reflected in your Home, Cashflow, and Rewards dashboards.'
                            : 'AI extracted the details below. Verify and edit anything wrong before saving — this data will then appear on your Home / Cashflow / Rewards dashboards.',
                        style: TextStyle(fontSize: 13, color: AppColors.primaryDark, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (widget.fileType == 'credit_card')
                      _buildCreditCardLayout()
                    else ...[
                      // Section: Bank Account(s)
                      Row(
                        children: const [
                          Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'BANK ACCOUNT(S)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Account cards
                      ...List.generate(_accounts.length, (idx) {
                        final acc = _accounts[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildInputField(controller: acc.bankCtrl, label: 'BANK NAME')),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildInputField(controller: acc.nameCtrl, label: 'ACCOUNT NAME')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildInputField(controller: acc.numCtrl, label: 'ACCOUNT NUMBER')),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInputField(
                                      controller: acc.currencyCtrl, 
                                      label: 'CURRENCY',
                                      onChanged: (val) {
                                        setState(() {
                                          acc.fxRateCtrl.text = ExtractedAccountItem._getDefaultFx(val);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildInputField(controller: acc.balanceCtrl, label: 'BALANCE', keyboardType: TextInputType.number)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'BALANCE AS OF',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () => _selectDate(context, acc),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: AppColors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.divider),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(acc.balanceAsOf),
                                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                                ),
                                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (acc.currencyCtrl.text.trim().toUpperCase() != 'SGD') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        controller: acc.fxRateCtrl,
                                        label: 'FX RATE TO SGD',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'SGD EQUIVALENT (EST.)',
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'S\$ ${((double.tryParse(acc.balanceCtrl.text) ?? 0.0) * (double.tryParse(acc.fxRateCtrl.text) ?? 1.0)).toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remove Account'),
                                        content: const Text('Are you sure you want to remove this account?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Remove'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      _removeAccount(idx);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  label: const Text(
                                    'Remove account',
                                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Account button link
                      TextButton.icon(
                        onPressed: _addNewAccount,
                        icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                        label: const Text(
                          'Add account',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Section: Transactions (N)
                    Text(
                      'TRANSACTIONS (${_transactions.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Income and expenses on the bank statement.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    if (_transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Center(
                          child: Text(
                            'No transactions extracted.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isCreditCard = widget.fileType == 'credit_card';

                          return Container(
                            key: ValueKey(tx),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isCreditCard) ...[
                                  // CREDIT CARD TRANSACTION: 4-ROW LAYOUT
                                  // ROW 1: Date | Amount | Delete Button
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: InkWell(
                                          onTap: () async {
                                            DateTime parsedDate = DateTime.now();
                                            try {
                                              parsedDate = DateFormat('dd MMM yyyy').parse(tx.dateStr.trim());
                                            } catch (_) {
                                              try {
                                                parsedDate = DateFormat('dd/MM/yyyy').parse(tx.dateStr.trim());
                                              } catch (_) {}
                                            }
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: parsedDate,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                tx.dateStr = DateFormat('dd MMM yyyy').format(picked);
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: const InputDecoration(
                                              labelText: 'Date',
                                              labelStyle: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              border: OutlineInputBorder(),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    tx.dateStr,
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(Icons.calendar_today, size: 11, color: AppColors.textSecondary),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 5,
                                        child: _buildTransactionField(
                                          value: tx.amount.toString(),
                                          label: 'Amount',
                                          onChanged: (val) {
                                            setState(() {
                                              final parsed = double.tryParse(val.trim());
                                              if (parsed != null) {
                                                tx.amount = parsed;
                                                final isIncome = tx.amount > 0;
                                                final catEnum = TransactionCategory.fromValue(tx.expenseCategoryStr);
                                                if (isIncome && !catEnum.isIncome) {
                                                  tx.expenseCategoryStr = TransactionCategory.incomeOther.value;
                                                } else if (!isIncome && catEnum.isIncome) {
                                                  tx.expenseCategoryStr = TransactionCategory.expenseOther.value;
                                                }
                                              }
                                            });
                                          },
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Transaction'),
                                              content: const Text('Are you sure you want to delete this transaction draft?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            setState(() {
                                              _transactions.removeAt(index);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // ROW 2: Merchant (Full Width)
                                  _buildTransactionField(
                                    value: tx.merchant,
                                    label: 'Merchant',
                                    onChanged: (val) => tx.merchant = val,
                                  ),
                                  const SizedBox(height: 8),
                                  // ROW 3: Category for Expenses | Category for Miles/Cashback
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Category for expenses', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            DropdownButtonFormField<TransactionCategory>(
                                              value: () {
                                                final isIncome = tx.amount > 0;
                                                final cat = TransactionCategory.fromValue(tx.expenseCategoryStr);
                                                final allowed = isIncome
                                                    ? TransactionCategory.incomeCategories
                                                    : TransactionCategory.expenseCategories;
                                                return allowed.contains(cat) ? cat : (isIncome ? TransactionCategory.incomeOther : TransactionCategory.expenseOther);
                                              }(),
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                border: OutlineInputBorder(),
                                              ),
                                              items: (tx.amount > 0 ? TransactionCategory.incomeCategories : TransactionCategory.expenseCategories)
                                                  .map((cat) => DropdownMenuItem(
                                                        value: cat,
                                                        child: Text(cat.displayName, style: const TextStyle(fontSize: 10)),
                                                      ))
                                                  .toList(),
                                              onChanged: (newCat) {
                                                if (newCat != null) {
                                                  setState(() {
                                                    tx.expenseCategoryStr = newCat.value;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Category for miles/cashback', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            DropdownButtonFormField<String>(
                                              value: _ccTransactionCategoryOptions.contains(tx.categoryStr) ? tx.categoryStr : 'Others',
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                border: OutlineInputBorder(),
                                              ),
                                              items: _ccTransactionCategoryOptions
                                                  .map((cat) => DropdownMenuItem(
                                                        value: cat,
                                                        child: Text(cat, style: const TextStyle(fontSize: 10)),
                                                      ))
                                                  .toList(),
                                              onChanged: (newCat) {
                                                if (newCat != null) {
                                                  setState(() {
                                                    tx.categoryStr = newCat;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // ROW 4: Currency | Custom Category Name
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Currency', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            DropdownButtonFormField<String>(
                                              value: tx.spendCurrency,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                border: OutlineInputBorder(),
                                              ),
                                              items: const ['SGD Spend', 'MYR spend', 'IDR spend', 'FCY spend', 'FCY Spend', 'SGD receipt', 'SGD Receipt']
                                                  .map((cur) => DropdownMenuItem(
                                                        value: cur,
                                                        child: Text(cur, style: const TextStyle(fontSize: 10)),
                                                      ))
                                                  .toList(),
                                              onChanged: (newCur) {
                                                if (newCur != null) {
                                                  setState(() {
                                                    tx.spendCurrency = newCur;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (tx.categoryStr == 'Others') ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Custom Category Name', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                              const SizedBox(height: 2),
                                              SizedBox(
                                                height: 36,
                                                child: TextField(
                                                  controller: tx.customCategoryCtrl,
                                                  style: const TextStyle(fontSize: 11),
                                                  decoration: const InputDecoration(
                                                    hintText: 'Custom Category Name',
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ] else ...[
                                  // BANK STATEMENT TRANSACTION: 3-ROW LAYOUT
                                  // ROW 1: Date | Amount | Delete Button
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: InkWell(
                                          onTap: () async {
                                            DateTime parsedDate = DateTime.now();
                                            try {
                                              parsedDate = DateFormat('dd MMM yyyy').parse(tx.dateStr.trim());
                                            } catch (_) {
                                              try {
                                                parsedDate = DateFormat('dd/MM/yyyy').parse(tx.dateStr.trim());
                                              } catch (_) {}
                                            }
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: parsedDate,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                tx.dateStr = DateFormat('dd MMM yyyy').format(picked);
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: const InputDecoration(
                                              labelText: 'Date',
                                              labelStyle: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              border: OutlineInputBorder(),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    tx.dateStr,
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 5,
                                        child: _buildTransactionField(
                                          value: tx.amount.toString(),
                                          label: 'Amount',
                                          onChanged: (val) {
                                            setState(() {
                                              final parsed = double.tryParse(val.trim());
                                              if (parsed != null) {
                                                tx.amount = parsed;
                                                final isIncome = tx.amount > 0;
                                                final catEnum = TransactionCategory.fromValue(tx.categoryStr);
                                                if (isIncome && !catEnum.isIncome) {
                                                  tx.categoryStr = TransactionCategory.incomeOther.value;
                                                } else if (!isIncome && catEnum.isIncome) {
                                                  tx.categoryStr = TransactionCategory.expenseOther.value;
                                                }
                                              }
                                            });
                                          },
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Transaction'),
                                              content: const Text('Are you sure you want to delete this transaction draft?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            setState(() {
                                              _transactions.removeAt(index);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // ROW 2: Merchant (Full Width)
                                  _buildTransactionField(
                                    value: tx.merchant,
                                    label: 'Merchant',
                                    onChanged: (val) => tx.merchant = val,
                                  ),
                                  const SizedBox(height: 8),
                                  // ROW 3: Category (Full Width)
                                  Builder(
                                    builder: (context) {
                                      final isIncomeTx = tx.amount > 0;
                                      final catEnum = TransactionCategory.fromValue(tx.categoryStr);
                                      final allowedCategories = isIncomeTx
                                          ? TransactionCategory.incomeCategories
                                          : TransactionCategory.expenseCategories;

                                      // Auto-correct category value if sign doesn't match
                                      TransactionCategory finalCat = catEnum;
                                      if (!allowedCategories.contains(finalCat)) {
                                        finalCat = isIncomeTx ? TransactionCategory.incomeOther : TransactionCategory.expenseOther;
                                        tx.categoryStr = finalCat.value;
                                      }

                                      return DropdownButtonFormField<TransactionCategory>(
                                        value: finalCat,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Category',
                                          labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          border: OutlineInputBorder(),
                                        ),
                                        items: allowedCategories
                                            .map((cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(
                                                    cat.displayName,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: cat.isIncome ? AppColors.primary : Colors.red,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (newCat) {
                                          if (newCat != null) {
                                            setState(() {
                                              tx.categoryStr = newCat.value;
                                            });
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),

                    // Add transaction button link
                    TextButton.icon(
                      onPressed: _addNewTransaction,
                      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Add transaction',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Footer actions row
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.divider),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _isViewOnly ? 'Save changes' : 'Confirm & save',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardRateItem(ReviewRateItem rate, int index, bool isMiles) {
    final hasOthersCategory = rate.category == 'Others';
    final isFirstRow = index == 0;
    return Padding(
      padding: EdgeInsets.only(bottom: isFirstRow ? 6.0 : 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstRow) ...[
                      const Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                    ],
                    Builder(
                      builder: (context) {
                        String resolvedCategory = 'Others';
                        final optionsList = List<String>.from(_categoryOptions);
                        if (!optionsList.contains(rate.category)) {
                          optionsList.add(rate.category);
                        }
                        resolvedCategory = rate.category;

                        return DropdownButtonFormField<String>(
                          value: resolvedCategory,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            border: OutlineInputBorder(),
                          ),
                          items: optionsList
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (newCat) {
                            if (newCat != null) {
                              setState(() {
                                rate.category = newCat;
                                rate.customCategoryCtrl.text = newCat;
                              });
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstRow) ...[
                      Text(
                        isMiles ? 'RATE (MILES / S\$1)' : 'RATE (% CASHBACK)',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                    ],
                    TextFormField(
                      controller: rate.rateCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        fillColor: AppColors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(top: isFirstRow ? 20.0 : 2.0),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Reward Rate'),
                        content: const Text('Are you sure you want to delete this reward rate item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _removeRate(index, isMiles);
                    }
                  },
                ),
              ),
            ],
          ),
          if (hasOthersCategory) ...[
            const SizedBox(height: 10),
            _buildInputField(
              controller: rate.customCategoryCtrl,
              label: 'CUSTOM CATEGORY NAME',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            fillColor: AppColors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionField({
    required String value,
    required String label,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  Widget _buildCreditCardLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Credit Card Details
        _buildSectionTitle(Icons.credit_card, 'CREDIT CARD DETAILS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildInputField(controller: _cardIssuerCtrl, label: 'ISSUER / BANK')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARD TYPE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _cardType,
                          decoration: InputDecoration(
                            fillColor: AppColors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                          ),
                          items: const ['Visa', 'Mastercard', 'Amex', 'JCB']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _cardType = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField(controller: _cardNameCtrl, label: 'CARD NAME')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField(controller: _cardNumberCtrl, label: 'CARD NUMBER')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section 2 Toggles
        SwitchListTile(
          title: const Text('Statement shows Miles or Reward Points Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          value: _hasMiles,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              _hasMiles = val;
            });
          },
        ),
        if (_hasMiles) ...[
          _buildSectionTitle(Icons.star_outline, 'MILES SUMMARY'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInputField(controller: _milesOpeningCtrl, label: 'OPENING BALANCE', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputField(controller: _milesEarnedCtrl, label: 'EARNED THIS MONTH', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInputField(controller: _milesBonusCtrl, label: 'BONUS THIS MONTH', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputField(controller: _milesRedeemedCtrl, label: 'REDEEMED / ADJUSTED', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInputField(controller: _milesEndingCtrl, label: 'ENDING BALANCE', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(Icons.percent, 'MILES EARN RATES'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_milesRates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No miles earned rates yet. Add one if this is a miles/points earning card.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...List.generate(_milesRates.length, (idx) {
                    final item = _milesRates[idx];
                    return _buildRewardRateItem(item, idx, true);
                  }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _addRate(true),
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Add miles rate',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _milesMinSpendCtrl,
                        label: 'MIN SPEND (S\$)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _milesMaxSpendCtrl,
                        label: 'MAX SPEND CAP (S\$)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        SwitchListTile(
          title: const Text('Statement shows Cashback summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          value: _hasCashback,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              _hasCashback = val;
            });
          },
        ),
        if (_hasCashback) ...[
          _buildSectionTitle(Icons.monetization_on_outlined, 'CASHBACK DETAILS'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: _buildInputField(controller: _cashbackEarnedCtrl, label: 'CASHBACK EARNED THIS MONTH (S\$)', keyboardType: TextInputType.number),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(Icons.percent, 'CASHBACK EARN RATES'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_cashbackRates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No cashback rates yet. Add one if this is a cashback card.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...List.generate(_cashbackRates.length, (idx) {
                    final item = _cashbackRates[idx];
                    return _buildRewardRateItem(item, idx, false);
                  }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _addRate(false),
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Add cashback rate',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _cashbackMinSpendCtrl,
                        label: 'MIN SPEND (S\$)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _cashbackMaxSpendCtrl,
                        label: 'MAX SPEND CAP (S\$)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Section 6: Statement Totals
        _buildSectionTitle(Icons.summarize_outlined, 'STATEMENT TOTALS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildInputField(controller: _totalSpendCtrl, label: 'TOTAL SPEND THIS MONTH (S\$)', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAYMENT DUE DATE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectDueDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_paymentDueDate),
                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATEMENT MONTH',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectStatementMonth(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMMM yyyy').format(_statementMonth),
                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class ReviewTransactionItem {
  String dateStr;
  String merchant;
  double amount;
  String categoryStr;
  String expenseCategoryStr;
  String spendCurrency;
  final TextEditingController customCategoryCtrl;

  ReviewTransactionItem({
    required this.dateStr,
    required this.merchant,
    required this.amount,
    required this.categoryStr,
    this.expenseCategoryStr = 'expense_other',
    this.spendCurrency = 'SGD Spend',
  }) : customCategoryCtrl = TextEditingController(text: categoryStr == 'Others' ? '' : categoryStr);
}
