import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/cashflow/upload/draft_statement_service.dart';

class GeminiExtractionService {
  final String _apiKey;

  GeminiExtractionService(this._apiKey);

  Future<DraftStatementData> extractData({
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    try {
      final dio = Dio();
      final res = await dio.get('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey');
      print('DEBUG LIST MODELS RESULT: ${res.data}');
    } catch (e) {
      print('DEBUG LIST MODELS FAILED: $e');
    }

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
You are an expert financial AI. Analyze the uploaded bank statement or credit card statement and extract:
1. If this is a Bank Statement, extract Account Details into "accounts" (Bank Name, Account Name, Account Number, Statement Ending Balance, Currency, and Statement Ending Date).
2. If this is a Credit Card Statement, extract Credit Card Details into "cardDraft" (Issuer, Card Type, Card Name, Card Number, Reward/Miles summary, Miles rates, Cashback summary, Cashback rates, Total Spend, Payment Due Date).
3. All Transactions listed in the statement (Date, Merchant/Description, Amount, and Category).

You MUST return a raw JSON object containing precisely the following format:
{
  "accounts": [
    {
      "bank": "Bank/Institution Name (e.g. Citi, DBS, MariBank)",
      "name": "Account Name (e.g. Savings Account)",
      "num": "Last 4 digits or full account number if visible",
      "currency": "3-letter currency code (e.g. SGD, USD)",
      "balance": "Ending balance as a decimal string (e.g. 1250.50)",
      "balanceAsOfIso": "The date of the statement ending balance in ISO-8601 format (YYYY-MM-DD)"
    }
  ],
  "cardDraft": {
    "issuer": "Credit Card issuer bank (e.g. Citibank, HSBC, DBS)",
    "cardType": "One of: Visa, Mastercard, Amex, JCB",
    "cardName": "Card Product Name (e.g. CITI PREMIERMILES WORLD MASTER)",
    "cardNumber": "Full or partially masked card number (e.g. 5425-5033-0193-7628)",
    "hasMiles": true, // set to true if statement contains any miles or reward points summary details
    "milesOpening": "Opening balance of miles/points (e.g. 104889) as string",
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
    "hasCashback": true, // set to true if statement contains any cashback summary details
    "cashbackEarned": "Cashback earned amount (e.g. 12.50) as string",
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
      "categoryValue": "Map the transaction to one of the following exact string values:
        - 'expense_transfer_to_cash' (Use for ATM cash withdrawals, cash payouts, cash transfers)
        - 'expense_dining' (Use for dining, food, restaurants, pizza, cafe, food delivery etc.)
        - 'expense_groceries' (Use for supermarkets, biomarks, convenience stores etc.)
        - 'expense_transport' (Use for commute, train, bus, ride sharing, metro etc.)
        - 'expense_shopping' (Use for clothing, online shopping, department stores etc.)
        - 'expense_entertainment' (Use for cinemas, shows, games etc.)
        - 'expense_travel' (Use for flights, hotels, bookings etc.)
        - 'expense_utilities' (Use for phone, water, electricity bills etc.)
        - 'expense_investments' (Use for stocks, insurance, investments etc.)
        - 'expense_tax' (Use for income tax, property tax, tax services, IRAS, custom taxes etc.)
        - 'expense_transfer'
        - 'expense_other'
        - 'income_salary'
        - 'income_transfer'
        - 'income_investments'
        - 'income_dividends'
        - 'income_other'",
      "milesCashbackCategoryValue": "For credit card transactions, map to one of the following exact string values (do not create others):
        - 'Automobile'
        - 'Beauty & Wellness'
        - 'Commute'
        - 'Dining & Food Delivery' (Use for restaurant, pizza, kebab, food outlets, cafes etc.)
        - 'Entertainment'
        - 'Groceries' (Use for supermarkets, minimarts, biomarks etc.)
        - 'Kids & Pets'
        - 'Online'
        - 'SimplyGo' (Use for public transit transactions like SimplyGo, bus, train)
        - 'Shopping' (Use for fashion, souvenir, department store, mall purchases etc.)
        - 'Fuel' (Use for petrol/gas stations)
        - 'Others'"
    }
  ]
}
''')
      ])
    ];

    // 4. Send request
    final response = await model.generateContent(prompt);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini API returned empty response');
    }

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
        milesRates: rawMilesRates.map((r) => ExtractedRewardRate.fromJson(r as Map<String, dynamic>)).toList(),
        hasCashback: cardMap['hasCashback'] as bool? ?? false,
        cashbackEarned: cardMap['cashbackEarned'] as String? ?? '',
        cashbackRates: rawCashbackRates.map((r) => ExtractedRewardRate.fromJson(r as Map<String, dynamic>)).toList(),
        totalSpend: cardMap['totalSpend'] as String? ?? '',
        paymentDueDate: cardMap['paymentDueDateIso'] != null
            ? DateTime.parse(cardMap['paymentDueDateIso'] as String)
            : DateTime.now(),
      );
    }

    final transactions = rawTransactions.map((tx) {
      return ExtractedTransactionDraft(
        dateStr: tx['dateStr'] as String? ?? '',
        merchant: tx['merchant'] as String? ?? '',
        amount: (tx['amount'] as num? ?? 0.0).toDouble(),
        categoryValue: tx['categoryValue'] as String? ?? 'expense_other',
        milesCashbackCategoryValue: tx['milesCashbackCategoryValue'] as String? ?? 'Others',
        spendCurrency: tx['spendCurrency'] as String? ?? 'SGD Spend',
      );
    }).toList();

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
