import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
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
    Locale('ja'),
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
  /// **'EV Battery'**
  String get categoryBattery;

  /// No description provided for @categoryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Electric Vehicle'**
  String get categoryVehicle;

  /// No description provided for @categoryAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get categoryAccessory;

  /// No description provided for @categoryAuction.
  ///
  /// In en, this message translates to:
  /// **'Auction'**
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

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJa;

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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAuctions.
  ///
  /// In en, this message translates to:
  /// **'Auctions'**
  String get navAuctions;

  /// No description provided for @navSell.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get navSell;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navProfile;

  /// No description provided for @menuPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get menuPersonalInfo;

  /// No description provided for @menuKyc.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification (eKYC)'**
  String get menuKyc;

  /// No description provided for @menuChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get menuChangePassword;

  /// No description provided for @menuNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get menuNotifications;

  /// No description provided for @menuPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get menuPaymentMethods;

  /// No description provided for @menuMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get menuMyListings;

  /// No description provided for @menuTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get menuTransactions;

  /// No description provided for @menuSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get menuSaved;

  /// No description provided for @menuBidHistory.
  ///
  /// In en, this message translates to:
  /// **'Bid History'**
  String get menuBidHistory;

  /// No description provided for @menuHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get menuHelpCenter;

  /// No description provided for @menuTermsPolicy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Policies'**
  String get menuTermsPolicy;

  /// No description provided for @menuAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get menuAboutApp;

  /// No description provided for @menuLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get menuLogout;

  /// No description provided for @menuLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get menuLogoutConfirm;

  /// No description provided for @menuCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get menuCancel;

  /// No description provided for @menuClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get menuClose;

  /// No description provided for @menuNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get menuNotUpdated;

  /// No description provided for @menuFeatureUpdating.
  ///
  /// In en, this message translates to:
  /// **'This feature is currently being updated.'**
  String get menuFeatureUpdating;

  /// No description provided for @infoFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get infoFullName;

  /// No description provided for @infoEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get infoEmail;

  /// No description provided for @infoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get infoPhone;

  /// No description provided for @infoAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get infoAddress;

  /// No description provided for @sellProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Post Product'**
  String get sellProductTitle;

  /// No description provided for @sellBatteryOption.
  ///
  /// In en, this message translates to:
  /// **'Post Battery'**
  String get sellBatteryOption;

  /// No description provided for @sellVehicleOption.
  ///
  /// In en, this message translates to:
  /// **'Post Vehicle'**
  String get sellVehicleOption;

  /// No description provided for @sellAccessoryOption.
  ///
  /// In en, this message translates to:
  /// **'Post Accessory'**
  String get sellAccessoryOption;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get sectionTransactions;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sectionSupport;

  /// No description provided for @sectionAdmin.
  ///
  /// In en, this message translates to:
  /// **'System Admin'**
  String get sectionAdmin;

  /// No description provided for @statsSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get statsSelling;

  /// No description provided for @statsBought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get statsBought;

  /// No description provided for @statsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get statsSaved;

  /// No description provided for @profileUserDefault.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileUserDefault;

  /// No description provided for @kycStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycStatusApproved;

  /// No description provided for @kycStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get kycStatusPending;

  /// No description provided for @kycStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycStatusRejected;

  /// No description provided for @kycStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get kycStatusUnverified;

  /// No description provided for @adminModeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch to Admin Mode'**
  String get adminModeSwitch;

  /// No description provided for @adminKycApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve User eKYC'**
  String get adminKycApprove;

  /// No description provided for @adminSystemStats.
  ///
  /// In en, this message translates to:
  /// **'System Statistics'**
  String get adminSystemStats;

  /// No description provided for @homeTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get homeTabForYou;

  /// No description provided for @homeTabNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near You'**
  String get homeTabNearYou;

  /// No description provided for @homeTabLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get homeTabLatest;

  /// No description provided for @homeTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get homeTabVideo;

  /// No description provided for @homeNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get homeNoProducts;

  /// No description provided for @errorServerConnection.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get errorServerConnection;

  /// No description provided for @btnRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get btnRetry;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchPlaceholder;

  /// No description provided for @homeSellBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to sell a product?'**
  String get homeSellBannerTitle;

  /// No description provided for @homeSellBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Easily list your batteries, EVs, or accessories with AI support!'**
  String get homeSellBannerSubtitle;

  /// No description provided for @btnPostSell.
  ///
  /// In en, this message translates to:
  /// **'Post Sell'**
  String get btnPostSell;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTitle;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessages;

  /// No description provided for @chatContactSellerToStart.
  ///
  /// In en, this message translates to:
  /// **'Contact a seller to start\na conversation'**
  String get chatContactSellerToStart;

  /// No description provided for @chatBtnViewListings.
  ///
  /// In en, this message translates to:
  /// **'View Listings'**
  String get chatBtnViewListings;

  /// No description provided for @chatNoMessageSnippet.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get chatNoMessageSnippet;

  /// No description provided for @auctionTabOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get auctionTabOngoing;

  /// No description provided for @auctionTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get auctionTabUpcoming;

  /// No description provided for @auctionTabEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get auctionTabEnded;

  /// No description provided for @auctionNoOngoing.
  ///
  /// In en, this message translates to:
  /// **'No ongoing auctions'**
  String get auctionNoOngoing;

  /// No description provided for @auctionNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming auctions'**
  String get auctionNoUpcoming;

  /// No description provided for @auctionNoEnded.
  ///
  /// In en, this message translates to:
  /// **'No ended auctions'**
  String get auctionNoEnded;

  /// No description provided for @btnCreateAuction.
  ///
  /// In en, this message translates to:
  /// **'Create Auction'**
  String get btnCreateAuction;

  /// No description provided for @auctionCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get auctionCurrentPrice;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @auctionBidCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bids'**
  String auctionBidCount(int count);
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
      <String>['en', 'ja', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
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
