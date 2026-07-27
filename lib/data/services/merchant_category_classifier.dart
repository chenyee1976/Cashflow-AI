import 'user_category_rules_service.dart';

class ClassificationResult {
  final String expenseCategory;
  final String milesCategory;

  ClassificationResult({
    required this.expenseCategory,
    required this.milesCategory,
  });
}

class MerchantCategoryClassifier {
  /// Classify a merchant description using user learned rules + built-in rules
  static Future<ClassificationResult> classify({
    required String merchant,
    required double amount,
    String? currentExpenseCategory,
    String? currentMilesCategory,
    UserCategoryRulesService? rulesService,
  }) async {
    // 1. Check User Learned Rules first (highest priority!)
    if (rulesService != null) {
      final learned = await rulesService.matchRule(merchant);
      if (learned != null) {
        return ClassificationResult(
          expenseCategory: learned.expenseCategory,
          milesCategory: learned.milesCategory,
        );
      }
    }

    final lower = merchant.toLowerCase();

    // 2. ATM Cash Withdrawals & Transfers to Cash
    if (lower.contains('atm') ||
        lower.contains('cash w/drawal') ||
        lower.contains('cash withdrawal') ||
        lower.contains('cash wdr') ||
        lower.contains('cash atm')) {
      return ClassificationResult(
        expenseCategory: 'expense_transfer_to_cash',
        milesCategory: 'Others',
      );
    }

    // 3. Tax / IRAS / Government / Ministry of Manpower
    if (lower.contains('iras') ||
        lower.contains('etax') ||
        lower.contains('inland reven') ||
        lower.contains('manpower') ||
        lower.contains('mom') ||
        lower.contains('property tax') ||
        lower.contains('income tax') ||
        lower.contains('customs')) {
      return ClassificationResult(
        expenseCategory: 'expense_tax',
        milesCategory: 'Others',
      );
    }

    // 4. Interest / Savings Interest / Bonus Interest
    if (lower.contains('interest') ||
        lower.contains('bonus int') ||
        lower.contains('savings int') ||
        lower.contains('co spend bonus') ||
        lower.contains('spend bonus')) {
      return ClassificationResult(
        expenseCategory: amount > 0 ? 'income_other' : 'expense_other',
        milesCategory: 'Others',
      );
    }

    // 5. PayNow / FAST / Fund Transfers
    if (lower.contains('paynow') ||
        lower.contains('fast payment') ||
        lower.contains('fund transfer') ||
        lower.contains('payment w/transfer') ||
        lower.contains('ibg giro') ||
        lower.contains('giro deduction') ||
        lower.contains('trf')) {
      if (lower.contains('tutorial') || lower.contains('school') || lower.contains('class') || lower.contains('tuition')) {
        return ClassificationResult(
          expenseCategory: 'expense_education',
          milesCategory: 'Others',
        );
      }
      if (amount > 0) {
        return ClassificationResult(
          expenseCategory: 'income_transfer',
          milesCategory: 'Others',
        );
      } else {
        return ClassificationResult(
          expenseCategory: 'expense_transfer',
          milesCategory: 'Others',
        );
      }
    }

    // 6. Groceries & Supermarkets
    if (lower.contains('fairprice') ||
        lower.contains('ntuc') ||
        lower.contains('sheng siong') ||
        lower.contains('cold storage') ||
        lower.contains('giant') ||
        lower.contains('don don donki') ||
        lower.contains('meidi-ya') ||
        lower.contains('prime super') ||
        lower.contains('supermarket')) {
      return ClassificationResult(
        expenseCategory: 'expense_groceries',
        milesCategory: 'Groceries',
      );
    }

    // 7. Transport / Commute / SimplyGo
    if (lower.contains('simplygo') ||
        lower.contains('grab') && !lower.contains('food') ||
        lower.contains('gojek') ||
        lower.contains('tada') ||
        lower.contains('comfortdelgro') ||
        lower.contains('smrt') ||
        lower.contains('sbstransit') ||
        lower.contains('transit')) {
      return ClassificationResult(
        expenseCategory: 'expense_transport',
        milesCategory: lower.contains('simplygo') ? 'SimplyGo' : 'Commute',
      );
    }

    // 8. Dining & Food Outlets
    if (lower.contains('foodpanda') ||
        lower.contains('deliveroo') ||
        lower.contains('grabfood') ||
        lower.contains('mcdonald') ||
        lower.contains('kfc') ||
        lower.contains('subway') ||
        lower.contains('starbucks') ||
        lower.contains('toast box') ||
        lower.contains('ya kun') ||
        lower.contains('din tai fung') ||
        lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('bistro') ||
        lower.contains('bakery') ||
        lower.contains('pizza')) {
      return ClassificationResult(
        expenseCategory: 'expense_dining',
        milesCategory: 'Dining & Food Delivery',
      );
    }

    // 9. Utilities & Telco
    if (lower.contains('singtel') ||
        lower.contains('starhub') ||
        lower.contains('m1') ||
        lower.contains('sp services') ||
        lower.contains('pub') ||
        lower.contains('electricity') ||
        lower.contains('myrepublic') ||
        lower.contains('circles.life')) {
      return ClassificationResult(
        expenseCategory: 'expense_utilities',
        milesCategory: 'Online',
      );
    }

    // 10. Fuel / Gas stations
    if (lower.contains('shell') ||
        lower.contains('esso') ||
        lower.contains('spc') ||
        lower.contains('caltex') ||
        lower.contains('petrol')) {
      return ClassificationResult(
        expenseCategory: 'expense_transport',
        milesCategory: 'Fuel',
      );
    }

    // 11. Shopping & E-commerce
    if (lower.contains('shopee') ||
        lower.contains('lazada') ||
        lower.contains('amazon') ||
        lower.contains('taobao') ||
        lower.contains('uniqlo') ||
        lower.contains('zara') ||
        lower.contains('h&m')) {
      return ClassificationResult(
        expenseCategory: 'expense_shopping',
        milesCategory: 'Online',
      );
    }

    // 12. Fallback to existing or generic
    String expCat = currentExpenseCategory ?? (amount > 0 ? 'income_other' : 'expense_other');
    if (expCat == 'expense_other' && amount > 0) {
      expCat = 'income_other';
    } else if (expCat == 'income_other' && amount < 0) {
      expCat = 'expense_other';
    }

    return ClassificationResult(
      expenseCategory: expCat,
      milesCategory: currentMilesCategory ?? 'Others',
    );
  }
}
