// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabsHome => 'Discover';

  @override
  String get tabsSearch => 'Search';

  @override
  String get tabsLibrary => 'Library';

  @override
  String get tabsSettings => 'Settings';

  @override
  String get feedLatest => 'All';

  @override
  String get feedRequested => 'Requested';

  @override
  String get feedManiax => 'R18';

  @override
  String get sortHeading => 'Sort';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortTitle => 'Title A→Z';

  @override
  String get sortPopular => 'Popular';

  @override
  String get sortPopularWeek => 'Week';

  @override
  String get sortPopularMonth => 'Month';

  @override
  String get sortPopularYear => 'Year';

  @override
  String get sortPopularAll => 'All time';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get listErrorTitle => 'Couldn\'t load';

  @override
  String get listErrorHint => 'Check your connection and try again.';

  @override
  String get listEmpty => 'No results';

  @override
  String get listLoadMore => 'Load more';

  @override
  String get listRefreshFailed => 'Couldn\'t refresh. Pull down to try again.';

  @override
  String get searchPlaceholder => 'Title, CV, RJ code…';

  @override
  String get searchFilterPlaceholder => 'Filter list…';

  @override
  String get searchModeKeyword => 'Keyword';

  @override
  String get searchModeTags => 'Tags';

  @override
  String get searchModeCv => 'Voice actors';

  @override
  String get searchHint => 'Search by title, CV or RJ code';

  @override
  String get searchHintDescription =>
      'Press search on the keyboard to see results.';

  @override
  String searchWorks(Object count) {
    return '$count works';
  }

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClearHistory => 'Clear';

  @override
  String searchRemoveHistory(Object q) {
    return 'Remove \"$q\" from history';
  }

  @override
  String searchInAll(Object q) {
    return 'Search \"$q\" in all works';
  }

  @override
  String get detailLoadFailed => 'Couldn\'t load this work';

  @override
  String get detailNotFound => 'Work not found';

  @override
  String get detailPlay => 'Play';

  @override
  String detailResume(Object time) {
    return 'Resume · $time';
  }

  @override
  String get detailAddToQueue => 'Add to queue';

  @override
  String get detailNoStream => 'This work has no audio yet.';

  @override
  String get detailTags => 'Tags';

  @override
  String get detailImages => 'Images';

  @override
  String detailChapters(Object count) {
    return 'Chapters · $count';
  }

  @override
  String get detailFavorite => 'Favorite';

  @override
  String get detailUnfavorite => 'Remove favorite';

  @override
  String detailRate(Object n) {
    return 'Rate $n stars';
  }

  @override
  String detailOpenImage(Object n) {
    return 'View image $n';
  }

  @override
  String get playerNowPlaying => 'Now playing';

  @override
  String get playerClose => 'Close player';

  @override
  String get playerNothing => 'Nothing playing';

  @override
  String get playerError => 'Playback failed. Check your connection and retry.';

  @override
  String get playerErrorShort => 'Playback failed';

  @override
  String get playerRetry => 'Retry playback';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerPreviousChapter => 'Previous chapter';

  @override
  String get playerNextChapter => 'Next chapter';

  @override
  String get playerBack15 => 'Back 15 seconds';

  @override
  String get playerForward30 => 'Forward 30 seconds';

  @override
  String playerSpeed(Object rate) {
    return 'Speed ${rate}x';
  }

  @override
  String get speedTitle => 'Playback speed';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerShuffleOff => 'Turn off shuffle';

  @override
  String get playerRepeatOff => 'Repeat: off';

  @override
  String get playerRepeatAll => 'Repeat: queue';

  @override
  String get playerRepeatOne => 'Repeat: one';

  @override
  String get playerPosition => 'Playback position';

  @override
  String playerOpen(Object title) {
    return 'Open player: $title';
  }

  @override
  String get playerChapters => 'Chapters';

  @override
  String get playerQueue => 'Queue';

  @override
  String get playerMore => 'More';

  @override
  String get playerStop => 'Stop playback';

  @override
  String moreQueueCount(Object count) {
    return '$count items';
  }

  @override
  String get moreOpenWork => 'Open work page';

  @override
  String queueRemove(Object title) {
    return 'Remove $title from queue';
  }

  @override
  String get sleepTitle => 'Sleep timer';

  @override
  String sleepMinutes(Object n) {
    return '$n min';
  }

  @override
  String get sleepChapterEnd => 'End of chapter';

  @override
  String get sleepWorkEnd => 'End of work';

  @override
  String get sleepOff => 'Turn off timer';

  @override
  String get sleepByMinutes => 'Minutes';

  @override
  String get sleepByContent => 'By content';

  @override
  String sleepStopsAt(Object time) {
    return 'Stops at $time';
  }

  @override
  String sleepExtend(Object n) {
    return '+$n min';
  }

  @override
  String get sleepChangeTo => 'Change to';

  @override
  String get sleepRemainingChapter => 'End of chapter';

  @override
  String get sleepRemainingWork => 'End of work';

  @override
  String sleepActive(Object label) {
    return 'Sleep timer: $label';
  }

  @override
  String get libraryFavorites => 'Favorites';

  @override
  String get libraryHistory => 'History';

  @override
  String get libraryRated => 'Rated';

  @override
  String get libraryClear => 'Clear';

  @override
  String get libraryClearConfirm => 'Clear listening history?';

  @override
  String get libraryEmptyFavorites => 'No favorites yet';

  @override
  String get libraryEmptyFavoritesHint => 'Tap ♥ on a work to save it.';

  @override
  String get libraryEmptyHistory => 'Nothing played yet';

  @override
  String get libraryEmptyRated => 'No rated works yet';

  @override
  String get libraryEmptyRatedHint => 'Pick stars on a work page.';

  @override
  String get libraryGroupToday => 'Today';

  @override
  String get libraryGroupYesterday => 'Yesterday';

  @override
  String get libraryGroupWeek => 'This week';

  @override
  String get libraryGroupOlder => 'Earlier';

  @override
  String libraryInProgress(Object time) {
    return 'In progress · $time';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsPrivacy => 'Privacy mode';

  @override
  String get settingsPrivacyHint =>
      'Blur covers, including on the lock screen.';

  @override
  String get settingsLock => 'App lock';

  @override
  String get settingsLockHint =>
      'Require Face ID, fingerprint or passcode when reopening.';

  @override
  String layoutSwitch(Object name) {
    return 'Switch layout: $name';
  }

  @override
  String get layoutGrid => 'Large grid';

  @override
  String get layoutCompact => 'Compact grid';

  @override
  String get layoutList => 'List';

  @override
  String get settingsAccent => 'Accent colour';

  @override
  String get accentLavender => 'Lavender';

  @override
  String get accentSakura => 'Sakura';

  @override
  String get accentOcean => 'Ocean';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsClearImageCache => 'Clear image cache';

  @override
  String get settingsReloadTags => 'Reload tag & voice actor lists';

  @override
  String get settingsClearHistory => 'Clear listening history';

  @override
  String get settingsDone => 'Done';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsSource => 'Source code';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockPrompt => 'Unlock nihonkoe';

  @override
  String get lockEnablePrompt => 'Confirm enabling app lock';

  @override
  String get lockDisablePrompt => 'Confirm disabling app lock';

  @override
  String get lockUnavailableTitle => 'Can\'t enable app lock';

  @override
  String get lockUnavailable =>
      'Set up Face ID, a fingerprint or a passcode on this device first.';

  @override
  String get lockFailedTitle => 'Couldn\'t authenticate';

  @override
  String get lockLockout =>
      'Too many attempts. Unlock your device, then try again.';

  @override
  String get homeFeatured => 'Featured';

  @override
  String get homeHotWeek => 'Hot this week';

  @override
  String get homeHotMonth => 'Hot this month';

  @override
  String get homeLatest => 'Latest';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get actionsPlayNow => 'Play now';

  @override
  String get actionsPlayNext => 'Play next';

  @override
  String get actionsViewCircle => 'View circle';

  @override
  String get actionsViewCv => 'View CV';

  @override
  String get actionsViewTags => 'View tags…';

  @override
  String get actionsShare => 'Share';

  @override
  String get actionsOpenWeb => 'Open on web';

  @override
  String get accentSystem => 'From wallpaper';

  @override
  String get languageSystem => 'System';

  @override
  String get detailDownload => 'Download';

  @override
  String get queueAdded => 'Added to queue';

  @override
  String get queueNext => 'Plays next';

  @override
  String get actionsRemoveFromHistory => 'Remove from history';

  @override
  String libraryStars(Object n) {
    return '$n stars';
  }

  @override
  String get galleryReveal => 'Tap to show';
}
