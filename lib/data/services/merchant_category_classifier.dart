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

    // 4. Interest / Savings Interest / Bonus Interest / Interest Earned
    if (lower.contains('interest') ||
        lower.contains('bonus int') ||
        lower.contains('savings int') ||
        lower.contains('co spend bonus') ||
        lower.contains('spend bonus') ||
        lower.contains('int earned') ||
        lower.contains('credit int') ||
        lower == 'int' ||
        lower.startsWith('int ') ||
        lower.endsWith(' int') ||
        lower.contains(' int ') ||
        lower.contains('int cr') ||
        lower.contains('int/cr')) {
      return ClassificationResult(
        expenseCategory: amount > 0 ? 'income_interest' : 'expense_other',
        milesCategory: 'Others',
      );
    }

    // 5. Salary / Payroll / Bonus / CPF
    if (lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('monthly pay') ||
        lower.contains('wages') ||
        lower.contains('annual bonus') ||
        lower.contains('perf bonus') ||
        lower.contains('aws bonus') ||
        lower.contains('cpf board') ||
        lower.contains('cpf contrib') ||
        lower.contains('central prov')) {
      return ClassificationResult(
        expenseCategory: amount > 0 ? 'income_salary' : 'expense_other',
        milesCategory: 'Others',
      );
    }

    // 6. PayNow / FAST Transfer / External Transfer / Fund Transfers / Giro
    if (lower.contains('transfer') ||
        lower.contains('fast') ||
        lower.contains('paynow') ||
        lower.contains('fund transfer') ||
        lower.contains('ibg giro') ||
        lower.contains('giro') ||
        lower.contains('trf') ||
        lower.contains('funds transfer')) {
      if (lower.contains('tutorial') || lower.contains('school') || lower.contains('class') || lower.contains('tuition') || lower.contains('childcare')) {
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

    // 7. Insurance & Protection
    if (lower.contains('aia') ||
        lower.contains('prudential') ||
        lower.contains('great eastern') ||
        lower.contains('aviva') ||
        lower.contains('singlife') ||
        lower.contains('ntuc income') ||
        lower.contains('axa') ||
        lower.contains('fwd') ||
        lower.contains('manulife') ||
        lower.contains('tokio marine') ||
        lower.contains('etiqa') ||
        lower.contains('allianz') ||
        lower.contains('insurance') ||
        lower.contains('assurance') ||
        lower.contains('takaful')) {
      return ClassificationResult(
        expenseCategory: 'expense_insurance',
        milesCategory: 'Others',
      );
    }

    // 8. Healthcare & Medical
    if (lower.contains('raffles medical') ||
        lower.contains('mount elizabeth') ||
        lower.contains('parkway') ||
        lower.contains('gleneagles') ||
        lower.contains('thomson medical') ||
        lower.contains('guardian') ||
        lower.contains('watsons') ||
        lower.contains('unity pharmacy') ||
        lower.contains('polyclinic') ||
        lower.contains('hospital') ||
        lower.contains('clinic') ||
        lower.contains('dental') ||
        lower.contains('dentist') ||
        lower.contains('medical') ||
        lower.contains('healthcare') ||
        lower.contains('pharmacy') ||
        lower.contains('physio') ||
        lower.contains('optom') ||
        lower.contains('optical')) {
      return ClassificationResult(
        expenseCategory: 'expense_healthcare',
        milesCategory: 'Others',
      );
    }

    // 9. Groceries & Supermarkets
    if (lower.contains('fairprice') ||
        lower.contains('ntuc') ||
        lower.contains('sheng siong') ||
        lower.contains('cold storage') ||
        lower.contains('giant') ||
        lower.contains('don don donki') ||
        lower.contains('meidi-ya') ||
        lower.contains('prime super') ||
        lower.contains('supermarket') ||
        lower.contains('redmart') ||
        lower.contains('cs fresh') ||
        lower.contains('little farms') ||
        lower.contains('scoop wholefoods')) {
      return ClassificationResult(
        expenseCategory: 'expense_groceries',
        milesCategory: 'Groceries',
      );
    }

    // 10. Transport / Commute / SimplyGo
    if (lower.contains('simplygo') ||
        (lower.contains('grab') && !lower.contains('food') && !lower.contains('mart')) ||
        lower.contains('gojek') ||
        lower.contains('tada') ||
        lower.contains('comfortdelgro') ||
        lower.contains('smrt') ||
        lower.contains('sbstransit') ||
        lower.contains('transitlink') ||
        lower.contains('lta ') ||
        lower.contains('transit') ||
        lower.contains('zig ') ||
        lower.contains('ryde')) {
      return ClassificationResult(
        expenseCategory: 'expense_transport',
        milesCategory: lower.contains('simplygo') ? 'SimplyGo' : 'Commute',
      );
    }

    // 11. Fuel / Petrol Stations
    if (lower.contains('shell') ||
        lower.contains('esso') ||
        lower.contains('spc') ||
        lower.contains('caltex') ||
        lower.contains('petrol') ||
        lower.contains('sinochem')) {
      return ClassificationResult(
        expenseCategory: 'expense_petrol',
        milesCategory: 'Fuel',
      );
    }

    // 12. Dining & Food Outlets
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
        lower.contains('pizza') ||
        lower.contains('sushi') ||
        lower.contains('ramen') ||
        lower.contains('kopitiam') ||
        lower.contains('koufu') ||
        lower.contains('food republic') ||
        lower.contains('breadtalk') ||
        lower.contains('old chang kee')) {
      return ClassificationResult(
        expenseCategory: 'expense_dining',
        milesCategory: 'Dining & Food Delivery',
      );
    }

    // 13. Utilities & Telco
    if (lower.contains('singtel') ||
        lower.contains('starhub') ||
        lower.contains('m1 ') ||
        lower.contains('sp services') ||
        lower.contains('sp group') ||
        lower.contains('pub ') ||
        lower.contains('electricity') ||
        lower.contains('myrepublic') ||
        lower.contains('circles.life') ||
        lower.contains('giga') ||
        lower.contains('simba') ||
        lower.contains('tuas power') ||
        lower.contains('keppel electric') ||
        lower.contains('senoko')) {
      return ClassificationResult(
        expenseCategory: 'expense_utilities',
        milesCategory: 'Online',
      );
    }

    // 14. Entertainment & Streaming
    if (lower.contains('cinema') ||
        lower.contains('golden village') ||
        lower.contains('cathay') ||
        lower.contains('shaw') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('disney') ||
        lower.contains('youtube') ||
        lower.contains('steam') ||
        lower.contains('playstation') ||
        lower.contains('nintendo') ||
        lower.contains('ticketmaster') ||
        lower.contains('sistic')) {
      return ClassificationResult(
        expenseCategory: 'expense_entertainment',
        milesCategory: 'Entertainment',
      );
    }

    // 15. Travel, Airlines & Hotels
    if (lower.contains('singapore air') ||
        lower.contains('sia ') ||
        lower.contains('scoot') ||
        lower.contains('jetstar') ||
        lower.contains('airasia') ||
        lower.contains('klook') ||
        lower.contains('agoda') ||
        lower.contains('booking.com') ||
        lower.contains('trip.com') ||
        lower.contains('expedia') ||
        lower.contains('hotel') ||
        lower.contains('resort') ||
        lower.contains('airbnb') ||
        lower.contains('changi')) {
      return ClassificationResult(
        expenseCategory: 'expense_travel',
        milesCategory: 'Others',
      );
    }

    // 16. Education & Childcare
    if (lower.contains('tuition') ||
        lower.contains('school') ||
        lower.contains('childcare') ||
        lower.contains('preschool') ||
        lower.contains('enrichment') ||
        lower.contains('student care') ||
        lower.contains('university') ||
        lower.contains('polytechnic') ||
        lower.contains('college') ||
        lower.contains('academy') ||
        lower.contains('kumon') ||
        lower.contains('mindchamps')) {
      return ClassificationResult(
        expenseCategory: 'expense_education',
        milesCategory: 'Others',
      );
    }

    // 17. Shopping & E-commerce
    if (lower.contains('shopee') ||
        lower.contains('lazada') ||
        lower.contains('amazon') ||
        lower.contains('taobao') ||
        lower.contains('uniqlo') ||
        lower.contains('zara') ||
        lower.contains('h&m') ||
        lower.contains('ikea') ||
        lower.contains('decathlon') ||
        lower.contains('sephora') ||
        lower.contains('watsons') ||
        lower.contains('guardian') ||
        lower.contains('department store') ||
        lower.contains('takashimaya') ||
        lower.contains('tang plaza') ||
        lower.contains('isetan')) {
      return ClassificationResult(
        expenseCategory: 'expense_shopping',
        milesCategory: 'Shopping',
      );
    }

    // 18. Fallback to existing or generic
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
