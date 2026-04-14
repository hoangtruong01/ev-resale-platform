import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EVN Market'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to EVN Market'**
  String get welcome;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent, inspected EV battery marketplace'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EV batteries, used EVs, and accessories with clear condition and trusted pricing.'**
  String get heroSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search batteries, EVs, accessories...'**
  String get searchHint;

  /// No description provided for @ctaExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore listings'**
  String get ctaExplore;

  /// No description provided for @ctaVehicles.
  ///
  /// In en, this message translates to:
  /// **'Browse vehicles'**
  String get ctaVehicles;

  /// No description provided for @ctaAuctions.
  ///
  /// In en, this message translates to:
  /// **'Join auctions'**
  String get ctaAuctions;

  /// No description provided for @ctaSell.
  ///
  /// In en, this message translates to:
  /// **'Sell now'**
  String get ctaSell;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key stats'**
  String get statsTitle;

  /// No description provided for @statBatteries.
  ///
  /// In en, this message translates to:
  /// **'Batteries listed'**
  String get statBatteries;

  /// No description provided for @statVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles listed'**
  String get statVehicles;

  /// No description provided for @statTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get statTransactions;

  /// No description provided for @statUsers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get statUsers;

  /// No description provided for @statProvinces.
  ///
  /// In en, this message translates to:
  /// **'Provinces'**
  String get statProvinces;

  /// No description provided for @statProvincesValue.
  ///
  /// In en, this message translates to:
  /// **'63'**
  String get statProvincesValue;

  /// No description provided for @whyChoose.
  ///
  /// In en, this message translates to:
  /// **'Why EVN Market'**
  String get whyChoose;

  /// No description provided for @featureInspection.
  ///
  /// In en, this message translates to:
  /// **'Verified inspection'**
  String get featureInspection;

  /// No description provided for @featureInspectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear status reports and verified listings.'**
  String get featureInspectionDesc;

  /// No description provided for @featureAi.
  ///
  /// In en, this message translates to:
  /// **'AI pricing'**
  String get featureAi;

  /// No description provided for @featureAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick market-based pricing suggestions.'**
  String get featureAiDesc;

  /// No description provided for @featureAuction.
  ///
  /// In en, this message translates to:
  /// **'Online auctions'**
  String get featureAuction;

  /// No description provided for @featureAuctionDesc.
  ///
  /// In en, this message translates to:
  /// **'Competitive and real-time bidding.'**
  String get featureAuctionDesc;

  /// No description provided for @featureWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty support'**
  String get featureWarranty;

  /// No description provided for @featureWarrantyDesc.
  ///
  /// In en, this message translates to:
  /// **'Transparent policies and post-sale support.'**
  String get featureWarrantyDesc;

  /// No description provided for @featureDelivery.
  ///
  /// In en, this message translates to:
  /// **'Nationwide delivery'**
  String get featureDelivery;

  /// No description provided for @featureDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Secure delivery with tracking updates.'**
  String get featureDeliveryDesc;

  /// No description provided for @featureCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition matching'**
  String get featureCondition;

  /// No description provided for @featureConditionDesc.
  ///
  /// In en, this message translates to:
  /// **'Compatibility and condition details upfront.'**
  String get featureConditionDesc;

  /// No description provided for @processTitle.
  ///
  /// In en, this message translates to:
  /// **'Trading process'**
  String get processTitle;

  /// No description provided for @processStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get processStep1Title;

  /// No description provided for @processStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Create an account in minutes.'**
  String get processStep1Desc;

  /// No description provided for @processStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Verify listing'**
  String get processStep2Title;

  /// No description provided for @processStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Inspection and listing approval.'**
  String get processStep2Desc;

  /// No description provided for @processStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Choose or bid'**
  String get processStep3Title;

  /// No description provided for @processStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Buy now or join transparent auctions.'**
  String get processStep3Desc;

  /// No description provided for @processStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Delivery & warranty'**
  String get processStep4Title;

  /// No description provided for @processStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Safe payment and support after purchase.'**
  String get processStep4Desc;

  /// No description provided for @featuredBatteries.
  ///
  /// In en, this message translates to:
  /// **'Verified EV batteries'**
  String get featuredBatteries;

  /// No description provided for @featuredVehicles.
  ///
  /// In en, this message translates to:
  /// **'Used EVs for you'**
  String get featuredVehicles;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @bannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection and warranty'**
  String get bannerTitle;

  /// No description provided for @bannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear condition reports and secure transactions.'**
  String get bannerSubtitle;

  /// No description provided for @footerProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get footerProducts;

  /// No description provided for @footerSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get footerSupport;

  /// No description provided for @footerRights.
  ///
  /// In en, this message translates to:
  /// **'© 2026 EVN Market. All rights reserved.'**
  String get footerRights;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get updating;

  /// No description provided for @categoryBattery.
  ///
  /// In en, this message translates to:
  /// **'Batteries'**
  String get categoryBattery;

  /// No description provided for @categoryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get categoryVehicle;

  /// No description provided for @categoryAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get categoryAccessory;

  /// No description provided for @categoryAuction.
  ///
  /// In en, this message translates to:
  /// **'Auctions'**
  String get categoryAuction;

  /// No description provided for @categoryInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get categoryInspection;

  /// No description provided for @categoryNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get categoryNearby;

  /// No description provided for @categoryChat.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get categoryChat;

  /// No description provided for @sellTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellTitle;

  /// No description provided for @sellBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell battery'**
  String get sellBatteryTitle;

  /// No description provided for @sellBatterySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lithium, NiMH, ...'**
  String get sellBatterySubtitle;

  /// No description provided for @sellVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell vehicle'**
  String get sellVehicleTitle;

  /// No description provided for @sellVehicleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'E-bike, e-scooter, EV car'**
  String get sellVehicleSubtitle;

  /// No description provided for @sellAccessoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell accessory'**
  String get sellAccessoryTitle;

  /// No description provided for @sellAccessorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chargers, tires, electronics'**
  String get sellAccessorySubtitle;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @badgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get badgeVerified;

  /// No description provided for @badgeWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get badgeWarranty;

  /// No description provided for @badgeTransparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get badgeTransparent;

  /// No description provided for @badgeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get badgeAvailable;

  /// No description provided for @badgeSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get badgeSold;

  /// No description provided for @badgeAuction.
  ///
  /// In en, this message translates to:
  /// **'Auction'**
  String get badgeAuction;

  /// No description provided for @badgeReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get badgeReserved;

  /// No description provided for @trustInspected.
  ///
  /// In en, this message translates to:
  /// **'Inspected'**
  String get trustInspected;

  /// No description provided for @trustWarranty.
  ///
  /// In en, this message translates to:
  /// **'Clear warranty'**
  String get trustWarranty;

  /// No description provided for @trustDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery support'**
  String get trustDelivery;

  /// No description provided for @trustAiPricing.
  ///
  /// In en, this message translates to:
  /// **'AI pricing'**
  String get trustAiPricing;

  /// No description provided for @heroCardBattery.
  ///
  /// In en, this message translates to:
  /// **'EV Batteries'**
  String get heroCardBattery;

  /// No description provided for @heroCardBatteryDesc.
  ///
  /// In en, this message translates to:
  /// **'SOH, capacity, cycles'**
  String get heroCardBatteryDesc;

  /// No description provided for @heroCardVehicle.
  ///
  /// In en, this message translates to:
  /// **'Used EVs'**
  String get heroCardVehicle;

  /// No description provided for @heroCardVehicleDesc.
  ///
  /// In en, this message translates to:
  /// **'Mileage, warranty, condition'**
  String get heroCardVehicleDesc;

  /// No description provided for @finalCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore inspected EV batteries and used EVs'**
  String get finalCtaTitle;

  /// No description provided for @finalCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent condition, trusted pricing, nationwide delivery.'**
  String get finalCtaSubtitle;

  /// No description provided for @finalCtaPrimary.
  ///
  /// In en, this message translates to:
  /// **'View listings'**
  String get finalCtaPrimary;

  /// No description provided for @finalCtaSecondary.
  ///
  /// In en, this message translates to:
  /// **'Sell for free'**
  String get finalCtaSecondary;

  /// No description provided for @errorLoad.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorLoad(Object message);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageVi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVi;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
