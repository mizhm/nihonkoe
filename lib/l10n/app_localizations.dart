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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @tabsHome.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabsHome;

  /// No description provided for @tabsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabsSearch;

  /// No description provided for @tabsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabsLibrary;

  /// No description provided for @tabsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabsSettings;

  /// No description provided for @feedRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get feedRequested;

  /// No description provided for @feedManiax.
  ///
  /// In en, this message translates to:
  /// **'R18'**
  String get feedManiax;

  /// No description provided for @sortHeading.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortHeading;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title A→Z'**
  String get sortTitle;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sortPopular;

  /// No description provided for @sortPopularWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get sortPopularWeek;

  /// No description provided for @sortPopularMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get sortPopularMonth;

  /// No description provided for @sortPopularYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get sortPopularYear;

  /// No description provided for @sortPopularAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get sortPopularAll;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @listErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get listErrorTitle;

  /// No description provided for @listErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get listErrorHint;

  /// No description provided for @listEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get listEmpty;

  /// No description provided for @listLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get listLoadMore;

  /// No description provided for @listRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Pull down to try again.'**
  String get listRefreshFailed;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Title, CV, RJ code…'**
  String get searchPlaceholder;

  /// No description provided for @searchFilterPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Filter list…'**
  String get searchFilterPlaceholder;

  /// No description provided for @searchModeKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get searchModeKeyword;

  /// No description provided for @searchModeTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get searchModeTags;

  /// No description provided for @searchModeCv.
  ///
  /// In en, this message translates to:
  /// **'Voice actors'**
  String get searchModeCv;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, CV or RJ code'**
  String get searchHint;

  /// No description provided for @searchHintDescription.
  ///
  /// In en, this message translates to:
  /// **'Press search on the keyboard to see results.'**
  String get searchHintDescription;

  /// No description provided for @searchWorks.
  ///
  /// In en, this message translates to:
  /// **'{count} works'**
  String searchWorks(Object count);

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// No description provided for @searchClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearHistory;

  /// No description provided for @searchRemoveHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{q}\" from history'**
  String searchRemoveHistory(Object q);

  /// No description provided for @searchInAll.
  ///
  /// In en, this message translates to:
  /// **'Search \"{q}\" in all works'**
  String searchInAll(Object q);

  /// No description provided for @detailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this work'**
  String get detailLoadFailed;

  /// No description provided for @detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Work not found'**
  String get detailNotFound;

  /// No description provided for @detailPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get detailPlay;

  /// No description provided for @detailResume.
  ///
  /// In en, this message translates to:
  /// **'Resume · {time}'**
  String detailResume(Object time);

  /// No description provided for @detailAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get detailAddToQueue;

  /// No description provided for @detailNoStream.
  ///
  /// In en, this message translates to:
  /// **'This work has no audio yet.'**
  String get detailNoStream;

  /// No description provided for @detailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get detailTags;

  /// No description provided for @detailImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get detailImages;

  /// No description provided for @detailChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters · {count}'**
  String detailChapters(Object count);

  /// No description provided for @detailFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get detailFavorite;

  /// No description provided for @detailUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get detailUnfavorite;

  /// No description provided for @detailRate.
  ///
  /// In en, this message translates to:
  /// **'Rate {n} stars'**
  String detailRate(Object n);

  /// No description provided for @detailOpenImage.
  ///
  /// In en, this message translates to:
  /// **'View image {n}'**
  String detailOpenImage(Object n);

  /// No description provided for @playerNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get playerNowPlaying;

  /// No description provided for @playerClose.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get playerClose;

  /// No description provided for @playerNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get playerNothing;

  /// No description provided for @playerError.
  ///
  /// In en, this message translates to:
  /// **'Playback failed. Check your connection and retry.'**
  String get playerError;

  /// No description provided for @playerErrorShort.
  ///
  /// In en, this message translates to:
  /// **'Playback failed'**
  String get playerErrorShort;

  /// No description provided for @playerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry playback'**
  String get playerRetry;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get playerPreviousChapter;

  /// No description provided for @playerNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get playerNextChapter;

  /// No description provided for @playerBack15.
  ///
  /// In en, this message translates to:
  /// **'Back 15 seconds'**
  String get playerBack15;

  /// No description provided for @playerForward30.
  ///
  /// In en, this message translates to:
  /// **'Forward 30 seconds'**
  String get playerForward30;

  /// No description provided for @playerSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed {rate}x'**
  String playerSpeed(Object rate);

  /// No description provided for @speedTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get speedTitle;

  /// No description provided for @playerShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playerShuffle;

  /// No description provided for @playerShuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off shuffle'**
  String get playerShuffleOff;

  /// No description provided for @playerRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat: off'**
  String get playerRepeatOff;

  /// No description provided for @playerRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat: queue'**
  String get playerRepeatAll;

  /// No description provided for @playerRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat: one'**
  String get playerRepeatOne;

  /// No description provided for @playerPosition.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playerPosition;

  /// No description provided for @playerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open player: {title}'**
  String playerOpen(Object title);

  /// No description provided for @playerChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get playerChapters;

  /// No description provided for @playerQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get playerQueue;

  /// No description provided for @playerMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get playerMore;

  /// No description provided for @playerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get playerStop;

  /// No description provided for @moreQueueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String moreQueueCount(Object count);

  /// No description provided for @moreOpenWork.
  ///
  /// In en, this message translates to:
  /// **'Open work page'**
  String get moreOpenWork;

  /// No description provided for @queueRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {title} from queue'**
  String queueRemove(Object title);

  /// No description provided for @sleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTitle;

  /// No description provided for @sleepMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String sleepMinutes(Object n);

  /// No description provided for @sleepChapterEnd.
  ///
  /// In en, this message translates to:
  /// **'End of chapter'**
  String get sleepChapterEnd;

  /// No description provided for @sleepWorkEnd.
  ///
  /// In en, this message translates to:
  /// **'End of work'**
  String get sleepWorkEnd;

  /// No description provided for @sleepOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off timer'**
  String get sleepOff;

  /// No description provided for @sleepByMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get sleepByMinutes;

  /// No description provided for @sleepByContent.
  ///
  /// In en, this message translates to:
  /// **'By content'**
  String get sleepByContent;

  /// No description provided for @sleepStopsAt.
  ///
  /// In en, this message translates to:
  /// **'Stops at {time}'**
  String sleepStopsAt(Object time);

  /// No description provided for @sleepExtend.
  ///
  /// In en, this message translates to:
  /// **'+{n} min'**
  String sleepExtend(Object n);

  /// No description provided for @sleepChangeTo.
  ///
  /// In en, this message translates to:
  /// **'Change to'**
  String get sleepChangeTo;

  /// No description provided for @sleepRemainingChapter.
  ///
  /// In en, this message translates to:
  /// **'End of chapter'**
  String get sleepRemainingChapter;

  /// No description provided for @sleepRemainingWork.
  ///
  /// In en, this message translates to:
  /// **'End of work'**
  String get sleepRemainingWork;

  /// No description provided for @sleepActive.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer: {label}'**
  String sleepActive(Object label);

  /// No description provided for @libraryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavorites;

  /// No description provided for @libraryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libraryHistory;

  /// No description provided for @libraryRated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get libraryRated;

  /// No description provided for @libraryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get libraryClear;

  /// No description provided for @libraryClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear listening history?'**
  String get libraryClearConfirm;

  /// No description provided for @libraryEmptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get libraryEmptyFavorites;

  /// No description provided for @libraryEmptyFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap ♥ on a work to save it.'**
  String get libraryEmptyFavoritesHint;

  /// No description provided for @libraryEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet'**
  String get libraryEmptyHistory;

  /// No description provided for @libraryEmptyRated.
  ///
  /// In en, this message translates to:
  /// **'No rated works yet'**
  String get libraryEmptyRated;

  /// No description provided for @libraryEmptyRatedHint.
  ///
  /// In en, this message translates to:
  /// **'Pick stars on a work page.'**
  String get libraryEmptyRatedHint;

  /// No description provided for @libraryGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get libraryGroupToday;

  /// No description provided for @libraryGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get libraryGroupYesterday;

  /// No description provided for @libraryGroupWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get libraryGroupWeek;

  /// No description provided for @libraryGroupOlder.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get libraryGroupOlder;

  /// No description provided for @libraryInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress · {time}'**
  String libraryInProgress(Object time);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySection;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy mode'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Hide covers on the lock screen and media controls.'**
  String get settingsPrivacyHint;

  /// No description provided for @settingsLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsLock;

  /// No description provided for @settingsLockHint.
  ///
  /// In en, this message translates to:
  /// **'Require Face ID, fingerprint or passcode when reopening.'**
  String get settingsLockHint;

  /// No description provided for @layoutSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch layout: {name}'**
  String layoutSwitch(Object name);

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Large grid'**
  String get layoutGrid;

  /// No description provided for @layoutCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact grid'**
  String get layoutCompact;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get settingsAccent;

  /// No description provided for @accentLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get accentLavender;

  /// No description provided for @accentSakura.
  ///
  /// In en, this message translates to:
  /// **'Sakura'**
  String get accentSakura;

  /// No description provided for @accentOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get accentOcean;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsClearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get settingsClearImageCache;

  /// No description provided for @settingsReloadTags.
  ///
  /// In en, this message translates to:
  /// **'Reload tag & voice actor lists'**
  String get settingsReloadTags;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear listening history'**
  String get settingsClearHistory;

  /// No description provided for @settingsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settingsDone;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsSource.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSource;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock nihonkoe'**
  String get lockPrompt;

  /// No description provided for @lockEnablePrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm enabling app lock'**
  String get lockEnablePrompt;

  /// No description provided for @lockDisablePrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm disabling app lock'**
  String get lockDisablePrompt;

  /// No description provided for @lockUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t enable app lock'**
  String get lockUnavailableTitle;

  /// No description provided for @lockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up Face ID, a fingerprint or a passcode on this device first.'**
  String get lockUnavailable;

  /// No description provided for @lockFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t authenticate'**
  String get lockFailedTitle;

  /// No description provided for @lockLockout.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Unlock your device, then try again.'**
  String get lockLockout;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get homeFeatured;

  /// No description provided for @homeHotWeek.
  ///
  /// In en, this message translates to:
  /// **'Hot this week'**
  String get homeHotWeek;

  /// No description provided for @homeHotMonth.
  ///
  /// In en, this message translates to:
  /// **'Hot this month'**
  String get homeHotMonth;

  /// No description provided for @homeLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get homeLatest;

  /// No description provided for @homeFeedPick.
  ///
  /// In en, this message translates to:
  /// **'Choose feed'**
  String get homeFeedPick;

  /// No description provided for @sortFixedHot.
  ///
  /// In en, this message translates to:
  /// **'Hot lists are already ordered by views'**
  String get sortFixedHot;

  /// No description provided for @actionsPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get actionsPlayNow;

  /// No description provided for @actionsPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get actionsPlayNext;

  /// No description provided for @actionsViewCircle.
  ///
  /// In en, this message translates to:
  /// **'View circle'**
  String get actionsViewCircle;

  /// No description provided for @actionsViewCv.
  ///
  /// In en, this message translates to:
  /// **'View CV'**
  String get actionsViewCv;

  /// No description provided for @actionsViewTags.
  ///
  /// In en, this message translates to:
  /// **'View tags…'**
  String get actionsViewTags;

  /// No description provided for @actionsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionsShare;

  /// No description provided for @actionsOpenWeb.
  ///
  /// In en, this message translates to:
  /// **'Open on web'**
  String get actionsOpenWeb;

  /// No description provided for @accentSystem.
  ///
  /// In en, this message translates to:
  /// **'From wallpaper'**
  String get accentSystem;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @detailDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get detailDownload;

  /// No description provided for @queueAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get queueAdded;

  /// No description provided for @queueNext.
  ///
  /// In en, this message translates to:
  /// **'Plays next'**
  String get queueNext;

  /// No description provided for @actionsRemoveFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get actionsRemoveFromHistory;

  /// No description provided for @libraryStars.
  ///
  /// In en, this message translates to:
  /// **'{n} stars'**
  String libraryStars(Object n);

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify you\'re human'**
  String get challengeTitle;

  /// No description provided for @challengeHint.
  ///
  /// In en, this message translates to:
  /// **'The site wants a captcha. Pass the check in the WebView and it loads again.'**
  String get challengeHint;

  /// No description provided for @challengeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open WebView'**
  String get challengeOpen;
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
