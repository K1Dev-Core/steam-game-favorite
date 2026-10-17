const sourceFiles = [
  ['lib/main.dart','แอปเริ่มที่ main(); ตั้งค่า Theme/Firebase, AuthGate, แท็บ, เกมโปรด, navigation, รายละเอียดเกม และ GameStatisticsPage','จุดไล่โค้ด: main() → AuthGate → MainPage → _cloudGameList() → _openDetail() → GameDetailPage → GameStatisticsPage'],
  ['lib/pages/auth_page.dart','หน้าสมัคร/ล็อกอิน/ออกจากระบบ เชื่อม Firebase Authentication และจัดการ validation/loading/error','ดู Form, validator, signInWithEmailAndPassword และ createUserWithEmailAndPassword'],
  ['lib/pages/game_editor_page.dart','แบบฟอร์มเพิ่ม/แก้เกม สร้าง SteamGame แล้วเรียก GameRepository.saveGame','ดู TextEditingController, FormState.validate, การเติมค่าเดิม และปุ่มบันทึก'],
  ['lib/pages/recommended_games_page.dart','เรียกเกมแนะนำจาก API พร้อม loading/error/empty/data และนำเกมไปเพิ่มในคลัง','ดู FutureBuilder, retry, Navigator.push และการส่งเกมผ่าน constructor'],
  ['lib/pages/community_page.dart','อ่านคอมเมนต์ API และแสดงการ์ด/รูปโปรไฟล์ พร้อม reload และ error state','ดู FutureBuilder<List<GameComment>> และ _reload()'],
  ['lib/pages/backlog_page.dart','CRUD เกมที่อยากเล่นบน storage ภายในเครื่อง พร้อมกรองสถานะและ empty state','ดู _load, ฟอร์ม bottom sheet, save/delete และ confirm dialog'],
  ['lib/repositories/game_repository.dart','สัญญากลางของเกมโปรด: watchGames, saveGame, deleteGame','UI พึ่ง interface นี้ แทนการผูกตรงกับ API/database'],
  ['lib/services/firestore_game_repository.dart','ประสาน Firebase Auth, Favorites API และ local DB/cache สำหรับเกมโปรด','ดู _userId/_idToken, watchGames และลำดับ save/delete'],
  ['lib/services/favorites_api_service.dart','REST CRUD เกมโปรดที่ต้องแนบ Firebase ID token','ดู Authorization Bearer, method GET/POST/PUT/DELETE, parse response/status'],
  ['lib/services/api_service.dart','โหลดเกมค้นพบและคอมเมนต์ผ่าน GET; ตรวจ URL, timeout และ JSON','ดู fetchGames, fetchComments และ _getList'],
  ['lib/services/diary_api_service.dart','REST CRUD สำหรับรีวิวเกมในกล่อง API ตามรหัสนักศึกษา','ดู defaultEndpoint, getDiaries/createDiary/updateDiary/deleteDiary และ _send'],
  ['lib/data/game_database.dart','ประกาศ GameDatabase และเลือก implementation ด้วย conditional import','ดู interface; native ใช้ sqflite, web ใช้ adapter, platform อื่นใช้ stub'],
  ['lib/data/game_database_sqflite.dart','สร้าง/อัปเกรดฐานข้อมูล SQLite และอ่าน/เขียน game cache กับ backlog','ดู openDatabase, onCreate/onUpgrade, query, transaction และ whereArgs'],
  ['lib/data/game_database_web.dart','adapter ของ browser ใช้ SharedPreferences/JSON แทน sqflite','ดู key แยกเจ้าของและการ serialize รายการ backlog'],
  ['lib/data/game_database_stub.dart','fallback ที่แจ้ง UnsupportedError เมื่อ platform ไม่มี storage adapter','ทำให้ conditional import มี implementation ครบ'],
  ['lib/models/steam_game.dart','model เกมโปรดและการแปลง Firestore/REST/SQLite','ดู constructor, copyWith, toMap/fromMap, toJson/fromJson, toFirestore/fromFirestore'],
  ['lib/models/recommended_game.dart','model เกมที่ API แนะนำ และแปลงเป็น draft สำหรับฟอร์ม','ดู fromJson และ toDraft'],
  ['lib/models/game_comment.dart','model คอมเมนต์ชุมชนพร้อม validation ข้อมูล JSON','ดู fromJson และ imageUrl ที่สร้างจาก appId'],
  ['lib/models/game_review.dart','model รีวิวส่วนตัว: id, title, content, mood/rating, date, appId','ดู id/_id compatibility และ toJson'],
  ['lib/models/backlog_game.dart','model local backlog และ toMap/fromMap สำหรับ SQLite/web JSON','ดู field status, genre, appId และ createdAt'],
  ['lib/widgets/game_review_section.dart','UI รีวิวแทรกในหน้ารายละเอียดเกมเดียว มีโหลด/เพิ่ม/แก้/ลบ','ดู _load → match appId, _editReview → POST/PUT, _deleteReview → DELETE, dialog validation'],
  ['lib/widgets/game_artwork.dart','แสดงภาพเกมโดยมี loading/error/placeholder fallback','ดู Image loadingBuilder/errorBuilder และรูป local/remote'],
  ['lib/widgets/profile_avatar.dart','แสดงรูป avatar และ fallback เมื่อโหลดภาพไม่ได้','ดู identity seed และ avatar image fallback'],
  ['lib/widgets/ios_navigation_bar.dart','AppBar/navigation bar หน้าตา iOS แบบใช้ซ้ำ','ดู leading/actions, alignment และ safe area'],
  ['lib/firebase_options.dart','ตัวเลือก Firebase client ตาม platform ที่ FlutterFire สร้าง','ใช้ DefaultFirebaseOptions.currentPlatform; ไม่ใส่ password หรือ service-account key'],
  ['test/game_review_test.dart','ทดสอบหน้ารีวิวด้วย MockClient โดยจำลอง server CRUD','ตรวจเพิ่ม/อ่าน/แก้/ลบโดยไม่เขียนข้อมูลจริง'],
  ['test/api_test.dart','ทดสอบ API parsing, error และหน้า Discover/Community','ดู MockClient, invalid JSON/status, loading/error/retry'],
  ['test/backlog_page_test.dart','ทดสอบ CRUD/filter ของ backlog ด้วย fake in-memory GameDatabase','พิสูจน์ state และ UI โดยไม่ต้องเปิด SQLite จริง'],
  ['test/lab2_test.dart','ทดสอบเกมโปรด CRUD, navigation และสถิติ','ดู fake repository และ interaction tests'],
  ['test/widget_test.dart','smoke test widget/app เบื้องต้น','ใช้ยืนยันว่า widget เริ่มสร้างได้ใน environment ของ test'],
  ['android/app/src/main/AndroidManifest.xml','ชื่อแอป, launcher activity และสิทธิ์อินเทอร์เน็ตฝั่ง Android','API ที่เพิ่มใช้ HTTPS จึงไม่ต้องเปิด usesCleartextTraffic'],
  ['android/app/src/main/kotlin/com/example/mydiary_app/MainActivity.kt','entry point native Android ที่ต่อ Flutter engine','โดยปกติไม่ต้องแก้ business logic Flutter ในไฟล์นี้'],
  ['android/app/build.gradle.kts','application id, SDK/build settings และ Firebase plugin ของ Android','ตั้งค่าที่จำเป็นต่อการ build APK'],
  ['ios/Runner/AppDelegate.swift','entry point native iOS และ register Flutter plugins','เชื่อม UIKit/Flutter lifecycle ก่อนเริ่ม Dart app'],
  ['ios/Runner/Info.plist','ชื่อ/สิทธิ์/metadata ของ iOS app','ตรวจ usage description ก่อนใช้ camera/photo picker'],
  ['ios/Runner.xcodeproj/project.pbxproj','การตั้งค่า target, signing, bundle identifier และ build configuration','Xcode ใช้ไฟล์นี้ตอน build/run บนอุปกรณ์'],
];

const list = document.querySelector('#fileList');
const search = document.querySelector('#fileSearch');
const status = document.querySelector('#fileStatus');

function escapeHtml(value) {
  return value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

function renderFiles(query = '') {
  const term = query.trim().toLowerCase();
  const matches = sourceFiles.filter(([path, summary, detail]) =>
    `${path} ${summary} ${detail}`.toLowerCase().includes(term),
  );
  list.innerHTML = '';
  for (const [path, summary, detail] of matches) {
    const card = document.createElement('article');
    card.className = 'file-card';
    const href = `../${path}`;
    card.innerHTML = `
      <div class="file-head">
        <details data-source="${path}">
          <summary><b>${path}</b><span>${summary}<br><strong>จุดอธิบายในไฟล์:</strong> ${detail}</span></summary>
          <div class="file-content"><p class="status">โหลดโค้ดต้นฉบับ…</p><pre><code></code></pre></div>
        </details>
        <div class="file-actions"><a href="${href}" download>ดาวน์โหลดไฟล์</a><button type="button" data-copy="${path}">คัดลอกโค้ด</button></div>
      </div>`;
    list.append(card);
  }
  status.textContent = `${matches.length} จาก ${sourceFiles.length} ไฟล์ในดัชนี`;
  list.querySelectorAll('details[data-source]').forEach((details) => {
    details.addEventListener('toggle', async () => {
      if (!details.open || details.dataset.loaded === 'true') return;
      const path = details.dataset.source;
      const codeBox = details.querySelector('code');
      const message = details.querySelector('.file-content .status');
      try {
        const response = await fetch(`../${path}`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        codeBox.textContent = await response.text();
        message.textContent = `source จริง · ${path}`;
        details.dataset.loaded = 'true';
      } catch (error) {
        message.textContent = `อ่านไฟล์ไม่ได้ (${error.message}) — เปิดผ่านเว็บเซิร์ฟเวอร์ที่ root เป็นโฟลเดอร์โปรเจกต์`;
      }
    });
  });
  list.querySelectorAll('button[data-copy]').forEach((button) => {
    button.addEventListener('click', async () => {
      const path = button.dataset.copy;
      try {
        const response = await fetch(`../${path}`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        await navigator.clipboard.writeText(await response.text());
        button.textContent = 'คัดลอกแล้ว ✓';
        setTimeout(() => { button.textContent = 'คัดลอกโค้ด'; }, 1600);
      } catch (_) {
        button.textContent = 'เปิดไฟล์แล้วคัดลอก';
        window.open(`../${path}`, '_blank', 'noopener');
        setTimeout(() => { button.textContent = 'คัดลอกโค้ด'; }, 1800);
      }
    });
  });
}

renderFiles();
search.addEventListener('input', () => renderFiles(search.value));
