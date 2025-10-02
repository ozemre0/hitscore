// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HitScore';

  @override
  String get loginTitle => 'Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginErrorGoogle => 'Google sign-in failed.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get refresh => 'Refresh';

  @override
  String get errorGeneric => 'An error occurred.';

  @override
  String get networkError => 'Network issue. Please check your connection.';

  @override
  String get setupProfile => 'Setup Profile';

  @override
  String get setupProfileDescription => 'No profile found. Please complete your profile.';

  @override
  String get back => 'Back';

  @override
  String get role => 'Role';

  @override
  String get gender => 'Gender';

  @override
  String get genderRequired => 'Gender is required';

  @override
  String get birthDateLabel => 'Birth date';

  @override
  String get birthDateRequired => 'Birth date is required';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get selectCity => 'Select City';

  @override
  String get homeTab => 'Home';

  @override
  String get profileTab => 'Profile';

  @override
  String get clubLabel => 'Club';

  @override
  String get profileId => 'Profile ID';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get addressSimple => 'Address';

  @override
  String get phoneNumberSimple => 'Phone';

  @override
  String get countryLabel => 'Country';

  @override
  String get cityLabel => 'City';

  @override
  String get clubIdLabel => 'Club ID';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get firstName => 'First name';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastName => 'Last name';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get birthDate => 'Birth date';

  @override
  String get dateNotSelected => 'Not selected';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get clubInfo => 'Club Information';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get selectClub => 'Select Club';

  @override
  String get allCountries => 'All Countries';

  @override
  String get allCities => 'All Cities';

  @override
  String get individualClub => 'Individual (No Club)';

  @override
  String get removeClub => 'Remove Club';

  @override
  String get roleChangeNotAllowed => 'Role can\'t be changed after setup';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get emailVerificationRequiredTitle => 'Email verification required';

  @override
  String get emailVerificationLoginContent => 'Please verify your email before logging in.';

  @override
  String get emailVerificationRequiredOk => 'OK';

  @override
  String get loginSuccessRedirectingShort => 'Login successful. Redirecting...';

  @override
  String get loginErrorInvalidCredentials => 'Invalid email or password.';

  @override
  String get loginErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String welcomeWithName(String name) {
    return 'Welcome $name';
  }

  @override
  String get createCompetitionTitle => 'Create Competition';

  @override
  String get competitionGeneralInfo => 'General Information';

  @override
  String get competitionGeneralInfoDesc => 'Fill in the competition details below.';

  @override
  String get competitionNameLabel => 'Competition name';

  @override
  String get competitionDescriptionLabel => 'Description';

  @override
  String get competitionDuration => 'Competition Duration';

  @override
  String get competitionDurationDesc => 'Select start and end date/time.';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get competitionDateHint => 'DD.MM.YYYY HH:mm';

  @override
  String get registrationDatesLabel => 'Registration Dates';

  @override
  String get registrationDatesOptional => 'Optional registration start and end times.';

  @override
  String get registrationStartLabel => 'Registration start';

  @override
  String get registrationEndLabel => 'Registration end';

  @override
  String get savingInProgress => 'Saving...';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String get competitionNameRequired => 'Competition name is required';

  @override
  String get startDateRequired => 'Start date is required';

  @override
  String get endDateRequired => 'End date is required';

  @override
  String get startDateCannotBeAfterEndDate => 'Start date cannot be after end date';

  @override
  String get competitionSavedSuccess => 'Competition created successfully!';

  @override
  String get competitionLoadError => 'Failed to load competitions';

  @override
  String get classifications => 'Classifications';

  @override
  String get addClassification => 'Add Classification';

  @override
  String get noClassificationsYet => 'No classifications yet';

  @override
  String get noClassificationsDesc => 'Add at least one classification to continue.';

  @override
  String get delete => 'Delete';

  @override
  String get classificationAtLeastOneRequired => 'Please add at least one classification';

  @override
  String get completeCompetition => 'Complete Competition';

  @override
  String get savingGeneric => 'Saving...';

  @override
  String get untitledCompetition => 'Untitled Competition';

  @override
  String get dateLabelGeneric => 'Date';

  @override
  String get dateNotProvided => 'Date not provided';

  @override
  String get invalidDate => 'Invalid date';

  @override
  String get enterValidDistance => 'Enter a valid distance';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get classificationNameLabel => 'Classification name';

  @override
  String get ageGroupLabel => 'Age group';

  @override
  String get bowTypeLabel => 'Bow type';

  @override
  String get environmentLabel => 'Environment';

  @override
  String get distanceMetersLabel => 'Distance (meters)';

  @override
  String get customDistance => 'Custom Distance';

  @override
  String get customDistanceMeters => 'Custom distance (meters)';

  @override
  String get editClassificationTitle => 'Edit Classification';

  @override
  String get addClassificationTitle => 'Add Classification';

  @override
  String get myCompetitionsTitle => 'My Competitions';

  @override
  String get myCompetitionsSubtitle => 'View and manage your competitions.';

  @override
  String get myCompetitionsEmptyTitle => 'No competitions yet';

  @override
  String get myCompetitionsEmptyDesc => 'Create your first competition to get started.';

  @override
  String get competitionStatusDraft => 'Draft';

  @override
  String get competitionStatusActive => 'Active';

  @override
  String get competitionStatusCompleted => 'Completed';

  @override
  String get competitionStatusCancelled => 'Cancelled';

  @override
  String get competitionCreatedOn => 'Created on';

  @override
  String get competitionStartsOn => 'Starts on';

  @override
  String get competitionEndsOn => 'Ends on';

  @override
  String get registrationStartsOn => 'Registration starts on';

  @override
  String get registrationEndsOn => 'Registration ends on';

  @override
  String get competitionParticipants => 'Participants';

  @override
  String get competitionViewDetails => 'View Details';

  @override
  String get competitionEdit => 'Edit';

  @override
  String get competitionDelete => 'Delete';

  @override
  String get competitionDeleteConfirm => 'Are you sure you want to delete this competition?';

  @override
  String get competitionDeleteSuccess => 'Competition deleted successfully';

  @override
  String get editCompetitionTitle => 'Edit Competition';

  @override
  String get competitionUpdateSuccess => 'Competition updated successfully';

  @override
  String get competitionUpdateError => 'Failed to update competition';

  @override
  String get classificationDeleteConfirm => 'Are you sure you want to delete this classification?';

  @override
  String get classificationDeleteTitle => 'Delete Classification';

  @override
  String get competitionCreatedSuccess => 'Competition created successfully!';

  @override
  String get competitionDateLabel => 'Date';

  @override
  String get competitionDateNotProvided => 'Date not provided';

  @override
  String get competitionInvalidDate => 'Invalid date';

  @override
  String get ageGroup9_10 => '9-10 Years';

  @override
  String get ageGroup11_12 => '11-12 Years';

  @override
  String get ageGroup13_14 => '13-14 Years';

  @override
  String get ageGroupU18 => 'U18 (15-16-17)';

  @override
  String get ageGroupU21 => 'U21 (18-19-20)';

  @override
  String get ageGroupSenior => 'Senior';

  @override
  String get bowTypeRecurve => 'Recurve';

  @override
  String get bowTypeCompound => 'Compound';

  @override
  String get bowTypeBarebow => 'Barebow';

  @override
  String get environmentIndoor => 'Indoor';

  @override
  String get environmentOutdoor => 'Outdoor';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMixed => 'Mixed';

  @override
  String get genderLabel => 'Gender';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage => 'Changes will not be saved. Are you sure?';

  @override
  String get exit => 'Exit';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileUpdated => 'Profile saved successfully';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSettings => 'Language';

  @override
  String get themeSettings => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String competitionClassificationsCount(int count) {
    return 'Classifications: $count';
  }

  @override
  String get competitionVisibleIdLabel => 'Competition ID';

  @override
  String get competitionVisibleIdCopyTooltip => 'Copy ID';

  @override
  String get competitionVisibleIdCopied => 'Competition ID copied';

  @override
  String get participantsTitle => 'Participants';

  @override
  String get participantsLoadError => 'Failed to load participants';

  @override
  String get participantsEmptyTitle => 'No participants yet';

  @override
  String get participantsEmptyDesc => 'No one has registered for this competition yet.';

  @override
  String get participantAthleteId => 'Athlete ID';

  @override
  String get participantGender => 'Gender';

  @override
  String get participantAgeGroup => 'Age group';

  @override
  String get participantEquipment => 'Equipment';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get acceptedStatus => 'Accepted';

  @override
  String get cancelledStatus => 'Rejected';

  @override
  String get acceptRequest => 'Accept';

  @override
  String get rejectRequest => 'Reject';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get acceptRequestConfirm => 'Accept this participant?';

  @override
  String get rejectRequestConfirm => 'Reject this participant?';

  @override
  String get changeToAcceptedConfirm => 'Change status to accepted?';

  @override
  String get changeToRejectedConfirm => 'Change status to rejected?';

  @override
  String get requestAccepted => 'Request accepted';

  @override
  String get requestRejected => 'Request rejected';

  @override
  String get statusChanged => 'Status changed';

  @override
  String get activeCompetitionsTitle => 'Active Competitions';

  @override
  String get activeCompetitionsSubtitle => 'Browse and join available competitions.';

  @override
  String get activeCompetitionsEmptyTitle => 'No active competitions';

  @override
  String get activeCompetitionsEmptyDesc => 'There are no competitions open for registration right now.';

  @override
  String get competitionJoin => 'Join';

  @override
  String get competitionJoined => 'You have joined the competition';

  @override
  String get competitionJoinError => 'Failed to join competition';

  @override
  String get athleteProfileRequired => 'Athlete profile required. Please complete your profile first.';

  @override
  String get registrationOpen => 'Registration open';

  @override
  String get registrationClosed => 'Registration closed';

  @override
  String get requestSent => 'Request sent';

  @override
  String get pending => 'Pending';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get cancelRequestConfirm => 'Do you want to cancel your join request?';

  @override
  String get requestCancelled => 'Request cancelled';

  @override
  String get selectClassificationTitle => 'Select classification';

  @override
  String get selectClassificationInstruction => 'Choose your classification to join';

  @override
  String get noClassificationsAvailable => 'No classifications available for this competition';
}
