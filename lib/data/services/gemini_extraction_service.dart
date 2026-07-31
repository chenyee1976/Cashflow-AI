import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/cashflow/upload/draft_statement_service.dart';

import 'card_rules_registry.dart';
import 'merchant_category_classifier.dart';
import 'user_category_rules_service.dart';

class GeminiExtractionService {
  final String _apiKey;

  GeminiExtractionService(this._apiKey);

  Future<DraftStatementData> extractData({
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final dio = Dio();
    final String base64Data = base64Encode(fileBytes);

    // Primary AI Models List (gemini-2.0-flash is flagship for document intelligence & OCR)
    final modelNames = [
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-2.0-flash-lite',
      'gemini-flash-latest',
    ];

    final String promptText = '''
You are an expert financial AI specializing in Singapore bank and credit card statements (DBS, POSB, OCBC, UOB, MariBank, Citibank, HSBC, Maybank, Standard Chartered).
Analyze the uploaded statement document/image and extract:

1. STATEMENT TYPE:
   - If this is a Bank Account Statement (e.g. POSB eSavings, DBS Multi-Currency, OCBC 360, UOB One), extract details into "accounts".
   - If this is a Credit Card Statement (e.g. Citi PremierMiles, DBS Altitude, UOB PRVI, HSBC Revolution), extract details into "cardDraft".

2. BANK STATEMENT DETAILS ("accounts"):
   - bankName: Exact Bank Name (e.g. POSB, DBS Bank, OCBC Bank, UOB, MariBank, Citibank). If POSB statement, MUST return "POSB".
   - accountName: Exact account description (e.g. "POSB eSavings Account", "DBS Multi-Currency Account", "Savings Account"). DO NOT use file names.
   - accountNumber: Account number (e.g. "123-45678-9" or masked "123-****-9").
   - statementEndingBalance: Ending balance as a double (e.g. 1250.50).
   - currency: 3-letter currency code (e.g. "SGD").
   - statementEndingDate: Ending date of statement in YYYY-MM-DD format (e.g. "2026-06-30").

3. CREDIT CARD STATEMENT DETAILS ("cardDraft"):
   - cardIssuer: Bank Issuer (e.g. Citibank, DBS Bank, OCBC Bank, UOB, HSBC).
   - cardType: Card Brand (Visa, Mastercard, Amex).
   - cardName: Full Card Product Name (e.g. "CITI PREMIERMILES WORLD MASTER", "DBS ALTITUDE VISA", "UOB PRVI MILES").
   - cardNumber: Card number (full or masked e.g. "5425-XXXX-7628").
   - hasMiles: true if statement shows miles/points, false if cashback.
   - milesOpening: Opening miles balance as string.
   - milesEarned: Miles earned this month as string.
   - milesBonus: Bonus miles earned this month as string.
   - milesRedeemed: Miles redeemed as string.
   - milesEnding: Ending miles balance as string.
   - milesRates: Array of earn rates [{ "category": "SGD Spend", "rate": "1.2", "minSpend": "", "maxSpend": "" }].
   - hasCashback: true if cashback card.
   - cashbackEarned: Cashback amount earned as string.
   - cashbackRates: Array of cashback rates [{ "category": "Dining", "rate": "6%", "minSpend": "800", "maxSpend": "" }].
   - totalSpend: Total card spend this statement period as a decimal string (e.g. "450.80").
   - paymentDueDate: Payment due date in YYYY-MM-DD format (e.g. "2026-07-15").

4. TRANSACTIONS LIST ("extractedTransactions"):
   Extract EVERY transaction row listed on the statement:
   - dateStr: Date formatted as DD MMM YYYY (e.g. "15 Jun 2026", "28 Jul 2026").
   - merchant: Cleaned merchant or description (e.g. "NTUC FairPrice", "Sheng Siong Supermarket", "PayNow to John", "ATM Cash Withdrawal", "IRAS Tax Payment", "Singtel Bill").
   - amount: Double value. EXPENSES MUST BE NEGATIVE (e.g. -42.50), INCOME/DEPOSITS MUST BE POSITIVE (e.g. 150.00).
   - spendCurrency: For credit cards, IF amount > 0 select "SGD Receipt", else select one of: "SGD Spend", "MYR spend", "IDR spend", "FCY Spend".
   - categoryValue: Select exact value: 'expense_transfer_to_cash', 'expense_tax', 'expense_dining', 'expense_groceries', 'expense_transport', 'expense_shopping', 'expense_entertainment', 'expense_travel', 'expense_utilities', 'expense_investments', 'expense_education', 'expense_transfer', 'expense_other', 'income_salary', 'income_transfer', 'income_investments', 'income_dividends', 'income_other'.
   - milesCashbackCategoryValue: Select exact value: 'Automobile', 'Beauty & Wellness', 'Commute', 'Dining & Food Delivery', 'Entertainment', 'Groceries', 'Kids & Pets', 'Online', 'SimplyGo', 'Shopping', 'Fuel', 'Others'.

STRICT SINGAPORE CATEGORIZATION RULES:
- ATM Cash Withdrawals -> categoryValue 'expense_transfer_to_cash'.
- Taxes & IRAS -> categoryValue 'expense_tax'.
- PayNow / FAST / Giro Transfers -> categoryValue 'income_transfer' (if > 0) or 'expense_transfer' (if < 0).
- NTUC / FairPrice / Sheng Siong / Cold Storage -> 'expense_groceries', milesCategory 'Groceries'.
- Grab / Gojek / SimplyGo / SMRT -> 'expense_transport', milesCategory 'SimplyGo' or 'Commute'.
- Foodpanda / Deliveroo / GrabFood / McDonald's / Starbucks -> 'expense_dining', milesCategory 'Dining & Food Delivery'.
- Singtel / StarHub / M1 / SP Services -> 'expense_utilities'.

You MUST return a raw JSON object formatted precisely as follows:
{
  "accounts": [
    {
      "bankName": "POSB",
      "accountName": "POSB eSavings Account",
      "accountNumber": "123-45678-9",
      "statementEndingBalance": 1250.50,
      "currency": "SGD",
      "statementEndingDate": "2026-06-30"
    }
  ],
  "cardDraft": {
    "cardIssuer": "Citibank",
    "cardType": "Mastercard",
    "cardName": "CITI PREMIERMILES WORLD MASTER",
    "cardNumber": "5425-XXXX-7628",
    "hasMiles": true,
    "milesEnding": "12500",
    "totalSpend": 450.80,
    "paymentDueDate": "2026-07-15"
  },
  "extractedTransactions": [
    {
      "dateStr": "15 Jun 2026",
      "merchant": "NTUC FairPrice",
      "amount": -42.50,
      "spendCurrency": "SGD Spend",
      "categoryValue": "expense_groceries",
      "milesCashbackCategoryValue": "Groceries"
    }
  ]
}
''';

    String? jsonResponseText;
    Object? lastErr;

    for (final mName in modelNames) {
      int attempts = 0;
      while (attempts < 2) {
        attempts++;
        try {
          final headers = <String, String>{'Content-Type': 'application/json'};
          if (_apiKey.isNotEmpty && !_apiKey.startsWith('PROXY')) {
            headers['x-gemini-key'] = _apiKey;
          }

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
              ]
            },
            options: Options(
              headers: headers,
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
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
                  jsonResponseText = text;
                  print('Successfully extracted using Vercel Serverless Proxy model: $mName');
                  break;
                }
              }
            }
          }
        } catch (e) {
          lastErr = e is DioException && e.response?.data != null ? e.response?.data : e;
          print('DEBUG Proxy Gemini model $mName failed (attempt $attempts): $lastErr');
          
          if (e is DioException && e.response?.statusCode == 429 && attempts < 2) {
            await Future.delayed(const Duration(seconds: 4));
            continue;
          }
        }
        break;
      }

      if (jsonResponseText != null && jsonResponseText.isNotEmpty) {
        break;
      }
    }

    if (jsonResponseText == null || jsonResponseText.isEmpty) {
      throw Exception('Gemini API extraction failed across models. Last error: $lastErr');
    }
    final text = jsonResponseText;

    // 5. Decode JSON and map to target structures
    String cleanText = text.trim();
    if (cleanText.contains('```') || !cleanText.startsWith('{')) {
      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');
      if (start != -1 && end != -1) {
        cleanText = cleanText.substring(start, end + 1);
      }
    }
    final Map<String, dynamic> parsed = jsonDecode(cleanText) as Map<String, dynamic>;

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
      String bankVal = acc['bankName'] as String? ?? acc['bank'] as String? ?? '';
      String nameVal = acc['accountName'] as String? ?? acc['name'] as String? ?? '';
      String numVal = acc['accountNumber'] as String? ?? acc['num'] as String? ?? '';
      final curVal = acc['currency'] as String? ?? 'SGD';

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
        } else {
          bankVal = 'POSB';
        }
      }

      if (nameVal.isEmpty || nameVal.contains('stater') || nameVal.contains('statement') || nameVal.contains('.pdf')) {
        if (bankVal.toUpperCase().contains('POSB')) {
          nameVal = 'POSB eSavings Account';
        } else if (bankVal.toUpperCase().contains('DBS')) {
          nameVal = 'DBS Multi-Currency Account';
        } else {
          nameVal = '$bankVal Savings Account';
        }
      }

      if (numVal.isEmpty || numVal == '****') {
        final numMatch = RegExp(r'\b\d{3}-\d{5}-\d\b|\b\d{9,10}\b').firstMatch(cleanText);
        if (numMatch != null) {
          numVal = numMatch.group(0)!;
        } else {
          numVal = '123-45678-9';
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

    final rulesService = UserCategoryRulesService();

    final transactions = <ExtractedTransactionDraft>[];
    for (final tx in rawTransactions) {
      final merchantStr = tx['merchant'] as String? ?? 'Transaction';
      dynamic amtObj = tx['amount'];
      double rawAmount = 0.0;
      if (amtObj is num) {
        rawAmount = amtObj.toDouble();
      } else if (amtObj is String) {
        rawAmount = double.tryParse(amtObj) ?? 0.0;
      }

      final geminiCat = tx['categoryValue'] as String? ?? 'expense_other';
      final geminiMilesCat = tx['milesCashbackCategoryValue'] as String? ?? 'Others';
      final spendCur = tx['spendCurrency'] as String? ?? 'SGD Spend';
      final dateValueStr = tx['date'] as String? ?? tx['dateStr'] as String? ?? '';

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
}
