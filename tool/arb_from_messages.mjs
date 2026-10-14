// One-off: builds lib/l10n/app_{vi,en,ja}.arb from the Expo app's messages plus keys new in the Flutter app.
// Usage: node tool/arb_from_messages.mjs /home/minh/Documents/pet/japaneseasmr/src/i18n/messages.ts lib/l10n
import { writeFileSync } from 'node:fs';

const [, , messagesPath, outDir] = process.argv;
const { MESSAGES } = await import(messagesPath);

const EXTRA = {
  vi: {
    'home.featured': 'Nổi bật', 'home.hotWeek': 'Hot tuần này', 'home.hotMonth': 'Hot tháng này', 'home.latest': 'Mới nhất',
    'common.seeAll': 'Xem tất cả', 'actions.playNow': 'Phát ngay', 'actions.playNext': 'Phát tiếp theo',
    'actions.viewCircle': 'Xem circle', 'actions.viewCv': 'Xem CV', 'actions.viewTags': 'Xem thẻ…',
    'actions.share': 'Chia sẻ', 'actions.openWeb': 'Mở trên web', 'accent.system': 'Theo hình nền',
    'language.system': 'Theo hệ thống', 'detail.download': 'Tải về', 'library.comingSoon': 'Thư viện sẽ có ở bản sau.',
  },
  en: {
    'home.featured': 'Featured', 'home.hotWeek': 'Hot this week', 'home.hotMonth': 'Hot this month', 'home.latest': 'Latest',
    'common.seeAll': 'See all', 'actions.playNow': 'Play now', 'actions.playNext': 'Play next',
    'actions.viewCircle': 'View circle', 'actions.viewCv': 'View CV', 'actions.viewTags': 'View tags…',
    'actions.share': 'Share', 'actions.openWeb': 'Open on web', 'accent.system': 'From wallpaper',
    'language.system': 'System', 'detail.download': 'Download', 'library.comingSoon': 'The library arrives in a later build.',
  },
  ja: {
    'home.featured': '注目', 'home.hotWeek': '今週の人気', 'home.hotMonth': '今月の人気', 'home.latest': '新着',
    'common.seeAll': 'すべて表示', 'actions.playNow': '今すぐ再生', 'actions.playNext': '次に再生',
    'actions.viewCircle': 'サークルを見る', 'actions.viewCv': 'CVを見る', 'actions.viewTags': 'タグを見る…',
    'actions.share': '共有', 'actions.openWeb': 'ウェブで開く', 'accent.system': '壁紙から',
    'language.system': 'システム', 'detail.download': 'ダウンロード', 'library.comingSoon': 'ライブラリは今後のビルドで追加されます。',
  },
};

const camel = (key) => key.split(/[.-]/).map((part, i) => (i ? part[0].toUpperCase() + part.slice(1) : part)).join('');

for (const lang of ['vi', 'en', 'ja']) {
  const arb = { '@@locale': lang };
  for (const [key, value] of Object.entries({ ...MESSAGES[lang], ...EXTRA[lang] })) {
    const id = camel(key);
    if (id in arb) throw new Error(`duplicate ARB key ${id} (${key})`);
    arb[id] = value;
    const placeholders = [...value.matchAll(/\{(\w+)\}/g)].map((m) => m[1]);
    if (lang === 'en' && placeholders.length) arb[`@${id}`] = { placeholders: Object.fromEntries(placeholders.map((p) => [p, {}])) };
  }
  writeFileSync(`${outDir}/app_${lang}.arb`, JSON.stringify(arb, null, 2) + '\n');
}
