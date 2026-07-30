import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/cashflow/upload/draft_statement_service.dart';

import 'merchant_category_classifier.dart';
import 'user_category_rules_service.dart';

class GeminiExtractionService {
  final String _apiKey;

  GeminiExtractionService(this._apiKey);

  Future<DraftStatementData> extractData({
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    // Proxy mode: skip direct API calls when using PROXY_VIA_VERCEL default key

    // 1. Initialize GenerativeModel
    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
    );

    // 2. Prepare file binary part
    final filePart = DataPart(mimeType, fileBytes);

    // 3. Build Prompt requesting strict JSON schema matching our Dart model fields
    final prompt = [
      Content.multi([
        filePart,
        TextPart('''
You are an expert financial AI specializing in Singapore bank and credit card statements. Analyze the uploaded statement and extract:
1. If this is a Bank Statement, extract Account Details into "accounts" (Bank Name, Account Name, Account Number, Statement Ending Balance, Currency, and Statement Ending Date).
2. If this is a Credit Card Statement, extract Credit Card Details into "cardDraft" (Issuer, Card Type, Card Name, Card Number, Reward/Miles summary, Miles rates, Cashback summary, Cashback rates, Total Spend, Payment Due Date).
3. All Transactions listed in the statement (Date, Merchant/Description, Amount, and Category).

STRICT CATEGORIZATION RULES FOR SINGAPORE TRANSACTIONS:
- ATM Cash Withdrawals ("ATM", "CASH WITHDRAWAL", "CASH W/DRAWAL"): categoryValue MUST BE 'expense_transfer_to_cash'.
- Taxes & Government Fees ("IRAS", "ETAX", "INLAND REVEN", "MINISTRY OF MANPOWER", "MOM", "TAX", "CUSTOMS"): categoryValue MUST BE 'expense_tax'.
- Interest & Bonus Interest ("BONUS INTEREST", "SAVINGS INT", "INTEREST", "CO SPEND BONUS"): categoryValue MUST BE 'income_other' for positive amounts.
- Transfers ("PAYNOW", "FAST PAYMENT", "PAYMENT W/TRANSFER", "TRF", "GIRO"): Use 'income_transfer' if amount > 0, else 'expense_transfer' (or 'expense_education' if tuition/course).
- Groceries ("NTUC", "FAIRPRICE", "SHENG SIONG", "COLD STORAGE", "GIANT", "DON DON DONKI"): categoryValue 'expense_groceries', milesCashbackCategoryValue 'Groceries'.
- Transport & SimplyGo ("GRAB", "GOJEK", "SIMPLYGO", "SMRT", "TRANSIT", "TADA"): categoryValue 'expense_transport', milesCashbackCategoryValue 'SimplyGo' or 'Commute'.
- Dining ("FOODPANDA", "DELIVEROO", "GRABFOOD", "MCDONALD", "KFC", "RESTAURANT", "CAFE", "STARBUCKS"): categoryValue 'expense_dining', milesCashbackCategoryValue 'Dining & Food Delivery'.
- Utilities & Telco ("SINGTEL", "STARHUB", "M1", "SP SERVICES", "PUB"): categoryValue 'expense_utilities'.

You MUST return a raw JSON object containing precisely the following format:
{
  "accounts": [
    {
      "bank": "Bank/Institution Name (e.g. Citi, DBS, MariBank, OCBC, UOB)",
      "name": "Account Name (e.g. Savings Account)",
      "num": "Last 4 digits or full account number if visible",
      "currency": "3-letter currency code (e.g. SGD, USD)",
      "balance": "Ending balance as a decimal string (e.g. 1250.50)",
      "balanceAsOfIso": "The date of the statement ending balance in ISO-8601 format (YYYY-MM-DD)"
    }
  ],
  "cardDraft": {
    "issuer": "Credit Card issuer bank (e.g. Citibank, HSBC, DBS, OCBC, UOB)",
    "cardType": "One of: Visa, Mastercard, Amex, JCB",
    "cardName": "Card Product Name (e.g. CITI PREMIERMILES WORLD MASTER)",
    "cardNumber": "Full or partially masked card number (e.g. 5425-5033-0193-7628)",
    "hasMiles": true,
    "milesOpening": "Opening balance of miles/points as string",
    "milesEarned": "Miles earned this month as string",
    "milesBonus": "Bonus miles earned this month as string",
    "milesRedeemed": "Miles redeemed or adjusted as string",
    "milesEnding": "Ending miles balance as string",
    "milesRates": [
      {
        "category": "Spend Category (e.g. SGD Spend, Foreign Currency Spend)",
        "rate": "Miles rate (e.g. 1.2 or 2.0) as string",
        "minSpend": "Minimum spend limit as string, or empty string",
        "maxSpend": "Maximum spend cap as string, or empty string"
      }
    ],
    "hasCashback": true,
    "cashbackEarned": "Cashback earned amount as string",
    "cashbackRates": [
      {
        "category": "Spend Category (e.g. Dining, Online Spend)",
        "rate": "Cashback percent rate (e.g. 6% or 1.5%) as string",
        "minSpend": "Minimum spend limit as string, or empty string",
        "maxSpend": "Maximum spend cap as string, or empty string"
      }
    ],
    "totalSpend": "Total spend this month (e.g. 220.57) as string",
    "paymentDueDateIso": "Payment due date in YYYY-MM-DD format (e.g. 2026-06-02)"
  },
  "transactions": [
    {
      "dateStr": "The date of transaction formatted as DD MMM YYYY (e.g. 25 Apr 2026)",
      "merchant": "Cleaned merchant/description (e.g. Sheng Siong Supermarket)",
      "amount": "The transaction amount as a double. EXPENSES MUST BE NEGATIVE NUMBERS, INCOME MUST BE POSITIVE NUMBERS (e.g. -42.50 or 150.00)",
      "spendCurrency": "For credit card transactions: IF amount is POSITIVE (> 0), spendCurrency MUST BE 'SGD Receipt'. Otherwise IF negative, select one of: SGD Spend, MYR spend, IDR spend, FCY Spend (based on transaction currency). Default is SGD Spend",
      "categoryValue": "Map the transaction to one of exact string values: 'expense_transfer_to_cash', 'expense_tax', 'expense_dining', 'expense_groceries', 'expense_transport', 'expense_shopping', 'expense_entertainment', 'expense_travel', 'expense_utilities', 'expense_investments', 'expense_education', 'expense_transfer', 'expense_other', 'income_salary', 'income_transfer', 'income_investments', 'income_dividends', 'income_other'",
      "milesCashbackCategoryValue": "For credit card transactions, map to one of exact string values: 'Automobile', 'Beauty & Wellness', 'Commute', 'Dining & Food Delivery', 'Entertainment', 'Groceries', 'Kids & Pets', 'Online', 'SimplyGo', 'Shopping', 'Fuel', 'Others'"
    }
  ]
}
''')
      ])
    ];

    // 4. Send request with multi-model fallback strategy (Direct Key & Vercel Serverless Proxy)
    final modelNames = [
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemini-flash-lite-latest',
      'gemini-flash-latest',
      'gemini-2.0-flash-lite',
      'gemini-2.0-flash',
    ];
    String? jsonResponseText;
    Object? lastErr;

    final dio = Dio();
    final String base64Data = base64Encode(fileBytes);
    final String promptText = '''
You are an expert financial AI specializing in Singapore bank and credit card statements. Analyze the uploaded statement and extract:
1. If this is a Bank Statement, extract Account Details into "accounts" (Bank Name, Account Name, Account Number, Statement Ending Balance, Currency, and Statement Ending Date).
2. If this is a Credit Card Statement, extract Credit Card Details into "cardDraft" (Issuer, Card Type, Card Name, Card Number, Reward/Miles summary, Miles rates, Cashback summary, Cashback rates, Total Spend, Payment Due Date).
3. All Transactions listed in the statement (Date, Merchant/Description, Amount, and Category).

STRICT CATEGORIZATION RULES FOR SINGAPORE TRANSACTIONS:
- ATM Cash Withdrawals ("ATM", "CASH WITHDRAWAL", "CASH W/DRAWAL"): categoryValue MUST BE 'expense_transfer_to_cash'.
- Taxes & Government Fees ("IRAS", "ETAX", "INLAND REVEN", "MINISTRY OF MANPOWER", "MOM", "TAX", "CUSTOMS"): categoryValue MUST BE 'expense_tax'.
- Interest & Bonus Interest ("BONUS INTEREST", "SAVINGS INT", "INTEREST", "CO SPEND BONUS"): categoryValue MUST BE 'income_other' for positive amounts.
- Transfers ("PAYNOW", "FAST PAYMENT", "PAYMENT W/TRANSFER", "TRF", "GIRO"): Use 'income_transfer' if amount > 0, else 'expense_transfer' (or 'expense_education' if tuition/course).
- Groceries ("NTUC", "FAIRPRICE", "SHENG SIONG", "COLD STORAGE", "GIANT", "DON DON DONKI"): categoryValue 'expense_groceries', milesCashbackCategoryValue 'Groceries'.
- Transport & SimplyGo ("GRAB", "GOJEK", "SIMPLYGO", "SMRT", "TRANSIT", "TADA"): categoryValue 'expense_transport', milesCashbackCategoryValue 'SimplyGo' or 'Commute'.
- Dining ("FOODPANDA", "DELIVEROO", "GRABFOOD", "MCDONALD", "KFC", "RESTAURANT", "CAFE", "STARBUCKS"): categoryValue 'expense_dining', milesCashbackCategoryValue 'Dining & Food Delivery'.
- Utilities & Telco ("SINGTEL", "STARHUB", "M1", "SP SERVICES", "PUB"): categoryValue 'expense_utilities'.

You MUST return a raw JSON object containing precisely the following format:
{
  "accounts": [
    {
      "bankName": "Exact Bank Name (e.g. DBS, OCBC, UOB, MariBank, Citibank)",
      "accountName": "Account description",
      "accountNumber": "Masked or full account number",
      "statementEndingBalance": 1234.56,
      "currency": "SGD",
      "statementEndingDate": "2026-06-30"
    }
  ],
  "cardDraft": {
    "cardIssuer": "Issuer Name",
    "cardType": "Visa/Mastercard/Amex",
    "cardName": "Card Name",
    "cardNumber": "Masked Card Number",
    "rewardSummary": "Summary",
    "milesRates": "Rates",
    "cashbackSummary": "Summary",
    "cashbackRates": "Rates",
    "totalSpend": 123.45,
    "paymentDueDate": "2026-07-15"
  },
  "extractedTransactions": [
    {
      "date": "2026-06-15",
      "merchant": "Cleaned merchant/description (e.g. Sheng Siong Supermarket)",
      "amount": "The transaction amount as a double. EXPENSES MUST BE NEGATIVE NUMBERS, INCOME MUST BE POSITIVE NUMBERS (e.g. -42.50 or 150.00)",
      "spendCurrency": "For credit card transactions: IF amount is POSITIVE (> 0), spendCurrency MUST BE 'SGD Receipt'. Otherwise IF negative, select one of: SGD Spend, MYR spend, IDR spend, FCY Spend (based on transaction currency). Default is SGD Spend",
      "categoryValue": "Map the transaction to one of exact string values: 'expense_transfer_to_cash', 'expense_tax', 'expense_dining', 'expense_groceries', 'expense_transport', 'expense_shopping', 'expense_entertainment', 'expense_travel', 'expense_utilities', 'expense_investments', 'expense_education', 'expense_transfer', 'expense_other', 'income_salary', 'income_transfer', 'income_investments', 'income_dividends', 'income_other'",
      "milesCashbackCategoryValue": "For credit card transactions, map to one of exact string values: 'Automobile', 'Beauty & Wellness', 'Commute', 'Dining & Food Delivery', 'Entertainment', 'Groceries', 'Kids & Pets', 'Online', 'SimplyGo', 'Shopping', 'Fuel', 'Others'"
    }
  ]
}
''';

    for (final mName in modelNames) {
      if (_apiKey.isNotEmpty && !_apiKey.startsWith('PROXY')) {
        try {
          final model = GenerativeModel(model: mName, apiKey: _apiKey);
          final response = await model.generateContent(prompt);
          if (response.text != null && response.text!.isNotEmpty) {
            jsonResponseText = response.text;
            print('Successfully extracted using direct Gemini API key: $mName');
            break;
          }
        } catch (e) {
          print('DEBUG Direct Gemini model $mName failed, trying serverless proxy: $e');
        }
      }

      // Try Vercel Serverless Proxy (/api/gemini) with automatic rate-limit retry
      int attempts = 0;
      while (attempts < 2) {
        attempts++;
        try {
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
            options: Options(headers: {'Content-Type': 'application/json'}),
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
          
          // If 429 Too Many Requests rate limit occurred, wait 4 seconds and retry once
          if (e is DioException && e.response?.statusCode == 429 && attempts < 2) {
            print('Rate limit (429) encountered. Waiting 4 seconds before retry...');
            await Future.delayed(const Duration(seconds: 4));
            continue;
          }
        }
        break; // Exit while loop if no retry needed
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

    final List<dynamic> rawAccounts = parsed['accounts'] as List<dynamic>? ?? [];
    final List<dynamic> rawTransactions = parsed['transactions'] as List<dynamic>? ?? [];

    final accounts = rawAccounts.map((acc) {
      return ExtractedAccountDraft(
        bank: acc['bank'] as String? ?? 'Unknown Bank',
        name: acc['name'] as String? ?? 'Savings Account',
        num: acc['num'] as String? ?? '',
        currency: acc['currency'] as String? ?? 'SGD',
        balance: acc['balance'] as String? ?? '0.00',
        balanceAsOf: acc['balanceAsOfIso'] != null
            ? DateTime.parse(acc['balanceAsOfIso'] as String)
            : DateTime.now(),
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

      cardDraft = ExtractedCreditCardDraft(
        issuer: cardMap['issuer'] as String? ?? '',
        cardType: cardMap['cardType'] as String? ?? 'Mastercard',
        cardName: cardNameStr,
        cardNumber: cardMap['cardNumber'] as String? ?? '',
        hasMiles: isMilesCard,
        milesOpening: cardMap['milesOpening'] as String? ?? '',
        milesEarned: cardMap['milesEarned'] as String? ?? '',
        milesBonus: cardMap['milesBonus'] as String? ?? '',
        milesRedeemed: cardMap['milesRedeemed'] as String? ?? '',
        milesEnding: cardMap['milesEnding'] as String? ?? '',
        milesRates: rawMilesRates.map((r) => ExtractedRewardRate(
          category: r['category'] as String? ?? 'SGD Spend',
          rate: r['rate'] as String? ?? '1.2',
          minSpend: r['minSpend'] as String? ?? '',
          maxSpend: r['maxSpend'] as String? ?? '',
        )).toList(),
        hasCashback: cardMap['hasCashback'] as bool? ?? false,
        cashbackEarned: cardMap['cashbackEarned'] as String? ?? '',
        cashbackRates: rawCashbackRates.map((r) => ExtractedRewardRate(
          category: r['category'] as String? ?? 'Dining',
          rate: r['rate'] as String? ?? '1.5',
          minSpend: r['minSpend'] as String? ?? '',
          maxSpend: r['maxSpend'] as String? ?? '',
        )).toList(),
        totalSpend: cardMap['totalSpend'] as String? ?? '0.00',
        paymentDueDate: cardMap['paymentDueDateIso'] != null
            ? DateTime.parse(cardMap['paymentDueDateIso'] as String)
            : DateTime.now().add(const Duration(days: 20)),
      );
    }

    final rulesService = UserCategoryRulesService();

    final transactions = <ExtractedTransactionDraft>[];
    for (final tx in rawTransactions) {
      final merchantStr = tx['merchant'] as String? ?? 'Transaction';
      final rawAmount = (tx['amount'] as num? ?? 0.0).toDouble();
      final geminiCat = tx['categoryValue'] as String? ?? 'expense_other';
      final geminiMilesCat = tx['milesCashbackCategoryValue'] as String? ?? 'Others';
      final spendCur = tx['spendCurrency'] as String? ?? 'SGD Spend';

      // Pass through Intelligent Classifier + User Learned Rules Engine
      final classified = await MerchantCategoryClassifier.classify(
        merchant: merchantStr,
        amount: rawAmount,
        currentExpenseCategory: geminiCat,
        currentMilesCategory: geminiMilesCat,
        rulesService: rulesService,
      );

      transactions.add(ExtractedTransactionDraft(
        dateStr: tx['dateStr'] as String? ?? '',
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
