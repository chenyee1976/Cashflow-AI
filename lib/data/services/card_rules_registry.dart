import 'package:flutter/foundation.dart';

enum RoundingMethod {
  nearest,       // round raw reward to nearest whole number
  floor,         // floor raw reward to nearest whole number
  ceil,          // ceil raw reward to nearest whole number
  keepDecimal,   // keep decimals (e.g. 2 decimal places for cashback)
}

class CardCalculationRule {
  final bool floorSpendToDollar;
  final double spendBlock;        // e.g. 5.0 for UOB's $5 blocks, 1.0 for standard
  final RoundingMethod roundingMethod;
  final double defaultLocalRate;  // default rate (miles per S$1 or cashback %)
  final double defaultForeignRate;
  final List<Map<String, dynamic>> defaultRatesList;

  const CardCalculationRule({
    this.floorSpendToDollar = false,
    this.spendBlock = 1.0,
    this.roundingMethod = RoundingMethod.keepDecimal,
    this.defaultLocalRate = 0.0,
    this.defaultForeignRate = 0.0,
    this.defaultRatesList = const [],
  });
}

class CardRulesRegistry {
  // Static registry containing 35 miles cards and 24 cashback cards
  static final Map<String, CardCalculationRule> registry = {
    // ==========================================
    // MILES CREDIT CARDS (35 Cards)
    // ==========================================
    
    // DBS Bank
    'dbs_altitude_visa_signature_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.2'},
      ],
    ),
    'dbs_altitude_american_express_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.2'},
      ],
    ),
    'dbs_yuu_visa_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.0,
      defaultForeignRate: 1.0,
      defaultRatesList: [
        {'category': 'Base Reward', 'rate': '1.0', 'minSpend': '', 'maxSpend': ''},
        {'category': 'Bonus Reward 1', 'rate': '9.0', 'minSpend': '', 'maxSpend': ''},
        {'category': 'Bonus Reward 2 with minimum spend of S\$800', 'rate': '26.0', 'minSpend': '800', 'maxSpend': ''},
      ],
    ),
    'dbs_yuu_american_express_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.0,
      defaultForeignRate: 1.0,
      defaultRatesList: [
        {'category': 'Base Reward', 'rate': '1.0', 'minSpend': '', 'maxSpend': ''},
        {'category': 'Bonus Reward 1', 'rate': '9.0', 'minSpend': '', 'maxSpend': ''},
        {'category': 'Bonus Reward 2 with minimum spend of S\$800', 'rate': '26.0', 'minSpend': '800', 'maxSpend': ''},
      ],
    ),
    'dbs_woman’s_mastercard_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0, // DBS women's card uses $5 block for calculation
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.2,
      defaultForeignRate: 1.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
      ],
    ),
    'dbs_woman’s_world_mastercard_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0, // $5 blocks
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0, // 4.0 miles per $1 on online spend
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'dbs_vantage_visa_infinite_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.6,
      defaultForeignRate: 2.4,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.6'},
        {'category': 'FCY spend', 'rate': '2.4'},
      ],
    ),

    // OCBC Bank
    'ocbc_rewards_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0, // OCBC uses $5 blocks for point calculations
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0, // 4 miles / S$1 online/retail
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'ocbc_90n_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.1,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY Spend', 'rate': '2.1'},
      ],
    ),
    'ocbc_90_n_visa_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.1,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY Spend', 'rate': '2.1'},
      ],
    ),
    'ocbc_90_n_mastercard_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.1,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY Spend', 'rate': '2.1'},
      ],
    ),
    'ocbc_90°n_mastercard_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.1,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY Spend', 'rate': '2.1'},
      ],
    ),
    'ocbc_90°n_visa_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.1,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY Spend', 'rate': '2.1'},
      ],
    ),
    'ocbc_voyage_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY spend', 'rate': '2.2'},
      ],
    ),

    // United Overseas Bank (UOB)
    'uob_prvi_miles_card_visa': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0, // UOB uses $5 blocks
      roundingMethod: RoundingMethod.keepDecimal, // UOB rewards UNI$ with decimal precision
      defaultLocalRate: 1.4,
      defaultForeignRate: 2.4,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.4'},
        {'category': 'FCY spend', 'rate': '2.4'},
      ],
    ),
    'uob_prvi_miles_card_mastercard': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.4,
      defaultForeignRate: 2.4,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.4'},
        {'category': 'FCY spend', 'rate': '2.4'},
      ],
    ),
    'uob_prvi_miles_card_american_express': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.4,
      defaultForeignRate: 2.4,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.4'},
        {'category': 'FCY spend', 'rate': '2.4'},
      ],
    ),
    'uob_lady’s_credit_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0, // 4 mpd on selected categories
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'uob_lady’s_solitaire_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0,
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'krisflyer_uob_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 3.0, // up to 3mpd
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '3.0'},
      ],
    ),
    'uob_preferred_visa_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0, // 4 mpd on mobile contactless
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'uob_visa_signature_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 5.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0,
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),

    // Standard Chartered
    'sc_visa_infinite_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.0, // default placeholder
      defaultForeignRate: 1.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.0'},
      ],
    ),
    'sc_journey_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.0'},
      ],
    ),
    'sc_beyond_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.0,
      defaultForeignRate: 1.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.0'},
      ],
    ),

    // Citibank Singapore
    'citi_premiermiles_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY Spend', 'rate': '2.2'},
      ],
    ),
    'citi_premiermiles_world_select_mastercard': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY Spend', 'rate': '2.2'},
      ],
    ),
    'citi_rewards_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0,
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'citi_prestige_card': const CardCalculationRule(
      floorSpendToDollar: true,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.3,
      defaultForeignRate: 2.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.3'},
        {'category': 'FCY spend', 'rate': '2.0'},
      ],
    ),

    // HSBC Singapore
    'hsbc_premier_mastercard': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.0'},
      ],
    ),
    'hsbc_revolution_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.floor,
      defaultLocalRate: 4.0, // 4mpd online/contactless
      defaultForeignRate: 4.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '4.0'},
      ],
    ),
    'hsbc_travelone_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.4,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.4'},
      ],
    ),
    'hsbc_visa_infinite_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.25,
      defaultForeignRate: 2.25,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.25'},
        {'category': 'FCY spend', 'rate': '2.25'},
      ],
    ),

    // Maybank Singapore
    'maybank_xl_rewards_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.0,
      defaultForeignRate: 1.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.0'},
      ],
    ),
    'maybank_horizon_visa_signature_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.8,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.8'},
      ],
    ),
    'maybank_world_mastercard': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.6,
      defaultForeignRate: 1.6,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.6'},
      ],
    ),
    'maybank_visa_infinite_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultForeignRate: 2.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
        {'category': 'FCY spend', 'rate': '2.0'},
      ],
    ),

    // AMEX Singapore
    'the_american_express_singapore_airlines_krisflyer_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.1,
      defaultForeignRate: 2.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.1'},
        {'category': 'FCY spend', 'rate': '2.0'},
      ],
    ),

    // Bank of China Singapore
    'boc_elite_miles_world_mastercard': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.0,
      defaultForeignRate: 2.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.0'},
        {'category': 'FCY spend', 'rate': '2.0'},
      ],
    ),

    // ==========================================
    // CASHBACK CREDIT CARDS (24 Cards)
    // ==========================================

    // DBS Bank
    'posb_everyday_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 0.3, // 0.3% base rebate
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '0.3'},
      ],
    ),
    'dbs_live_fresh_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 5.0, // 5% shopping/contactless
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '5.0'},
      ],
    ),

    // OCBC Bank
    'ocbc_infinity_cardback_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.6, // 1.6% cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.6'},
      ],
    ),
    'ocbc_365_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 5.0, // 5% dining/groceries
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '5.0'},
      ],
    ),
    'ocbc_frank_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 8.0, // 8% online
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '8.0'},
      ],
    ),

    // United Overseas Bank (UOB)
    'uob_one_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 3.33, // 3.33% up to 10%
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '3.33'},
      ],
    ),
    'uob_absolute_cashback_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.7, // 1.7% cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.7'},
      ],
    ),
    'uob_evol_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 8.0, // 8% online/mobile
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '8.0'},
      ],
    ),

    // Standard Chartered
    'sc_simply_cash_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.5, // 1.5% cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.5'},
      ],
    ),
    'sc_smart_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 5.6, // 5.6% cashback on fast food / streaming
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '5.6'},
      ],
    ),

    // Citibank Singapore
    'citi_cash_back_+_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.6, // 1.6% cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.6'},
      ],
    ),
    'citi_cash_back_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 8.0, // 8% dining/groceries
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '8.0'},
      ],
    ),
    'citi_smrt_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 5.0, // 5% online/groceries/transit
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '5.0'},
      ],
    ),

    // HSBC Singapore
    'hsbc_live+_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 8.0, // 8% dining/shopping
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '8.0'},
      ],
    ),
    'hsbc_advance_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.5,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.5'},
      ],
    ),

    // Maybank Singapore
    'maybank_xl_cashbank_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.0'},
      ],
    ),
    'maybank_family_&_friends_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 8.0, // 8% cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '8.0'},
      ],
    ),
    'maybank_platinum_visa_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 3.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '3.2'},
      ],
    ),

    // AMEX Singapore
    'the_american_express_true_cashback_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.5, // 1.5% cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.5'},
      ],
    ),

    // Trust Singapore
    'trust_link_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 0.5,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '0.5'},
      ],
    ),
    'ntuc_link_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 0.5,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '0.5'},
      ],
    ),
    'trust_cashback_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.5,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.5'},
      ],
    ),

    // Bank of China Singapore
    'boc_family_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 3.0,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '3.0'},
      ],
    ),

    // Maribank Singapore
    'mari_credit_card': const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.keepDecimal,
      defaultLocalRate: 1.5, // 1.5% unlimited cashback
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.5'},
      ],
    ),
  };

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static CardCalculationRule getRule(String bankName, String cardName) {
    // Attempt exact matching first
    final key1 = _normalize('${bankName}_$cardName');
    final key2 = _normalize(cardName);
    
    CardCalculationRule? match = registry[key1] ?? registry[key2];
    if (match != null) return match;

    // Check fuzzy containing
    for (final entry in registry.entries) {
      if (key1.contains(entry.key) || entry.key.contains(key2)) {
        return entry.value;
      }
    }

    // Default fallback
    return const CardCalculationRule(
      floorSpendToDollar: false,
      spendBlock: 1.0,
      roundingMethod: RoundingMethod.nearest,
      defaultLocalRate: 1.2,
      defaultRatesList: [
        {'category': 'SGD Spend', 'rate': '1.2'},
      ],
    );
  }
}
