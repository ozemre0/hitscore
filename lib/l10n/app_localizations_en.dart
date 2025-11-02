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
  String get roleRequired => 'Role is required';

  @override
  String get roleWarningTitle => 'Role Selection Information';

  @override
  String get roleWarningMessage => 'You cannot change your role without deleting your account. Role functionalities are different in the Hit Archery app, but in this app all roles have the same functionality.';

  @override
  String get understood => 'Understood';

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
  String get competitionDurationDesc => 'Select start and end dates.';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get competitionDateHint => 'DD.MM.YYYY';

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
  String get saveAndContinue => 'Save and Continue';

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
  String get participantAthleteId => 'User ID';

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
  String get athlete => 'Athlete';

  @override
  String get coach => 'Coach';

  @override
  String get registrationOpen => 'Registration open';

  @override
  String get registrationClosed => 'Registration closed';

  @override
  String get registrationAllowedLabel => 'Allow registration';

  @override
  String get registrationAllowedDesc => 'If enabled, users can send join requests. You can change this later.';

  @override
  String get scoreAllowedLabel => 'Allow score entry';

  @override
  String get scoreAllowedDesc => 'Lets participants enter scores. Enable before the competition; you can change this later.';

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
  String get pendingClassificationLabel => 'Requested classification';

  @override
  String get selectClassificationTitle => 'Select classification';

  @override
  String get selectClassificationInstruction => 'Choose your classification to join';

  @override
  String get noClassificationsAvailable => 'No classifications available for this competition';

  @override
  String get addAthletes => 'Add Participants';

  @override
  String get searchAthleteHint => 'Search athletes';

  @override
  String get add => 'Add';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get onlyEligible => 'Only eligible';

  @override
  String get noResults => 'No results';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get addedSuccessfully => 'Added successfully';

  @override
  String get addToCompetition => 'Add to competition';

  @override
  String get searchCompetitionHint => 'Search competitions';

  @override
  String get alreadyRequestedThisClassification => 'You already have a pending request for this classification';

  @override
  String pendingRequestsCount(int count) {
    return 'Pending requests: $count';
  }

  @override
  String acceptedParticipantsCount(int count) {
    return 'Accepted participants: $count';
  }

  @override
  String get all => 'All';

  @override
  String get classification => 'Classification';

  @override
  String get participantClassification => 'Classification';

  @override
  String get participantCompetitionsTitle => 'My Participations';

  @override
  String get participantCompetitionsSubtitle => 'View competitions you\'re participating in.';

  @override
  String get participantCompetitionsEmptyTitle => 'No participations yet';

  @override
  String get participantCompetitionsEmptyDesc => 'You haven\'t joined any competitions yet.';

  @override
  String get participantCompetitionsLoadError => 'Failed to load participations';

  @override
  String get competitionStatus => 'Status';

  @override
  String get joinedOn => 'Joined on';

  @override
  String get leaveCompetition => 'Leave';

  @override
  String get leaveCompetitionConfirm => 'Do you want to leave this competition?';

  @override
  String get competitionLeft => 'You have left the competition';

  @override
  String get leaveCompetitionError => 'Failed to leave competition';

  @override
  String get scoreEntryTitle => 'Score Entry';

  @override
  String get scoreEntrySubtitle => 'Enter your scores for this competition';

  @override
  String get enterScore => 'Enter Score';

  @override
  String get scoreEntryComingSoon => 'Score entry feature coming soon';

  @override
  String get scoreEntryAllowed => 'Score entry allowed';

  @override
  String get scoreEntryNotAllowed => 'Score entry not allowed';

  @override
  String get classificationLabel => 'Classification';

  @override
  String get roundCountLabel => 'Round count';

  @override
  String get arrowsPerSetLabel => 'Arrows per set';

  @override
  String get setsPerRoundLabel => 'Sets per round';

  @override
  String roundSeparator(Object roundNumber) {
    return 'Round $roundNumber';
  }

  @override
  String get myOrganizedCompetitionsTitle => 'My Organized Competitions';

  @override
  String get myOrganizedCompetitionsSubtitle => 'Manage competitions you have created.';

  @override
  String get participantClub => 'Club';

  @override
  String get noClub => 'No Club';

  @override
  String get currentSet => 'Current Set';

  @override
  String get totalScore => 'Total Score';

  @override
  String tapScoreToContinue(int setNumber) {
    return 'Tap the score buttons below to continue training. You are now writing Set $setNumber.';
  }

  @override
  String editSet(int setNumber) {
    return 'Edit - Set $setNumber';
  }

  @override
  String get edit => 'Edit';

  @override
  String overwritingSet(int setNumber) {
    return 'You are overwriting Set $setNumber. Tap the score buttons below to continue.';
  }

  @override
  String get guestTitle => 'Welcome';

  @override
  String get guestSubtitle => 'Explore active competitions or sign in to continue.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get browseActiveCompetitions => 'Active Competitions';

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeSubtitle => 'Choose your language and explore HitScore';

  @override
  String get onboardingLanguageNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingIntroTitle => 'Manage competitions with ease';

  @override
  String get onboardingIntroDescription => 'Join competitions, organize events, and track scores seamlessly.';

  @override
  String get onboardingFeaturesTitle => 'What you can do';

  @override
  String get onboardingFeatureSessionsTitle => 'Participate';

  @override
  String get onboardingFeatureSessionsDescription => 'Browse active competitions and send join requests.';

  @override
  String get onboardingFeatureCoachTitle => 'Organize';

  @override
  String get onboardingFeatureCoachDescription => 'Create competitions, manage participants and classifications.';

  @override
  String get onboardingFeatureToolsTitle => 'Track Scores';

  @override
  String get onboardingFeatureToolsDescription => 'Enter and follow scores with clear, responsive screens.';

  @override
  String get availableScoreButtonsLabel => 'Available Score Buttons';

  @override
  String get availableScoreButtonsDescription => 'Select which score buttons will be available for this classification';

  @override
  String get autoFilled => 'Auto Filled';

  @override
  String get roundSettingsLabel => 'Round Settings';

  @override
  String get scoreEntryNotAllowedTitle => 'Score Entry Not Available';

  @override
  String get scoreEntryNotAllowedMessage => 'Score entry is not currently available for this competition. You will be able to enter scores when the organizer opens it.';

  @override
  String get ok => 'OK';

  @override
  String get filters => 'Filters';

  @override
  String get filter => 'Filter';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear';

  @override
  String get dateFrom => 'Start date';

  @override
  String get dateTo => 'End date';

  @override
  String get dateRange => 'Date range';

  @override
  String get presetToday => 'Today';

  @override
  String get presetThisWeek => 'This week';

  @override
  String get presetThisMonth => 'This month';

  @override
  String get scorePermission => 'Score permission';

  @override
  String get scoreAllowed => 'Allowed';

  @override
  String get scoreNotAllowed => 'Not allowed';

  @override
  String get sets => 'Sets';

  @override
  String setLabel(int setNumber) {
    return 'Set $setNumber';
  }

  @override
  String get arrows => 'Arrows';

  @override
  String get competitionArchiveTitle => 'Competition Archive';

  @override
  String get competitionArchiveEmptyTitle => 'No archived competitions';

  @override
  String get competitionArchiveEmptyDesc => 'Completed or past competitions will appear here.';

  @override
  String get addOrganizer => 'Add organizer';

  @override
  String get addOrganizersTitle => 'Add Organizers';

  @override
  String get addOrganizersSubtitle => 'Search by name or profile ID and select users.';

  @override
  String get searchUserHint => 'Search users (name or profile ID)';

  @override
  String get organizersUpdated => 'Organizers updated';

  @override
  String get update => 'Update';

  @override
  String get searchToFindUsers => 'Search to find users';

  @override
  String get creatorTag => 'Creator';

  @override
  String get competitionArchiveSubtitle => 'Browse all competitions, past and present.';

  @override
  String get arrowMissSymbol => 'M';

  @override
  String get arrowXSymbol => 'X';

  @override
  String get noArrowsYet => 'No arrows yet';

  @override
  String get undo => 'Undo';

  @override
  String get reset => 'Reset';

  @override
  String get complete => 'Complete';

  @override
  String maximumSetsReached(int setsPerRound) {
    return 'Maximum sets reached ($setsPerRound). You cannot add more sets.';
  }

  @override
  String get noScoreYet => 'No score yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsWelcomeTitle => 'Stay Updated';

  @override
  String get notificationsWelcomeSubtitle => 'Get the latest updates about your competitions and activities';

  @override
  String get noNotificationsTitle => 'No notifications yet';

  @override
  String get noNotificationsSubtitle => 'When you have new notifications, they will appear here';

  @override
  String get total => 'Total';

  @override
  String get eliminationSettingsTitle => 'Elimination Settings';

  @override
  String get eliminationSettingsSubtitle => 'Configure elimination system for your competition';

  @override
  String get bowTypeSelection => 'Bow Type Selection';

  @override
  String get bowTypeSelectionSubtitle => 'Select the bow type for elimination matches';

  @override
  String get recurveBow => 'Recurve';

  @override
  String get barebowBow => 'Barebow';

  @override
  String get compoundBow => 'Compound';

  @override
  String get cutoffSettings => 'Cutoff Settings';

  @override
  String get cutoffSettingsSubtitle => 'Set the cutoff rank for elimination participants';

  @override
  String get cutoffRank => 'Cutoff Rank';

  @override
  String get cutoffLimit => 'Cutoff Limit';

  @override
  String cutoffLimitDescription(Object count) {
    return 'The first $count ranked athletes are included in the elimination system';
  }

  @override
  String get athleteCount => 'Athlete Count';

  @override
  String get enterValueBetween => 'Enter a value between 8-256';

  @override
  String get possibleBracketCombinations => 'Possible Bracket Combinations';

  @override
  String availableOptionsForCutoff(Object count) {
    return 'Available options for Cutoff ($count athletes):';
  }

  @override
  String personBracket(Object count) {
    return '$count Person Bracket';
  }

  @override
  String get allAthletesInMainTable => 'All athletes in the main table';

  @override
  String preliminaryElimination(Object total, Object winners) {
    return 'Preliminary Round: $total athletes → $winners winners';
  }

  @override
  String get allAthletesInMainTableShort => 'All athletes in main table';

  @override
  String preliminaryEliminationShort(Object total, Object winners) {
    return 'Preliminary: $total athletes → $winners winners';
  }

  @override
  String get close => 'Close';

  @override
  String get showAllMatches => 'Show All Matches';

  @override
  String get detailedMatchSchedule => 'Detailed Match Schedule';

  @override
  String mainTableStart(Object count) {
    return 'Main Table Start ($count athletes)';
  }

  @override
  String preliminaryEliminationStart(Object target, Object total) {
    return 'Preliminary Elimination ($total → $target athletes)';
  }

  @override
  String get byeSettings => 'Bye Settings';

  @override
  String get byeSettingsSubtitle => 'Configure bye (automatic advancement) settings';

  @override
  String get allowByes => 'Allow Byes';

  @override
  String get allowByesSubtitle => 'Enable automatic advancement for top-ranked participants';

  @override
  String get byeStrategy => 'Bye Strategy';

  @override
  String get highestRankingStrategy => 'Highest Ranking';

  @override
  String get evenDistributionStrategy => 'Even Distribution';

  @override
  String get performanceBasedStrategy => 'Performance Based';

  @override
  String get bracketSettings => 'Bracket Settings';

  @override
  String get bracketSettingsSubtitle => 'Select bracket size for elimination';

  @override
  String get eliminationPreview => 'Elimination Preview';

  @override
  String get noValidCombinations => 'No valid combinations available';

  @override
  String get recommended => 'Recommended';

  @override
  String get eliminationBracketTitle => 'Elimination Bracket';

  @override
  String get totalParticipants => 'Participants';

  @override
  String get activeMatches => 'Active';

  @override
  String get currentRound => 'Round';

  @override
  String get round => 'Round';

  @override
  String get bracketTree => 'Bracket Tree';

  @override
  String get bracketVisualizationComingSoon => 'Bracket Visualization';

  @override
  String get bracketVisualizationSubtitle => 'Interactive bracket tree view coming soon';

  @override
  String get matches => 'Matches';

  @override
  String get noMatchesInRound => 'No matches in this round';

  @override
  String get noMatchesInRoundSubtitle => 'Matches will appear here when created';

  @override
  String get scoreMatch => 'Score';

  @override
  String get bye => 'Bye';

  @override
  String get unknown => 'Unknown';

  @override
  String get eliminationSettings => 'Settings';

  @override
  String get exportResults => 'Export Results';

  @override
  String get eliminationStatusTitle => 'Elimination Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusEliminated => 'Eliminated';

  @override
  String get statusChampion => 'Champion';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get currentPosition => 'Current Position';

  @override
  String get bracketPosition => 'Position';

  @override
  String get byeStatusMessage => 'You have a bye and advance automatically to the next round';

  @override
  String get nextMatch => 'Next Match';

  @override
  String get you => 'You';

  @override
  String get tbd => 'TBD';

  @override
  String get scheduledTime => 'Scheduled';

  @override
  String get noUpcomingMatch => 'No upcoming match';

  @override
  String get myMatches => 'My Matches';

  @override
  String get noMatchHistory => 'No match history yet';

  @override
  String get victory => 'Victory';

  @override
  String get defeat => 'Defeat';

  @override
  String get statistics => 'Statistics';

  @override
  String get matchesPlayed => 'Played';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get matchScoringTitle => 'Match Scoring';

  @override
  String get participant1 => 'Participant 1';

  @override
  String get participant2 => 'Participant 2';

  @override
  String get selectSet => 'Select Set';

  @override
  String get set => 'Set';

  @override
  String get scoring => 'Scoring';

  @override
  String get score => 'Score';

  @override
  String get saveSet => 'Save Set';

  @override
  String get completedSets => 'Completed Sets';

  @override
  String get tieBreak => 'Tie Break';

  @override
  String get tieBreakDescription => 'The match is tied. A tie break shoot-off is required.';

  @override
  String get startTieBreak => 'Start Tie Break';

  @override
  String get completeMatch => 'Complete Match';

  @override
  String get matchCompleted => 'Match Completed';

  @override
  String get matchCompletedDescription => 'The match has been successfully completed and saved';

  @override
  String get completed => 'Completed';

  @override
  String get active => 'Active';

  @override
  String get classificationNamePreview => 'Classification Name Preview';

  @override
  String get classificationNamePreviewEmpty => 'Select classification properties to see the auto-generated name';

  @override
  String get autoSelected => 'Auto Selected';

  @override
  String get multiByeSystem => 'Multi-Bye System';

  @override
  String multiByeSystemStart(String total, String target) {
    return 'Multi-Bye Elimination System ($total → $target athletes)';
  }

  @override
  String multiByeSystemShort(String threeRound, String twoRound, String oneRound, String zeroRound) {
    return '3R: $threeRound, 2R: $twoRound, 1R: $oneRound, 0R: $zeroRound';
  }

  @override
  String get thirdPlaceMatch => '3rd Place Match';

  @override
  String get thirdPlaceMatchTitle => '3RD PLACE MATCH';

  @override
  String thirdPlaceMatchDescription(int round) {
    return '3RD PLACE: L${round}_1 vs L${round}_2';
  }

  @override
  String get register => 'Register';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters long';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later';

  @override
  String get emailVerificationRequiredContent => 'We\'ve sent a verification email to your address. Please check your email and click the verification link to activate your account.';

  @override
  String get emailAlreadyRegisteredTitle => 'Email Already Registered';

  @override
  String get emailAlreadyRegisteredMessage => 'This email address is already registered. Please try logging in instead.';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordDescription => 'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Password reset link sent to your email';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get redirectingToLogin => 'Redirecting to login page...';

  @override
  String get invalidResetLink => 'Invalid or expired reset link';

  @override
  String get invalidResetLinkDescription => 'This password reset link is invalid or has expired. Please request a new password reset.';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get tokenExpired => 'Password reset link has expired';

  @override
  String get passwordResetError => 'Error resetting password';

  @override
  String get processingAuthentication => 'Verifying reset link...';

  @override
  String get resetPasswordNewPasswordTitle => 'Enter New Password';

  @override
  String get resetPasswordNewPasswordDescription => 'Please enter your new password below';

  @override
  String get tokenExpiryWarning => 'This reset link expires quickly. Please complete the process immediately.';

  @override
  String error(String message) {
    return 'Error: $message';
  }
}
