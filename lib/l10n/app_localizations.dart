import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HitScore'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginErrorGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get loginErrorGoogle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get errorGeneric;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network issue. Please check your connection.'**
  String get networkError;

  /// No description provided for @setupProfile.
  ///
  /// In en, this message translates to:
  /// **'Setup Profile'**
  String get setupProfile;

  /// No description provided for @setupProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'No profile found. Please complete your profile.'**
  String get setupProfileDescription;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required'**
  String get genderRequired;

  /// No description provided for @birthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDateLabel;

  /// No description provided for @birthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Birth date is required'**
  String get birthDateRequired;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @clubLabel.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get clubLabel;

  /// No description provided for @profileId.
  ///
  /// In en, this message translates to:
  /// **'Profile ID'**
  String get profileId;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @addressSimple.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressSimple;

  /// No description provided for @phoneNumberSimple.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneNumberSimple;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @clubIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Club ID'**
  String get clubIdLabel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDate;

  /// No description provided for @dateNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get dateNotSelected;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @clubInfo.
  ///
  /// In en, this message translates to:
  /// **'Club Information'**
  String get clubInfo;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectClub.
  ///
  /// In en, this message translates to:
  /// **'Select Club'**
  String get selectClub;

  /// No description provided for @allCountries.
  ///
  /// In en, this message translates to:
  /// **'All Countries'**
  String get allCountries;

  /// No description provided for @allCities.
  ///
  /// In en, this message translates to:
  /// **'All Cities'**
  String get allCities;

  /// No description provided for @individualClub.
  ///
  /// In en, this message translates to:
  /// **'Individual (No Club)'**
  String get individualClub;

  /// No description provided for @removeClub.
  ///
  /// In en, this message translates to:
  /// **'Remove Club'**
  String get removeClub;

  /// No description provided for @roleChangeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Role can\'t be changed after setup'**
  String get roleChangeNotAllowed;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @emailVerificationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verification required'**
  String get emailVerificationRequiredTitle;

  /// No description provided for @emailVerificationLoginContent.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before logging in.'**
  String get emailVerificationLoginContent;

  /// No description provided for @emailVerificationRequiredOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get emailVerificationRequiredOk;

  /// No description provided for @loginSuccessRedirectingShort.
  ///
  /// In en, this message translates to:
  /// **'Login successful. Redirecting...'**
  String get loginSuccessRedirectingShort;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get loginErrorGeneric;

  /// No description provided for @welcomeWithName.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcomeWithName(String name);

  /// No description provided for @createCompetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Competition'**
  String get createCompetitionTitle;

  /// No description provided for @competitionGeneralInfo.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get competitionGeneralInfo;

  /// No description provided for @competitionGeneralInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill in the competition details below.'**
  String get competitionGeneralInfoDesc;

  /// No description provided for @competitionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition name'**
  String get competitionNameLabel;

  /// No description provided for @competitionDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get competitionDescriptionLabel;

  /// No description provided for @competitionDuration.
  ///
  /// In en, this message translates to:
  /// **'Competition Duration'**
  String get competitionDuration;

  /// No description provided for @competitionDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'Select start and end date/time.'**
  String get competitionDurationDesc;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @competitionDateHint.
  ///
  /// In en, this message translates to:
  /// **'DD.MM.YYYY HH:mm'**
  String get competitionDateHint;

  /// No description provided for @registrationDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Dates'**
  String get registrationDatesLabel;

  /// No description provided for @registrationDatesOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional registration start and end times.'**
  String get registrationDatesOptional;

  /// No description provided for @registrationStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration start'**
  String get registrationStartLabel;

  /// No description provided for @registrationEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration end'**
  String get registrationEndLabel;

  /// No description provided for @savingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingInProgress;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// No description provided for @competitionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Competition name is required'**
  String get competitionNameRequired;

  /// No description provided for @startDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Start date is required'**
  String get startDateRequired;

  /// No description provided for @endDateRequired.
  ///
  /// In en, this message translates to:
  /// **'End date is required'**
  String get endDateRequired;

  /// No description provided for @startDateCannotBeAfterEndDate.
  ///
  /// In en, this message translates to:
  /// **'Start date cannot be after end date'**
  String get startDateCannotBeAfterEndDate;

  /// No description provided for @competitionSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Competition created successfully!'**
  String get competitionSavedSuccess;

  /// No description provided for @competitionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load competitions'**
  String get competitionLoadError;

  /// No description provided for @classifications.
  ///
  /// In en, this message translates to:
  /// **'Classifications'**
  String get classifications;

  /// No description provided for @addClassification.
  ///
  /// In en, this message translates to:
  /// **'Add Classification'**
  String get addClassification;

  /// No description provided for @noClassificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No classifications yet'**
  String get noClassificationsYet;

  /// No description provided for @noClassificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add at least one classification to continue.'**
  String get noClassificationsDesc;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @classificationAtLeastOneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one classification'**
  String get classificationAtLeastOneRequired;

  /// No description provided for @completeCompetition.
  ///
  /// In en, this message translates to:
  /// **'Complete Competition'**
  String get completeCompetition;

  /// No description provided for @savingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingGeneric;

  /// No description provided for @untitledCompetition.
  ///
  /// In en, this message translates to:
  /// **'Untitled Competition'**
  String get untitledCompetition;

  /// No description provided for @dateLabelGeneric.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabelGeneric;

  /// No description provided for @dateNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Date not provided'**
  String get dateNotProvided;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDate;

  /// No description provided for @enterValidDistance.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid distance'**
  String get enterValidDistance;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @classificationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Classification name'**
  String get classificationNameLabel;

  /// No description provided for @ageGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Age group'**
  String get ageGroupLabel;

  /// No description provided for @bowTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bow type'**
  String get bowTypeLabel;

  /// No description provided for @environmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentLabel;

  /// No description provided for @distanceMetersLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance (meters)'**
  String get distanceMetersLabel;

  /// No description provided for @customDistance.
  ///
  /// In en, this message translates to:
  /// **'Custom Distance'**
  String get customDistance;

  /// No description provided for @customDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'Custom distance (meters)'**
  String get customDistanceMeters;

  /// No description provided for @editClassificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Classification'**
  String get editClassificationTitle;

  /// No description provided for @addClassificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Classification'**
  String get addClassificationTitle;

  /// No description provided for @myCompetitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Competitions'**
  String get myCompetitionsTitle;

  /// No description provided for @myCompetitionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your competitions.'**
  String get myCompetitionsSubtitle;

  /// No description provided for @myCompetitionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No competitions yet'**
  String get myCompetitionsEmptyTitle;

  /// No description provided for @myCompetitionsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first competition to get started.'**
  String get myCompetitionsEmptyDesc;

  /// No description provided for @competitionStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get competitionStatusDraft;

  /// No description provided for @competitionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get competitionStatusActive;

  /// No description provided for @competitionStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get competitionStatusCompleted;

  /// No description provided for @competitionStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get competitionStatusCancelled;

  /// No description provided for @competitionCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get competitionCreatedOn;

  /// No description provided for @competitionStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get competitionStartsOn;

  /// No description provided for @competitionEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get competitionEndsOn;

  /// No description provided for @registrationStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Registration starts on'**
  String get registrationStartsOn;

  /// No description provided for @registrationEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Registration ends on'**
  String get registrationEndsOn;

  /// No description provided for @competitionParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get competitionParticipants;

  /// No description provided for @competitionViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get competitionViewDetails;

  /// No description provided for @competitionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get competitionEdit;

  /// No description provided for @competitionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get competitionDelete;

  /// No description provided for @competitionDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this competition?'**
  String get competitionDeleteConfirm;

  /// No description provided for @competitionDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Competition deleted successfully'**
  String get competitionDeleteSuccess;

  /// No description provided for @editCompetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Competition'**
  String get editCompetitionTitle;

  /// No description provided for @competitionUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Competition updated successfully'**
  String get competitionUpdateSuccess;

  /// No description provided for @competitionUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update competition'**
  String get competitionUpdateError;

  /// No description provided for @classificationDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this classification?'**
  String get classificationDeleteConfirm;

  /// No description provided for @classificationDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Classification'**
  String get classificationDeleteTitle;

  /// No description provided for @competitionCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Competition created successfully!'**
  String get competitionCreatedSuccess;

  /// No description provided for @competitionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get competitionDateLabel;

  /// No description provided for @competitionDateNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Date not provided'**
  String get competitionDateNotProvided;

  /// No description provided for @competitionInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get competitionInvalidDate;

  /// No description provided for @ageGroup9_10.
  ///
  /// In en, this message translates to:
  /// **'9-10 Years'**
  String get ageGroup9_10;

  /// No description provided for @ageGroup11_12.
  ///
  /// In en, this message translates to:
  /// **'11-12 Years'**
  String get ageGroup11_12;

  /// No description provided for @ageGroup13_14.
  ///
  /// In en, this message translates to:
  /// **'13-14 Years'**
  String get ageGroup13_14;

  /// No description provided for @ageGroupU18.
  ///
  /// In en, this message translates to:
  /// **'U18 (15-16-17)'**
  String get ageGroupU18;

  /// No description provided for @ageGroupU21.
  ///
  /// In en, this message translates to:
  /// **'U21 (18-19-20)'**
  String get ageGroupU21;

  /// No description provided for @ageGroupSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get ageGroupSenior;

  /// No description provided for @bowTypeRecurve.
  ///
  /// In en, this message translates to:
  /// **'Recurve'**
  String get bowTypeRecurve;

  /// No description provided for @bowTypeCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get bowTypeCompound;

  /// No description provided for @bowTypeBarebow.
  ///
  /// In en, this message translates to:
  /// **'Barebow'**
  String get bowTypeBarebow;

  /// No description provided for @environmentIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get environmentIndoor;

  /// No description provided for @environmentOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get environmentOutdoor;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get genderMixed;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Changes will not be saved. Are you sure?'**
  String get unsavedChangesMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileUpdated;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettings;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @competitionClassificationsCount.
  ///
  /// In en, this message translates to:
  /// **'Classifications: {count}'**
  String competitionClassificationsCount(int count);

  /// No description provided for @competitionVisibleIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition ID'**
  String get competitionVisibleIdLabel;

  /// No description provided for @competitionVisibleIdCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get competitionVisibleIdCopyTooltip;

  /// No description provided for @competitionVisibleIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Competition ID copied'**
  String get competitionVisibleIdCopied;

  /// No description provided for @participantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsTitle;

  /// No description provided for @participantsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load participants'**
  String get participantsLoadError;

  /// No description provided for @participantsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get participantsEmptyTitle;

  /// No description provided for @participantsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'No one has registered for this competition yet.'**
  String get participantsEmptyDesc;

  /// No description provided for @participantAthleteId.
  ///
  /// In en, this message translates to:
  /// **'Athlete ID'**
  String get participantAthleteId;

  /// No description provided for @participantGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get participantGender;

  /// No description provided for @participantAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Age group'**
  String get participantAgeGroup;

  /// No description provided for @participantEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get participantEquipment;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get cancelledStatus;

  /// No description provided for @acceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptRequest;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectRequest;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @acceptRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept this participant?'**
  String get acceptRequestConfirm;

  /// No description provided for @rejectRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject this participant?'**
  String get rejectRequestConfirm;

  /// No description provided for @changeToAcceptedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change status to accepted?'**
  String get changeToAcceptedConfirm;

  /// No description provided for @changeToRejectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change status to rejected?'**
  String get changeToRejectedConfirm;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get requestAccepted;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @statusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get statusChanged;

  /// No description provided for @activeCompetitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Competitions'**
  String get activeCompetitionsTitle;

  /// No description provided for @activeCompetitionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and join available competitions.'**
  String get activeCompetitionsSubtitle;

  /// No description provided for @activeCompetitionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active competitions'**
  String get activeCompetitionsEmptyTitle;

  /// No description provided for @activeCompetitionsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'There are no competitions open for registration right now.'**
  String get activeCompetitionsEmptyDesc;

  /// No description provided for @competitionJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get competitionJoin;

  /// No description provided for @competitionJoined.
  ///
  /// In en, this message translates to:
  /// **'You have joined the competition'**
  String get competitionJoined;

  /// No description provided for @competitionJoinError.
  ///
  /// In en, this message translates to:
  /// **'Failed to join competition'**
  String get competitionJoinError;

  /// No description provided for @athleteProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Athlete profile required. Please complete your profile first.'**
  String get athleteProfileRequired;

  /// No description provided for @registrationOpen.
  ///
  /// In en, this message translates to:
  /// **'Registration open'**
  String get registrationOpen;

  /// No description provided for @registrationClosed.
  ///
  /// In en, this message translates to:
  /// **'Registration closed'**
  String get registrationClosed;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSent;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to cancel your join request?'**
  String get cancelRequestConfirm;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get requestCancelled;

  /// No description provided for @selectClassificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select classification'**
  String get selectClassificationTitle;

  /// No description provided for @selectClassificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Choose your classification to join'**
  String get selectClassificationInstruction;

  /// No description provided for @noClassificationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No classifications available for this competition'**
  String get noClassificationsAvailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
