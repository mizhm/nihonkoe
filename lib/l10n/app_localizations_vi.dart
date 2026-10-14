// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get tabsHome => 'Khám phá';

  @override
  String get tabsSearch => 'Tìm kiếm';

  @override
  String get tabsLibrary => 'Thư viện';

  @override
  String get tabsSettings => 'Cài đặt';

  @override
  String get feedLatest => 'Tất cả';

  @override
  String get feedRequested => 'Được yêu cầu';

  @override
  String get feedManiax => 'R18';

  @override
  String get sortHeading => 'Sắp xếp';

  @override
  String get sortNewest => 'Mới nhất';

  @override
  String get sortOldest => 'Cũ nhất';

  @override
  String get sortTitle => 'Tên A→Z';

  @override
  String get sortPopular => 'Phổ biến';

  @override
  String get sortPopularWeek => 'Tuần';

  @override
  String get sortPopularMonth => 'Tháng';

  @override
  String get sortPopularYear => 'Năm';

  @override
  String get sortPopularAll => 'Mọi lúc';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonClose => 'Đóng';

  @override
  String get listErrorTitle => 'Không tải được dữ liệu';

  @override
  String get listErrorHint => 'Kiểm tra kết nối mạng rồi thử lại.';

  @override
  String get listEmpty => 'Không có kết quả';

  @override
  String get listLoadMore => 'Tải tiếp';

  @override
  String get listRefreshFailed => 'Không làm mới được. Kéo xuống để thử lại.';

  @override
  String get searchPlaceholder => 'Tên, CV, mã RJ…';

  @override
  String get searchFilterPlaceholder => 'Lọc danh sách…';

  @override
  String get searchModeKeyword => 'Từ khoá';

  @override
  String get searchModeTags => 'Thẻ';

  @override
  String get searchModeCv => 'Diễn viên';

  @override
  String get searchHint => 'Tìm theo tên, CV hoặc mã RJ';

  @override
  String get searchHintDescription =>
      'Nhấn tìm kiếm trên bàn phím để xem kết quả.';

  @override
  String searchWorks(Object count) {
    return '$count tác phẩm';
  }

  @override
  String get searchRecent => 'Tìm kiếm gần đây';

  @override
  String get searchClearHistory => 'Xoá hết';

  @override
  String searchRemoveHistory(Object q) {
    return 'Xoá \"$q\" khỏi lịch sử';
  }

  @override
  String searchInAll(Object q) {
    return 'Tìm \"$q\" trong tất cả tác phẩm';
  }

  @override
  String get detailLoadFailed => 'Không tải được tác phẩm';

  @override
  String get detailNotFound => 'Không tìm thấy tác phẩm';

  @override
  String get detailPlay => 'Phát';

  @override
  String detailResume(Object time) {
    return 'Tiếp tục · $time';
  }

  @override
  String get detailAddToQueue => 'Thêm vào hàng đợi';

  @override
  String get detailNoStream => 'Tác phẩm này chưa có bản nghe.';

  @override
  String get detailTags => 'Thẻ';

  @override
  String get detailImages => 'Hình ảnh';

  @override
  String detailChapters(Object count) {
    return 'Chương · $count';
  }

  @override
  String get detailFavorite => 'Yêu thích';

  @override
  String get detailUnfavorite => 'Bỏ yêu thích';

  @override
  String detailRate(Object n) {
    return 'Đánh giá $n sao';
  }

  @override
  String detailOpenImage(Object n) {
    return 'Xem ảnh $n';
  }

  @override
  String get playerNowPlaying => 'Đang phát';

  @override
  String get playerClose => 'Đóng trình phát';

  @override
  String get playerNothing => 'Chưa phát gì';

  @override
  String get playerError => 'Không phát được. Kiểm tra mạng rồi thử lại.';

  @override
  String get playerErrorShort => 'Không phát được';

  @override
  String get playerRetry => 'Thử phát lại';

  @override
  String get playerPlay => 'Phát';

  @override
  String get playerPause => 'Tạm dừng';

  @override
  String get playerPreviousChapter => 'Chương trước';

  @override
  String get playerNextChapter => 'Chương tiếp';

  @override
  String get playerBack15 => 'Lùi 15 giây';

  @override
  String get playerForward30 => 'Tới 30 giây';

  @override
  String playerSpeed(Object rate) {
    return 'Tốc độ ${rate}x';
  }

  @override
  String get speedTitle => 'Tốc độ phát';

  @override
  String get playerShuffle => 'Trộn bài';

  @override
  String get playerShuffleOff => 'Tắt trộn bài';

  @override
  String get playerRepeatOff => 'Lặp: tắt';

  @override
  String get playerRepeatAll => 'Lặp: cả hàng đợi';

  @override
  String get playerRepeatOne => 'Lặp: một bài';

  @override
  String get playerPosition => 'Vị trí phát';

  @override
  String playerOpen(Object title) {
    return 'Mở trình phát: $title';
  }

  @override
  String get playerChapters => 'Chương';

  @override
  String get playerQueue => 'Hàng đợi';

  @override
  String get playerMore => 'Thêm';

  @override
  String get playerStop => 'Dừng phát';

  @override
  String moreQueueCount(Object count) {
    return '$count bài';
  }

  @override
  String get moreOpenWork => 'Mở trang tác phẩm';

  @override
  String queueRemove(Object title) {
    return 'Xoá $title khỏi hàng đợi';
  }

  @override
  String get sleepTitle => 'Hẹn giờ tắt';

  @override
  String sleepMinutes(Object n) {
    return '$n phút';
  }

  @override
  String get sleepChapterEnd => 'Hết chương này';

  @override
  String get sleepWorkEnd => 'Hết tác phẩm này';

  @override
  String get sleepOff => 'Tắt hẹn giờ';

  @override
  String get sleepByMinutes => 'Theo phút';

  @override
  String get sleepByContent => 'Theo nội dung';

  @override
  String sleepStopsAt(Object time) {
    return 'Sẽ dừng lúc $time';
  }

  @override
  String sleepExtend(Object n) {
    return '+$n phút';
  }

  @override
  String get sleepChangeTo => 'Đổi sang';

  @override
  String get sleepRemainingChapter => 'Hết chương';

  @override
  String get sleepRemainingWork => 'Hết tác phẩm';

  @override
  String sleepActive(Object label) {
    return 'Hẹn giờ tắt: $label';
  }

  @override
  String get libraryFavorites => 'Yêu thích';

  @override
  String get libraryHistory => 'Lịch sử';

  @override
  String get libraryRated => 'Đã chấm';

  @override
  String get libraryClear => 'Xoá';

  @override
  String get libraryClearConfirm => 'Xoá lịch sử nghe?';

  @override
  String get libraryEmptyFavorites => 'Chưa có yêu thích';

  @override
  String get libraryEmptyFavoritesHint =>
      'Nhấn ♥ trong trang tác phẩm để lưu lại.';

  @override
  String get libraryEmptyHistory => 'Chưa nghe tác phẩm nào';

  @override
  String get libraryEmptyRated => 'Chưa chấm điểm tác phẩm nào';

  @override
  String get libraryEmptyRatedHint => 'Chọn số sao trong trang tác phẩm.';

  @override
  String get libraryGroupToday => 'Hôm nay';

  @override
  String get libraryGroupYesterday => 'Hôm qua';

  @override
  String get libraryGroupWeek => 'Tuần này';

  @override
  String get libraryGroupOlder => 'Cũ hơn';

  @override
  String libraryInProgress(Object time) {
    return 'Đang nghe dở · $time';
  }

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsPrivacySection => 'Riêng tư';

  @override
  String get settingsPrivacy => 'Chế độ riêng tư';

  @override
  String get settingsPrivacyHint =>
      'Làm mờ ảnh bìa và che nội dung khi chuyển ứng dụng.';

  @override
  String get settingsLock => 'Khoá ứng dụng';

  @override
  String get settingsLockHint =>
      'Yêu cầu Face ID, vân tay hoặc mật khẩu khi mở lại.';

  @override
  String layoutSwitch(Object name) {
    return 'Đổi kiểu hiển thị: $name';
  }

  @override
  String get layoutGrid => 'Lưới lớn';

  @override
  String get layoutCompact => 'Lưới nhỏ';

  @override
  String get layoutList => 'Danh sách';

  @override
  String get settingsAccent => 'Màu chủ đạo';

  @override
  String get accentLavender => 'Tím';

  @override
  String get accentSakura => 'Hồng sakura';

  @override
  String get accentOcean => 'Xanh biển';

  @override
  String get settingsTheme => 'Chủ đề';

  @override
  String get settingsStorage => 'Bộ nhớ';

  @override
  String get settingsClearImageCache => 'Xoá cache ảnh';

  @override
  String get settingsReloadTags => 'Tải lại danh sách thẻ và diễn viên';

  @override
  String get settingsClearHistory => 'Xoá lịch sử nghe';

  @override
  String get settingsDone => 'Đã xong';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsSource => 'Mã nguồn';

  @override
  String get lockUnlock => 'Mở khoá';

  @override
  String get lockPrompt => 'Mở khoá nihonkoe';

  @override
  String get lockEnablePrompt => 'Xác nhận bật khoá ứng dụng';

  @override
  String get lockDisablePrompt => 'Xác nhận tắt khoá ứng dụng';

  @override
  String get lockUnavailableTitle => 'Không thể bật khoá';

  @override
  String get lockUnavailable =>
      'Thiết bị chưa thiết lập Face ID, vân tay hoặc mật khẩu.';

  @override
  String get lockFailedTitle => 'Không thể xác thực';

  @override
  String get lockLockout =>
      'Thử sai quá nhiều lần. Hãy mở khoá thiết bị rồi thử lại.';

  @override
  String get homeFeatured => 'Nổi bật';

  @override
  String get homeHotWeek => 'Hot tuần này';

  @override
  String get homeHotMonth => 'Hot tháng này';

  @override
  String get homeLatest => 'Mới nhất';

  @override
  String get commonSeeAll => 'Xem tất cả';

  @override
  String get actionsPlayNow => 'Phát ngay';

  @override
  String get actionsPlayNext => 'Phát tiếp theo';

  @override
  String get actionsViewCircle => 'Xem circle';

  @override
  String get actionsViewCv => 'Xem CV';

  @override
  String get actionsViewTags => 'Xem thẻ…';

  @override
  String get actionsShare => 'Chia sẻ';

  @override
  String get actionsOpenWeb => 'Mở trên web';

  @override
  String get accentSystem => 'Theo hình nền';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get detailDownload => 'Tải về';

  @override
  String get libraryComingSoon => 'Thư viện sẽ có ở bản sau.';

  @override
  String get queueAdded => 'Đã thêm vào hàng đợi';

  @override
  String get queueNext => 'Sẽ phát tiếp theo';
}
