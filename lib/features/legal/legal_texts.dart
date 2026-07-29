class LegalTexts {
  static const String appName = 'SG CashFlow AI';
  static const String dpoEmail = 'sgcashflowai@gmail.com';
  static const String lastUpdated = 'July 2026';

  static const String termsOfService = '''
# SG CASHFLOW AI — TERMS OF SERVICE
*Last Updated: July 2026*

## 1. ACCEPTANCE OF TERMS
By downloading, accessing, or using SG CashFlow AI ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not access or use the App.

## 2. SERVICE OVERVIEW & READ-ONLY FINANCIAL TRACKING
SG CashFlow AI is a personal treasury and cashflow tracking application. 
* **Read-Only Analytical Tool**: The App is strictly an analytical record-keeping and forecasting tool. SG CashFlow AI cannot move funds, execute transfers, or directly execute bank transactions on your behalf.
* **No Professional Financial Advice**: Analytics, AI extraction outputs, and budget insights are provided for personal informational purposes only and do not constitute professional financial, tax, or investment advice.

## 3. MEMBERSHIP TIERS & SUBSCRIPTIONS (ESSENTIAL, PRO, ELITE)
SG CashFlow AI offers multiple service tiers:
* **Essential (Free) Tier**: Basic cashflow tracking, standard manual logging, and limited monthly document extractions supported by in-app advertisements.
* **Pro Membership**: Unlocks higher document parsing limits, advanced analytics, priority AI processing, and an ad-free experience.
* **Elite Membership**: Unlocks maximum AI document parsing capacity, multi-currency treasury insights, custom financial export tools, premium support, and exclusive partner perks.
* **Billing & Auto-Renewal**: Subscriptions are billed through Apple App Store or Google Play Store In-App Purchases. Subscriptions automatically renew unless cancelled at least 24 hours prior to the end of the current billing cycle in your app store account settings.

## 4. AI PROCESSING & APP-PROVIDED GEMINI API KEY
* SG CashFlow AI utilizes generative AI technology (Google Gemini API) powered by the App’s central API key infrastructure to process user-uploaded bank and credit card statements into structured transactions.
* **Fair Usage Quotas**: Use of the app-provided Gemini API key is subject to fair usage limits aligned with your active membership tier. Reverse engineering or attempting to extract the API key is strictly prohibited.

## 5. USER ACCOUNTS & GOOGLE SIGN-IN
Authentication may be conducted via Google Sign-In. You are responsible for safeguarding your credentials and all activity under your account.

## 6. ADVERTISING (GOOGLE ADMOB) & FINANCIAL AFFILIATE NETWORKS
* **Advertising**: Free/supported tiers display third-party ads served via Google AdMob.
* **Financial Affiliate Links**: The App may display product recommendations (e.g., credit cards, bank accounts). SG CashFlow AI may receive referral compensation if you apply through these affiliate links. Financial products are governed by the respective third-party institution's terms.

## 7. LIMITATION OF LIABILITY & INDEMNIFICATION
To the maximum extent permitted by law, SG CashFlow AI shall not be liable for any financial inaccuracies, missed payments, AI parsing errors, or third-party service interruptions.

## 8. GOVERNING LAW & SINGAPORE JURISDICTION
These Terms are governed by and construed in accordance with the laws of the Republic of Singapore. Any disputes arising under these Terms shall be submitted to the exclusive jurisdiction of the courts of Singapore.
''';

  static const String privacyPolicy = '''
# SG CASHFLOW AI — PRIVACY POLICY
*(Compliant with Singapore PDPA / PDPC Guidelines & Global App Store Policies)*
*Last Updated: July 2026*

## 1. DATA WE COLLECT
* **Account Information**: Name, Email Address, and Profile Picture via Google Sign-In.
* **Financial & Document Data**: Bank/card statement images, PDFs, and manual transaction logs. Core databases remain stored locally on your device via encrypted SQLite storage.
* **AdMob Advertising Identifiers**: Device Ad IDs (IDFA/GAID) and IP addresses collected by Google AdMob.
* **Affiliate Interaction Tokens**: Anonymous click tracking for financial partner links.
* **Diagnostic & AI Telemetry**: Feature usage logs and error stack traces (only if "Allow AI Analytics & Logs" is enabled).

## 2. PURPOSE OF COLLECTION & USE (SINGAPORE PDPA COMPLIANCE)
In accordance with the Singapore Personal Data Protection Act (PDPA), we collect and process personal data for:
* Authenticating users and managing Essential, Pro, or Elite Membership subscriptions.
* Performing OCR and statement transaction extraction via Google Gemini API.
* Serving advertisements via Google AdMob.
* Tailoring financial affiliate product recommendations.
* Diagnosing software crashes and technical errors.

## 3. THIRD-PARTY SERVICE PROVIDERS & CROSS-BORDER DATA TRANSFERS
We do NOT sell your personal financial data. We share necessary data only with trusted providers:
* **Google Services**: Google Sign-In (Auth), Google Gemini API (Transient AI document extraction), Google AdMob (Advertising).
* **Vercel Telemetry**: Central logging endpoint for optional bug reports.
* **Cross-Border Transfer Obligation**: Where data is transferred or processed outside Singapore (e.g., Google cloud infrastructure), we ensure third-party recipients provide a standard of data protection comparable to the Singapore PDPA.

## 4. DATA RETENTION & ERASURE
Personal data is retained only for as long as necessary to fulfill the purposes set out in this policy. Uninstalling the app or clearing local data purges your device database. Requesting account deletion purges remote log records.

## 5. USER RIGHTS & CONSENT WITHDRAWAL (SINGAPORE PDPA)
Under Singapore PDPA, you have the right to:
* **Withdraw Consent**: Turn off "Allow AI Analytics & Logs" at any time in Account Settings.
* **Access & Correction**: Request access to or correction of your personal data held by us.
* **Account Deletion**: Request complete erasure of your user profile and remote telemetry data.

## 6. CONTACT OUR DATA PROTECTION OFFICER (DPO)
For privacy inquiries, PDPA rights requests, or feedback, contact our designated Data Protection Officer:
**Email**: sgcashflowai@gmail.com
''';
}
