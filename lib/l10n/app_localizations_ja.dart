// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tabsHome => '発見';

  @override
  String get tabsSearch => '検索';

  @override
  String get tabsLibrary => 'ライブラリ';

  @override
  String get tabsSettings => '設定';

  @override
  String get feedLatest => 'すべて';

  @override
  String get feedRequested => 'リクエスト';

  @override
  String get feedManiax => 'R18';

  @override
  String get sortHeading => '並べ替え';

  @override
  String get sortNewest => '新しい順';

  @override
  String get sortOldest => '古い順';

  @override
  String get sortTitle => 'タイトル順';

  @override
  String get sortPopular => '人気';

  @override
  String get sortPopularWeek => '週間';

  @override
  String get sortPopularMonth => '月間';

  @override
  String get sortPopularYear => '年間';

  @override
  String get sortPopularAll => '全期間';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get listErrorTitle => '読み込めませんでした';

  @override
  String get listErrorHint => '接続を確認して再試行してください。';

  @override
  String get listEmpty => '結果がありません';

  @override
  String get listLoadMore => 'さらに読み込む';

  @override
  String get listRefreshFailed => '更新できませんでした。下に引いて再試行してください。';

  @override
  String get searchPlaceholder => 'タイトル・声優・RJ番号…';

  @override
  String get searchFilterPlaceholder => '絞り込む…';

  @override
  String get searchModeKeyword => 'キーワード';

  @override
  String get searchModeTags => 'タグ';

  @override
  String get searchModeCv => '声優';

  @override
  String get searchHint => 'タイトル・声優・RJ番号で検索';

  @override
  String get searchHintDescription => 'キーボードの検索を押すと結果が表示されます。';

  @override
  String searchWorks(Object count) {
    return '$count作品';
  }

  @override
  String get searchRecent => '最近の検索';

  @override
  String get searchClearHistory => 'すべて消去';

  @override
  String searchRemoveHistory(Object q) {
    return '「$q」を履歴から削除';
  }

  @override
  String searchInAll(Object q) {
    return 'すべての作品から「$q」を検索';
  }

  @override
  String get detailLoadFailed => '作品を読み込めませんでした';

  @override
  String get detailNotFound => '作品が見つかりません';

  @override
  String get detailPlay => '再生';

  @override
  String detailResume(Object time) {
    return '続きから · $time';
  }

  @override
  String get detailAddToQueue => 'キューに追加';

  @override
  String get detailNoStream => 'この作品にはまだ音声がありません。';

  @override
  String get detailTags => 'タグ';

  @override
  String get detailImages => '画像';

  @override
  String detailChapters(Object count) {
    return 'チャプター · $count';
  }

  @override
  String get detailFavorite => 'お気に入り';

  @override
  String get detailUnfavorite => 'お気に入り解除';

  @override
  String detailRate(Object n) {
    return '$nつ星で評価';
  }

  @override
  String detailOpenImage(Object n) {
    return '画像$nを表示';
  }

  @override
  String get playerNowPlaying => '再生中';

  @override
  String get playerClose => 'プレーヤーを閉じる';

  @override
  String get playerNothing => '再生中の作品はありません';

  @override
  String get playerError => '再生できませんでした。接続を確認して再試行してください。';

  @override
  String get playerErrorShort => '再生できません';

  @override
  String get playerRetry => '再生をやり直す';

  @override
  String get playerPlay => '再生';

  @override
  String get playerPause => '一時停止';

  @override
  String get playerPreviousChapter => '前のチャプター';

  @override
  String get playerNextChapter => '次のチャプター';

  @override
  String get playerBack15 => '15秒戻る';

  @override
  String get playerForward30 => '30秒進む';

  @override
  String playerSpeed(Object rate) {
    return '速度 ${rate}x';
  }

  @override
  String get speedTitle => '再生速度';

  @override
  String get playerShuffle => 'シャッフル';

  @override
  String get playerShuffleOff => 'シャッフルをオフ';

  @override
  String get playerRepeatOff => 'リピート: オフ';

  @override
  String get playerRepeatAll => 'リピート: キュー';

  @override
  String get playerRepeatOne => 'リピート: 1作品';

  @override
  String get playerPosition => '再生位置';

  @override
  String playerOpen(Object title) {
    return 'プレーヤーを開く: $title';
  }

  @override
  String get playerChapters => 'チャプター';

  @override
  String get playerQueue => 'キュー';

  @override
  String get playerMore => 'その他';

  @override
  String get playerStop => '再生を停止';

  @override
  String moreQueueCount(Object count) {
    return '$count件';
  }

  @override
  String get moreOpenWork => '作品ページを開く';

  @override
  String queueRemove(Object title) {
    return '$title をキューから削除';
  }

  @override
  String get sleepTitle => 'スリープタイマー';

  @override
  String sleepMinutes(Object n) {
    return '$n分';
  }

  @override
  String get sleepChapterEnd => 'このチャプターの終わり';

  @override
  String get sleepWorkEnd => 'この作品の終わり';

  @override
  String get sleepOff => 'タイマーをオフ';

  @override
  String get sleepByMinutes => '分で指定';

  @override
  String get sleepByContent => '内容で指定';

  @override
  String sleepStopsAt(Object time) {
    return '$time に停止';
  }

  @override
  String sleepExtend(Object n) {
    return '+$n分';
  }

  @override
  String get sleepChangeTo => '変更';

  @override
  String get sleepRemainingChapter => 'チャプター終了';

  @override
  String get sleepRemainingWork => '作品終了';

  @override
  String sleepActive(Object label) {
    return 'スリープタイマー: $label';
  }

  @override
  String get libraryFavorites => 'お気に入り';

  @override
  String get libraryHistory => '履歴';

  @override
  String get libraryRated => '評価済み';

  @override
  String get libraryClear => '消去';

  @override
  String get libraryClearConfirm => '再生履歴を消去しますか？';

  @override
  String get libraryEmptyFavorites => 'お気に入りはまだありません';

  @override
  String get libraryEmptyFavoritesHint => '作品ページの♥で保存できます。';

  @override
  String get libraryEmptyHistory => 'まだ何も再生していません';

  @override
  String get libraryEmptyRated => '評価した作品はまだありません';

  @override
  String get libraryEmptyRatedHint => '作品ページで星を選んでください。';

  @override
  String get libraryGroupToday => '今日';

  @override
  String get libraryGroupYesterday => '昨日';

  @override
  String get libraryGroupWeek => '今週';

  @override
  String get libraryGroupOlder => 'それ以前';

  @override
  String libraryInProgress(Object time) {
    return '途中 · $time';
  }

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsPrivacySection => 'プライバシー';

  @override
  String get settingsPrivacy => 'プライバシーモード';

  @override
  String get settingsPrivacyHint => 'ロック画面を含め、カバー画像をぼかします。';

  @override
  String get settingsLock => 'アプリロック';

  @override
  String get settingsLockHint => '再度開くときに Face ID・指紋・パスコードを要求します。';

  @override
  String layoutSwitch(Object name) {
    return '表示切替: $name';
  }

  @override
  String get layoutGrid => '大きいグリッド';

  @override
  String get layoutCompact => '小さいグリッド';

  @override
  String get layoutList => 'リスト';

  @override
  String get settingsAccent => 'アクセントカラー';

  @override
  String get accentLavender => 'ラベンダー';

  @override
  String get accentSakura => 'さくら';

  @override
  String get accentOcean => 'オーシャン';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsStorage => 'ストレージ';

  @override
  String get settingsClearImageCache => '画像キャッシュを削除';

  @override
  String get settingsReloadTags => 'タグと声優の一覧を再読み込み';

  @override
  String get settingsClearHistory => '再生履歴を削除';

  @override
  String get settingsDone => '完了しました';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsSource => 'ソースコード';

  @override
  String get lockUnlock => 'ロック解除';

  @override
  String get lockPrompt => 'nihonkoe のロックを解除';

  @override
  String get lockEnablePrompt => 'アプリロックの有効化を確認';

  @override
  String get lockDisablePrompt => 'アプリロックの無効化を確認';

  @override
  String get lockUnavailableTitle => 'アプリロックを有効にできません';

  @override
  String get lockUnavailable => '端末に Face ID・指紋・パスコードを設定してください。';

  @override
  String get lockFailedTitle => '認証できませんでした';

  @override
  String get lockLockout => '試行回数が多すぎます。端末のロックを解除してから再試行してください。';

  @override
  String get homeFeatured => '注目';

  @override
  String get homeHotWeek => '今週の人気';

  @override
  String get homeHotMonth => '今月の人気';

  @override
  String get homeLatest => '新着';

  @override
  String get commonSeeAll => 'すべて表示';

  @override
  String get actionsPlayNow => '今すぐ再生';

  @override
  String get actionsPlayNext => '次に再生';

  @override
  String get actionsViewCircle => 'サークルを見る';

  @override
  String get actionsViewCv => 'CVを見る';

  @override
  String get actionsViewTags => 'タグを見る…';

  @override
  String get actionsShare => '共有';

  @override
  String get actionsOpenWeb => 'ウェブで開く';

  @override
  String get accentSystem => '壁紙から';

  @override
  String get languageSystem => 'システム';

  @override
  String get detailDownload => 'ダウンロード';

  @override
  String get queueAdded => 'キューに追加しました';

  @override
  String get queueNext => '次に再生します';

  @override
  String get actionsRemoveFromHistory => '履歴から削除';
}
