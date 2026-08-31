import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/cashflow/upload/draft_statement_service.dart';

import 'card_rules_registry.dart';
import 'merchant_category_classifier.dart';
import 'user_category_rules_service.dart';
import 'analytics_service.dart';

class GeminiExtractionService {
  final String _apiKey;

  GeminiExtractionService(this._apiKey);

  Future<DraftStatementData> extractData({
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final dio = Dio();
    final String base64Data = base64Encode(fileBytes);

    // Primary AI Models List in speed/accuracy priority
    final modelNames = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    ];

    final rulesService = UserCategoryRulesService();
    final topLearnedRules = await rulesService.getTopRules(limit: 25);
    String userRulesSection = '';
    if (topLearnedRules.isNotEmpty) {
      userRulesSection = '\nUSER-LEARNED MERCHANT CATEGORY PREFERENCES (Apply these first with high priority):\n' +
          topLearnedRules.map((r) => '- "${r.pattern}" -> categoryValue: "${r.expenseCategory}", milesCategory: "${r.milesCategory}"').join('\n') +
          '\n';
    }

    final String promptText = '''
You are an expert financial AI specializing in Singapore bank and credit card statements (DBS, POSB, OCBC, UOB, MariBank, Citibank, HSBC, Maybank, Standard Chartered).
Analyze the uploaded statement document/image and extract:

1. STATEMENT TYPE:
   - If this is a Bank Account Statement (e.g. POSB eSavings, DBS Multi-Currency, OCBC 360, UOB One), extract details into "accounts".
   - If this is a Credit Card Statement (e.g. Citi PremierMiles, DBS Altitude, UOB PRVI, HSBC Revolution), extract details into "cardDraft".

2. BANK STATEMENT DETAILS ("accounts"):
   - bankName: Exact Bank Name extracted directly from the statement header/logo (e.g. POSB, DBS Bank, OCBC Bank, UOB, MariBank, Citibank, HSBC, Maybank, Standard Chartered).
   - accountName: Exact account description from statement (e.g. "eSavings Account", "Multi-Currency Account", "One Account", "360 Account"). DO NOT invent names or use file names.
   - accountNumber: Full or masked account number printed on the statement (e.g. "123-45678-9" or "123-****-9"). If not found, return empty string "". NEVER invent fake numbers.
   - statementEndingBalance: Statement ending / closing balance as a double (e.g. 1250.50). Look for "Closing Balance", "Ending Balance", "Total Balance", "Balance Carried Forward".
   - currency: 3-letter currency code (e.g. "SGD", "USD", "EUR").
   - statementEndingDate: Statement date or period end date in YYYY-MM-DD format (e.g. "2026-06-30").

3. CREDIT CARD STATEMENT DETAILS ("cardDraft"):
   - cardIssuer: Bank Issuer (e.g. Citibank, DBS Bank, OCBC Bank, UOB, HSBC, Maybank, Standard Chartered).
   - cardType: Card Brand (Visa, Mastercard, Amex).
   - cardName: Full Card Product Name from the statement (e.g. "CITI PREMIERMILES WORLD MASTER", "DBS ALTITUDE VISA", "UOB PRVI MILES").
   - cardNumber: Card number printed on the statement (e.g. "5425-XXXX-7628" or last 4 digits).
   - hasMiles: true if statement shows miles/points rewards, false if cashback.
   - milesOpening: Opening miles balance as string.
   - milesEarned: Miles earned this month as string.
   - milesBonus: Bonus miles earned this month as string.
   - milesRedeemed: Miles redeemed as string.
   - milesEnding: Ending miles balance as string.
   - milesRates: Array of earn rates [{ "category": "SGD Spend", "rate": "1.2", "minSpend": "", "maxSpend": "" }].
   - hasCashback: true if cashback card.
   - cashbackEarned: Cashback amount earned as string.
   - cashbackRates: Array of cashback rates [{ "category": "Dining", "rate": "6%", "minSpend": "800", "maxSpend": "" }].
   - totalSpend: Total card spend this statement period as a decimal string (e.g. "450.80"). Look for "Total Current Charges" or "Total Purchases".
   - paymentDueDate: Payment due date in YYYY-MM-DD format (e.g. "2026-07-15").

4. TRANSACTIONS LIST ("extractedTransactions"):
   CRITICAL RULES TO EXTRACT ALL 90+ TRANSACTIONS:
   - This document contains multiple transaction tables across pages 1, 2, 3, 4, and 5.
   - You MUST read and extract EVERY transaction row from EVERY page sequentially.
   - Extract rows from the Principal card table (e.g. Page 1, Page 2, Page 3, Page 4) AND CONTINUE extracting from the Supplementary / Additional card table (e.g. Page 4, Page 5).
   - DO NOT stop after Page 2 or Page 3. DO NOT group, summarize, or sample transactions. Return the full list of all 90+ rows.
   - Use compact single-letter keys to maximize token space:
     * "d": Date formatted as DD MMM YYYY (e.g. "25 May 2026", "04 Jun 2026", "23 Jun 2026"). Look at the TRANSACTION DATE column.
     * "m": Clean merchant/description (e.g. "Vivifi", "McDonalds", "Lotus's KSL City", "Sheng Siong", "Shopee", "Taobao", "Pinduoduo", "Giro Pymt").
     * "a": Transaction amount double. EXPENSES / PURCHASES MUST BE NEGATIVE (e.g. -9.00, -35.88), CREDITS / PAYMENTS / CASHBACK MUST BE POSITIVE (e.g. 57.71, 888.73). Look for "CR" suffix for positive values.
     * "c": Exact category (e.g. 'expense_groceries', 'expense_dining', 'expense_transport', 'expense_shopping', 'expense_utilities', 'expense_other', 'income_transfer').
     * "cur": "SGD Spend" (or "SGD Receipt" if CR / Payment, or "MYR spend" / "FCY Spend" if foreign).

STRICT SINGAPORE CATEGORIZATION RULES:
- Interest Earned / INT / INT CR / Bonus Interest / Savings Interest / Credit Int (amount > 0) -> 'income_interest'.
- Salary / Payroll / Bonus / AWS / CPF -> 'income_salary'.
- ATM Cash Withdrawals -> 'expense_transfer_to_cash'.
- Taxes & IRAS -> 'expense_tax'.
- PayNow / FAST / FAST Transfer / Giro / Fund Transfers:
  * If positive (amount > 0) -> 'income_transfer' (Transfer In / Payment).
  * If negative (amount < 0) -> 'expense_transfer' (Transfer Out).
- Insurance (AIA, Prudential, Great Eastern, Aviva, Singlife, NTUC Income, AXA, FWD, Manulife) -> 'expense_insurance'.
- Healthcare (Raffles Medical, Mount Elizabeth, Parkway, Gleneagles, Guardian, Watsons, Polyclinic, Hospitals, Clinics, Dental) -> 'expense_healthcare'.
- Petrol / Gas (Shell, Esso, SPC, Caltex) -> 'expense_petrol'.
- Supermarkets (NTUC FairPrice, Sheng Siong, Cold Storage, Giant, Don Don Donki, Meidi-Ya, Prime Super, RedMart, Lotus's, Ang Mo Supermarket) -> 'expense_groceries'.
- Transport & Rides (SimplyGo, BUS/MRT, SMRT, SBS Transit, Grab ride, Gojek, Tada, ComfortDelGro) -> 'expense_transport'.
- Dining & Delivery (Foodpanda, Deliveroo, GrabFood, McDonald's, Starbucks, Toast Box, Ya Kun, Koufu, Kopitiam, Mixue, Pizza Hut, KFC, TGV, Saizeriya, The Hainan Story, Cantine, Sultan Prata, Coffee Bean) -> 'expense_dining'.
- Utilities & Telco (Singtel, StarHub, M1, Simba, Vivifi, Eight Telecom, Whiz Communications, SP Services, SP Group, PUB) -> 'expense_utilities'.
- Streaming & Entertainment (Netflix, Spotify, Disney+, YouTube, Golden Village, Cathay, Shaw) -> 'expense_entertainment'.
- Travel (SIA, Scoot, Jetstar, AirAsia, Klook, Agoda, Booking.com, Hotels) -> 'expense_travel'.
- Shopping (Shopee, Lazada, Amazon, Taobao, Pinduoduo, Uniqlo, Zara, H&M, Takashimaya, Tangs, 7-Eleven, Cheers) -> 'expense_shopping'.
$userRulesSection
You MUST return a raw JSON object formatted precisely as follows:
{
  "accounts": [
    {
      "bankName": "Bank Name",
      "accountName": "Account or Card Product Name",
      "accountNumber": "1234-5678-9012-3456",
      "statementEndingBalance": 876.32,
      "currency": "SGD",
      "statementEndingDate": "2026-06-25"
    }
  ],
  "cardDraft": {
    "cardIssuer": "Bank Issuer",
    "cardType": "Mastercard",
    "cardName": "Full Card Product Name",
    "cardNumber": "1234-5678-9012-3456",
    "hasMiles": false,
    "hasCashback": true,
    "cashbackEarned": "57.71",
    "totalSpend": "905.46",
    "statementEndingDate": "2026-06-25",
    "paymentDueDate": "2026-07-15"
  },
  "extractedTransactions": [
    {
      "d": "25 May 2026",
      "m": "Vivifi",
      "a": -9.00,
      "c": "expense_utilities",
      "cur": "SGD Spend"
    },
    {
      "d": "25 May 2026",
      "m": "McDonalds 930234",
      "a": -1.00,
      "c": "expense_dining",
      "cur": "SGD Spend"
    }
  ]
}
''';

    String? jsonResponseText;
    Map<String, dynamic>? parsedJsonMap;
    Object? lastErr;

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < modelNames.length; i++) {
      if (stopwatch.elapsed.inSeconds >= 110) break; // Keep strictly within 120s limit
      final mName = modelNames[i];
      int attempts = 0;
      while (attempts < 2) {
        if (stopwatch.elapsed.inSeconds >= 110) break;
        attempts++;
        try {
          final headers = <String, String>{'Content-Type': 'application/json'};
          if (_apiKey.isNotEmpty && !_apiKey.startsWith('PROXY')) {
            headers['x-gemini-key'] = _apiKey;
          }

          final perAttemptSeconds = 75;

          final proxyRes = await dio.post(
            '/api/gemini?model=$mName',
            data: {
              'contents': [
                {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': mimeType,
                        'data': base64Data,
                      }
                    },
                    {
                      'text': promptText,
                    }
                  ]
                }
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'maxOutputTokens': 8192,
              },
            },
            options: Options(
              headers: headers,
              sendTimeout: Duration(seconds: perAttemptSeconds),
              receiveTimeout: Duration(seconds: perAttemptSeconds),
            ),
          );

          if (proxyRes.statusCode == 200 && proxyRes.data != null) {
            final Map<String, dynamic> body = proxyRes.data is String
                ? jsonDecode(proxyRes.data as String) as Map<String, dynamic>
                : proxyRes.data as Map<String, dynamic>;

            final candidates = body['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  // Validate that the JSON can be parsed or repaired
                  final validatedJson = _tryParseOrRepairJson(text);
                  if (validatedJson != null) {
                    jsonResponseText = text;
                    parsedJsonMap = validatedJson;
                    print('Successfully extracted and validated JSON using model: $mName');
                    break;
                  } else {
                    print('Model $mName produced unparsable JSON, attempting next model engine...');
                    lastErr = 'Model $mName produced unparsable JSON text (length: ${text.length})';
                  }
                }
              }
            }
          }
        } catch (e) {
          lastErr = e is DioException && e.response?.data != null ? e.response?.data : e;
          print('DEBUG Proxy Gemini model $mName failed (attempt $attempts): $lastErr');
          
          if (e is DioException) {
            if (e.response?.statusCode == 429) {
              AnalyticsService().logEvent('gemini_rate_limit_exceeded', parameters: {
                'model': mName,
                'attempt': attempts,
              });
              // First 3 engines: pause 5-6s, remainder engines: pause 10s
              final pauseSec = i < 3 ? 5 : 10;
              if (stopwatch.elapsed.inSeconds + pauseSec < 115) {
                await Future.delayed(Duration(seconds: pauseSec));
              }
              if (attempts < 2) {
                continue;
              }
            } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
              AnalyticsService().logEvent('gemini_service_unavailable', parameters: {
                'model': mName,
                'statusCode': e.response?.statusCode,
              });
            }
          }
        }
        break;
      }

      if (parsedJsonMap != null) {
        break;
      }
    }

    if (parsedJsonMap == null) {
      AnalyticsService().logEvent('gemini_extraction_failed', parameters: {
        'error': lastErr.toString(),
      });
      throw Exception('Gemini API extraction failed across all models. Last error: $lastErr');
    }

    final Map<String, dynamic> parsed = parsedJsonMap;
    final String cleanText = (jsonResponseText ?? '').trim();

    final List<dynamic> rawAccounts = (parsed['accounts'] as List<dynamic>?) ?? 
        (parsed['accountList'] as List<dynamic>?) ?? 
        (parsed['bankAccounts'] as List<dynamic>?) ?? [];

    final List<dynamic> rawTransactions = (parsed['extractedTransactions'] as List<dynamic>?) ?? 
        (parsed['transactions'] as List<dynamic>?) ?? 
        (parsed['transactionsList'] as List<dynamic>?) ?? 
        (parsed['statementTransactions'] as List<dynamic>?) ?? 
        (parsed['items'] as List<dynamic>?) ?? 
        (parsed['history'] as List<dynamic>?) ?? [];

    final accounts = rawAccounts.map((acc) {
      String bankVal = (acc['bankName'] as String? ?? acc['bank'] as String? ?? '').trim();
      String nameVal = (acc['accountName'] as String? ?? acc['name'] as String? ?? '').trim();
      String numVal = (acc['accountNumber'] as String? ?? acc['num'] as String? ?? '').trim();
      final curVal = (acc['currency'] as String? ?? 'SGD').trim().toUpperCase();

      final fullLowerText = cleanText.toLowerCase();
      if (bankVal.isEmpty || bankVal == 'Bank') {
        if (fullLowerText.contains('posb')) {
          bankVal = 'POSB';
        } else if (fullLowerText.contains('dbs')) {
          bankVal = 'DBS Bank';
        } else if (fullLowerText.contains('ocbc')) {
          bankVal = 'OCBC Bank';
        } else if (fullLowerText.contains('uob')) {
          bankVal = 'UOB';
        } else if (fullLowerText.contains('maribank')) {
          bankVal = 'MariBank';
        } else if (fullLowerText.contains('citi')) {
          bankVal = 'Citibank';
        } else if (fullLowerText.contains('hsbc')) {
          bankVal = 'HSBC';
        } else if (fullLowerText.contains('maybank')) {
          bankVal = 'Maybank';
        } else if (fullLowerText.contains('standard chartered') || fullLowerText.contains('stanbic')) {
          bankVal = 'Standard Chartered';
        } else {
          bankVal = 'Bank Account';
        }
      }

      if (nameVal.isEmpty || nameVal.contains('stater') || nameVal.contains('statement') || nameVal.contains('.pdf')) {
        nameVal = '$bankVal Account';
      }

      if (numVal == '****' || numVal == '123-45678-9') {
        final numMatch = RegExp(r'\b\d{3}-\d{5,6}-\d\b|\b\d{3}-\d{3}-\d{3}-\d\b|\b\d{3}-\d{6}\b|\b\d{9,12}\b').firstMatch(cleanText);
        if (numMatch != null) {
          numVal = numMatch.group(0)!;
        } else {
          numVal = '';
        }
      }
      
      dynamic balObj = acc['statementEndingBalance'] ?? acc['balance'];
      String balVal = '0.00';
      if (balObj != null) {
        balVal = balObj.toString();
      }

      final dateStr = acc['statementEndingDate'] as String? ?? acc['balanceAsOfIso'] as String?;
      DateTime dateVal = DateTime.now();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          dateVal = DateTime.parse(dateStr);
        } catch (_) {}
      }

      return ExtractedAccountDraft(
        bank: bankVal,
        name: nameVal,
        num: numVal,
        currency: curVal,
        balance: balVal,
        balanceAsOf: dateVal,
      );
    }).toList();

    ExtractedCreditCardDraft? cardDraft;
    if (parsed['cardDraft'] != null) {
      final cardMap = parsed['cardDraft'] as Map<String, dynamic>;
      final List<dynamic> rawMilesRates = cardMap['milesRates'] as List<dynamic>? ?? [];
      final List<dynamic> rawCashbackRates = cardMap['cashbackRates'] as List<dynamic>? ?? [];
      final cardNameStr = cardMap['cardName'] as String? ?? '';
      final lowerName = cardNameStr.toLowerCase();
      final isMilesCard = (cardMap['hasMiles'] as bool? ?? false) || lowerName.contains('90') || lowerName.contains('miles') || lowerName.contains('points') || lowerName.contains('voyage') || lowerName.contains('altitude') || lowerName.contains('prvi');

      dynamic spendObj = cardMap['totalSpend'];
      String spendStr = '0.00';
      if (spendObj != null) {
        spendStr = spendObj.toString();
      }

      final dueStr = cardMap['paymentDueDate'] as String? ?? cardMap['paymentDueDateIso'] as String?;
      DateTime dueVal = DateTime.now().add(const Duration(days: 20));
      if (dueStr != null && dueStr.isNotEmpty) {
        try {
          dueVal = DateTime.parse(dueStr);
        } catch (_) {}
      }

      // Auto-lookup card rules from CardRulesRegistry for exact earn rates
      CardCalculationRule? registryRule;
      for (final entry in CardRulesRegistry.registry.entries) {
        final keyClean = entry.key.replaceAll('_', ' ').toLowerCase();
        if (lowerName.isNotEmpty && (lowerName.contains(keyClean) || keyClean.contains(lowerName))) {
          registryRule = entry.value;
          break;
        }
      }

      final List<ExtractedRewardRate> milesRates = [];
      final List<ExtractedRewardRate> cashbackRates = [];

      if (rawMilesRates.isNotEmpty) {
        milesRates.addAll(rawMilesRates.map((r) => ExtractedRewardRate(
          category: r['category'] as String? ?? 'SGD Spend',
          rate: r['rate'] as String? ?? '1.2',
          minSpend: r['minSpend'] as String? ?? '',
          maxSpend: r['maxSpend'] as String? ?? '',
        )));
      } else if (registryRule != null && isMilesCard) {
        milesRates.addAll(registryRule.defaultRatesList.map((r) => ExtractedRewardRate(
          category: r['category'] as String? ?? 'SGD Spend',
          rate: r['rate'] as String? ?? '1.2',
          minSpend: r['minSpend'] as String? ?? '',
          maxSpend: r['maxSpend'] as String? ?? '',
        )));
      } else if (isMilesCard) {
        milesRates.addAll([
          ExtractedRewardRate(category: 'SGD Spend', rate: '1.2', minSpend: '', maxSpend: ''),
          ExtractedRewardRate(category: 'FCY spend', rate: '2.0', minSpend: '', maxSpend: ''),
        ]);
      }

      if (rawCashbackRates.isNotEmpty) {
        cashbackRates.addAll(rawCashbackRates.map((r) => ExtractedRewardRate(
          category: r['category'] as String? ?? 'Dining',
          rate: r['rate'] as String? ?? '1.5',
          minSpend: r['minSpend'] as String? ?? '',
          maxSpend: r['maxSpend'] as String? ?? '',
        )));
      } else if (registryRule != null && !isMilesCard) {
        cashbackRates.addAll(registryRule.defaultRatesList.map((r) => ExtractedRewardRate(
          category: r['category'] as String? ?? 'Dining',
          rate: r['rate'] as String? ?? '1.5',
          minSpend: r['minSpend'] as String? ?? '',
          maxSpend: r['maxSpend'] as String? ?? '',
        )));
      }

      cardDraft = ExtractedCreditCardDraft(
        issuer: cardMap['cardIssuer'] as String? ?? cardMap['issuer'] as String? ?? '',
        cardType: cardMap['cardType'] as String? ?? 'Mastercard',
        cardName: cardNameStr.isNotEmpty ? cardNameStr : 'Credit Card',
        cardNumber: cardMap['cardNumber'] as String? ?? '',
        hasMiles: isMilesCard,
        milesOpening: cardMap['milesOpening'] as String? ?? '',
        milesEarned: cardMap['milesEarned'] as String? ?? '',
        milesBonus: cardMap['milesBonus'] as String? ?? '',
        milesRedeemed: cardMap['milesRedeemed'] as String? ?? '',
        milesEnding: cardMap['milesEnding'] as String? ?? '',
        milesRates: milesRates,
        hasCashback: !isMilesCard,
        cashbackEarned: cardMap['cashbackEarned'] as String? ?? '',
        cashbackRates: cashbackRates,
        totalSpend: spendStr,
        paymentDueDate: dueVal,
      );
    }

    final transactions = <ExtractedTransactionDraft>[];
    for (final tx in rawTransactions) {
      final merchantStr = tx['m'] as String? ?? tx['merchant'] as String? ?? 'Transaction';
      dynamic amtObj = tx['a'] ?? tx['amount'];
      double rawAmount = 0.0;
      if (amtObj is num) {
        rawAmount = amtObj.toDouble();
      } else if (amtObj is String) {
        rawAmount = double.tryParse(amtObj) ?? 0.0;
      }

      final geminiCat = tx['c'] as String? ?? tx['categoryValue'] as String? ?? 'expense_other';
      final geminiMilesCat = tx['milesCashbackCategoryValue'] as String? ?? 'Others';
      final spendCur = tx['cur'] as String? ?? tx['spendCurrency'] as String? ?? 'SGD Spend';
      final dateValueStr = tx['d'] as String? ?? tx['date'] as String? ?? tx['dateStr'] as String? ?? '';

      // Pass through Intelligent Classifier + User Learned Rules Engine
      final classified = await MerchantCategoryClassifier.classify(
        merchant: merchantStr,
        amount: rawAmount,
        currentExpenseCategory: geminiCat,
        currentMilesCategory: geminiMilesCat,
        rulesService: rulesService,
      );

      transactions.add(ExtractedTransactionDraft(
        dateStr: dateValueStr,
        merchant: merchantStr,
        amount: rawAmount,
        categoryValue: classified.expenseCategory,
        milesCashbackCategoryValue: classified.milesCategory,
        spendCurrency: spendCur,
      ));
    }

    return DraftStatementData(
      accounts: accounts,
      cardDraft: cardDraft,
      transactions: transactions,
    );
  }

  /// Parses voice transcripts or text phrases like "Kopi $1.50" or "Lunch $5.20" into structured expense data.
  Future<Map<String, dynamic>> parseVoiceOrTextExpense(String inputPhrase) async {
    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
    );

    final prompt = [
      Content.multi([
        TextPart('''
You are an expert personal finance AI assistant for Singapore users.
The user provides a short voice transcript or text phrase describing a cash expense, e.g.:
- "Kopi \$1.50"
- "Lunch \$5.20"
- "Grab ride to office \$14"
- "Sheng Siong groceries \$35.40"

Analyze the input phrase and return a raw JSON object with precisely these keys:
{
  "merchant": "Cleaned description/merchant name, e.g., 'Kopi', 'Lunch', 'Grab Ride'",
  "amount": "Positive double number representing amount spent, e.g., 1.50",
  "categoryValue": "One of exact category strings: 'expense_dining', 'expense_groceries', 'expense_transport', 'expense_shopping', 'expense_entertainment', 'expense_travel', 'expense_utilities', 'expense_investments', 'expense_tax', 'expense_other'"
}

User input phrase: "$inputPhrase"
''')
      ])
    ];

    final response = await model.generateContent(prompt);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Could not parse voice expense phrase.');
    }

    String cleanText = text.trim();
    if (cleanText.contains('```') || !cleanText.startsWith('{')) {
      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');
      if (start != -1 && end != -1) {
        cleanText = cleanText.substring(start, end + 1);
      }
    }

    final parsed = json.decode(cleanText) as Map<String, dynamic>;
    return {
      'merchant': parsed['merchant']?.toString() ?? inputPhrase,
      'amount': (parsed['amount'] as num? ?? 0.0).toDouble(),
      'categoryValue': parsed['categoryValue']?.toString() ?? 'expense_other',
    };
  }

  /// Progressively tries to decode and repair potentially truncated or malformed JSON from Gemini LLM
  static Map<String, dynamic>? _tryParseOrRepairJson(String raw) {
    String cleanText = raw.trim();
    if (cleanText.contains('```') || !cleanText.startsWith('{')) {
      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        cleanText = cleanText.substring(start, end + 1);
      }
    }

    // 1. Direct standard parse
    try {
      final res = jsonDecode(cleanText);
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}

    // 2. Remove control characters and normalize escaped quotes and trailing commas
    try {
      String repaired = cleanText
          .replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F]'), ' ')
          .replaceAll(r'\"', '"')
          .replaceAll(RegExp(r',\s*([\}\]])'), r'$1');

      final res = jsonDecode(repaired);
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}

    // 3. Handle truncated JSON array / object from token limits by auto-closing brackets
    try {
      String truncated = cleanText
          .replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F]'), ' ')
          .replaceAll(r'\"', '"');

      // Cut off incomplete trailing JSON tokens (e.g. incomplete key/value at the end)
      final lastClosingBrace = truncated.lastIndexOf('}');
      if (lastClosingBrace != -1) {
        String sub = truncated.substring(0, lastClosingBrace + 1);
        sub = sub.replaceAll(RegExp(r',\s*([\}\]])'), r'$1');
        // Count unclosed brackets
        int openBraces = 0;
        int openBrackets = 0;
        for (int i = 0; i < sub.length; i++) {
          final c = sub[i];
          if (c == '{') openBraces++;
          if (c == '}') openBraces--;
          if (c == '[') openBrackets++;
          if (c == ']') openBrackets--;
        }
        while (openBrackets > 0) {
          sub += ']';
          openBrackets--;
        }
        while (openBraces > 0) {
          sub += '}';
          openBraces--;
        }
        final res = jsonDecode(sub);
        if (res is Map<String, dynamic>) return res;
      }
    } catch (_) {}

    // 4. Outermost bracket extraction fallback
    try {
      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        String fixed = cleanText.substring(start, end + 1);
        fixed = fixed.replaceAll(RegExp(r',\s*([\}\]])'), r'$1');
        final res = jsonDecode(fixed);
        if (res is Map<String, dynamic>) return res;
      }
    } catch (_) {}

    return null;
  }
}
