# HW3 — Steam Game Favorite

ต่อจากแอปเดิม: วชิรวิทย์ วงค์แสง 67011212055

## เว็บและ API ที่ deploy แล้ว

- เว็บ: https://steam-game-favorite-hw3.vercel.app
- API เกม: https://steam-games-hw3.vercel.app/api/games (37 เกม)
- API คอมเมนต์: https://steam-comments-hw3.vercel.app/api/comments (12 คอมเมนต์)
- แยกกันคนละ Vercel project โค้ดอยู่ `games-api/` กับ `comments-api/`
- โบนัส +1: ทดสอบเพิ่ม GTA V จาก API ลง SQLite บนเว็บ production แล้วรีโหลด ข้อมูลยังอยู่
- โบนัส +1: ข้อมูล API แสดงทั้งหน้า "ค้นพบเกม" และ "รายละเอียดเกมแนะนำ"
- โบนัส +1: API ตัวที่สอง `/api/comments` (12 คอมเมนต์ผู้ใช้ @ชื่อเกม ทำเอง) + หน้า "ชุมชน" อ่านอย่างเดียว
- ตรวจ API ตอบ HTTP 200 และทดสอบอัตโนมัติ 19 รายการผ่าน
- ทดสอบ HW3 บน iPhone (K1Dev) แล้ว: เปิดแอพ → ค้นพบเกม (สุ่ม + เพิ่มด่วน) → บันทึก SQLite → เปิดใหม่ข้อมูลอยู่

## สิ่งที่เพิ่ม

- `lib/services/api_service.dart`: HTTP GET แบบ async, timeout 12 วินาที, แปลงข้อผิดพลาดเป็นข้อความ
- `lib/models/recommended_game.dart`: fromJson ตรวจชนิดข้อมูล และแปลงเป็นร่างเกมโดยไม่ใช้ id ของ SQLite
- `lib/pages/recommended_games_page.dart`: FutureBuilder loading/error/empty/data และปุ่มโหลดใหม่
- หน้ารายละเอียดจาก API ส่งผ่าน constructor แล้วเปิดฟอร์มเดิมเพื่อเลือกอารมณ์/คะแนน/วันที่และบันทึก SQLite
- Android INTERNET permission
- เว็บใช้ SQLite WASM ผ่าน sqflite_common_ffi_web เก็บ IndexedDB แยกจาก iPhone

## รูปแบบ API บน Vercel

```json
{"games":[{"appId":"271590","title":"GTA V","description":"รายละเอียดเกม","imageUrl":"https://example.com/game.jpg"}]}
```

GET URL สาธารณะ ตอบ 200 และ JSON UTF-8 ไม่ต้องล็อกอิน
ทุก field เป็น String, appId ไม่ซ้ำ, imageUrl ว่างได้หรือใช้ HTTPS
ไม่มีรายการให้ส่ง `{"games":[]}`
เว็บเรียก API คนละ origin ต้องตั้ง CORS ให้ยอมรับ origin ของเว็บที่ใช้
API นี้เป็นข้อมูลเกมสาธารณะ ไม่ส่งข้อมูลไดอารีหรือฐานข้อมูลส่วนตัวไปเซิร์ฟเวอร์

## เปิดเว็บทดสอบตอนยังไม่มี Vercel URL

```sh
flutter pub get
flutter build web --dart-define=GAMES_API_URL=http://localhost:8080/api/games --pwa-strategy=none
node tool/preview_server.mjs
```

เปิด http://localhost:8080 ใช้พอร์ตเดิมเพื่อให้เห็นฐานข้อมูลเดิม
เซิร์ฟเวอร์นี้ส่งข้อมูลตัวอย่าง 7 เกมผ่าน HTTP ในเครื่องเท่านั้น มีป้ายแจ้งโหมดทดสอบ
ไม่ใช่ API ที่ deploy แล้ว และยังไม่ถือว่าสาธิตการดึงข้อมูลจากอินเทอร์เน็ตจริงครบ
ฐานข้อมูลในเว็บอาจถูกล้างได้เมื่อผู้ใช้ล้าง site data หรือใช้โหมดไม่ระบุตัวตน

## รันด้วย API จริง

```sh
flutter run -d chrome --web-port=8080
```

หยุด preview server ก่อนใช้พอร์ตเดียวกัน เปลี่ยน URL แล้วต้องรัน/build ใหม่
บนมือถือใช้ dart-define เดียวกันได้ ไม่ต้องแก้ schema และไม่ต้องถอนแอป
หากไม่ได้กำหนด URL เว็บจะใช้ /api/games ของโดเมนที่เปิดอยู่ ส่วนมือถือใช้ URL production ข้างต้น
ไม่ใช้ข้อมูลจำลองแทนเมื่อ API ล้มเหลว

## Deploy เว็บและ API ซ้ำ

```sh
flutter build web --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none
mkdir -p hosting/public
cp -R build/web/. hosting/public/
cd hosting
vercel deploy --prod --yes --project steam-game-favorite-hw3 --scope hex-s-dev
cd ../games-api
vercel deploy --prod --yes --project steam-games-hw3 --scope hex-s-dev
cd ../comments-api
vercel deploy --prod --yes --project steam-comments-hw3 --scope hex-s-dev
```

อัปโหลดเฉพาะ hosting/ ซึ่งมี compiled web และ API ไม่อัปโหลดฐานข้อมูลส่วนตัวหรือไฟล์สำรอง

## สร้าง SQLite worker ใหม่หากจำเป็น

ไฟล์ web/sqflite_sw.js และ web/sqlite3.wasm เตรียมไว้แล้ว
ใช้ sqlite3 2.9.4 ให้ตรงกับโปรเจกต์ เพื่อไม่เปลี่ยน native dependencies เดิม

```sh
dart compile js -O2 tool/sqlite_worker.dart -o web/sqflite_sw.js
curl -fL https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm -o web/sqlite3.wasm
```

## ทดสอบและส่งงาน

```sh
flutter analyze
flutter test
```

ก่อนส่งต้องใช้ API จริง สาธิตโหลด → รายละเอียด → เพิ่มลง SQLite → รีเฟรช/เปิดใหม่ข้อมูลอยู่
ตัดอินเทอร์เน็ตแล้วกดโหลดใหม่ให้เห็น error ที่สุภาพ และกลับมาเชื่อมต่อแล้วลองใหม่ได้
คลิปไม่เกิน 90 วินาที ชื่อ 67011212055_HW3
ZIP ตามโจทย์: lib/ + pubspec.yaml + AndroidManifest.xml
ถ้าจะให้ผู้รับรันบนเว็บด้วย ต้องแนบ web/ ที่มี SQLite worker และ WASM เพิ่ม
