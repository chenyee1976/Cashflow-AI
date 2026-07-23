enum TransactionCategory {
  incomeSalary('income_salary', 'Salary', true),
  incomeTransfer('income_transfer', 'Transfer In', true),
  incomeInterest('income_interest', 'Interest', true),
  incomeInvestments('income_investments', 'Investments', true),
  incomeDividends('income_dividends', 'Dividends', true),
  incomeOther('income_other', 'Other Income', true),
  expenseTransferToCash('expense_transfer_to_cash', 'Transfer to Cash on hand', false),
  expenseTransfer('expense_transfer', 'Transfer Out', false),
  expenseGroceries('expense_groceries', 'Groceries', false),
  expenseDining('expense_dining', 'Dining', false),
  expenseTransport('expense_transport', 'Transport', false),
  expensePetrol('expense_petrol', 'Petrol', false),
  expenseUtilities('expense_utilities', 'Utilities', false),
  expenseShopping('expense_shopping', 'Shopping', false),
  expenseTravel('expense_travel', 'Travel', false),
  expenseInsurance('expense_insurance', 'Insurance', false),
  expenseInvestments('expense_investments', 'Investments', false),
  expenseEntertainment('expense_entertainment', 'Entertainment', false),
  expenseHealthcare('expense_healthcare', 'Healthcare', false),
  expenseEducation('expense_education', 'Education', false),
  expenseTax('expense_tax', 'Tax', false),
  expenseOther('expense_other', 'Other Expense', false);

  const TransactionCategory(this.value, this.displayName, this.isIncome);

  final String value;
  final String displayName;
  final bool isIncome;

  bool get isExpense => !isIncome;

  static TransactionCategory fromValue(String value) {
    return TransactionCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionCategory.expenseOther,
    );
  }

  static List<TransactionCategory> get incomeCategories =>
      TransactionCategory.values.where((c) => c.isIncome).toList();

  static List<TransactionCategory> get expenseCategories =>
      TransactionCategory.values.where((c) => c.isExpense).toList();
}
