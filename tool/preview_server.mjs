import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const games = [
  ['730', 'Counter-Strike 2', 'FPS 5v5 วางระเบิดกู้ระเบิด เกมยิงอันดับหนึ่งบน Steam เล่นฟรี'],
  ['570', 'Dota 2', 'MOBA 5v5 เลือกฮีโร่กว่า 100 ตัว วางแผนทีมไฟต์ เล่นฟรี'],
  ['440', 'Team Fortress 2', 'เกมยิงทีมสุดคลาสสิก 9 คลาส เล่นฟรี'],
  ['578080', 'PUBG: BATTLEGROUNDS', 'โดดร่ม 100 คน หาของ เอาตัวรอดเป็นคนสุดท้าย'],
  ['252490', 'Rust', 'เอาชีวิตรอด สร้างฐาน เรดบ้านคนอื่น ดิบเถื่อนสะใจ'],
  ['346110', 'ARK: Survival Evolved', 'เอาตัวรอดบนเกาะไดโนเสาร์ จับไดโนเสาร์มาเป็นพวกได้'],
  ['1085660', 'Destiny 2', 'เกมยิงเก็บของเล่นฟรี ลุยดันเจียนกับเพื่อน'],
  ['1172470', 'Apex Legends', 'Battle Royale ฮีโร่ชูตเตอร์ เล่นฟรี ลื่นมัน'],
  ['359550', 'Rainbow Six Siege', 'เกมยิงเชิงแท็กติก วางแผนบุกทีละห้องกับทีม'],
  ['271590', 'GTA V', 'สำรวจเมือง Los Santos ในเกมแอ็กชันผจญภัยโลกเปิด สลับมุมมองระหว่างตัวละครหลักสามคน'],
  ['1174180', 'Red Dead Redemption 2', 'ออกเดินทางไปกับ Arthur Morgan และแก๊ง Van der Linde ในโลกตะวันตกอันกว้างใหญ่'],
  ['1091500', 'Cyberpunk 2077', 'RPG โลกเปิดในเมือง Night City แต่งตัว อัปเกรดไซเบอร์'],
  ['292030', 'The Witcher 3: Wild Hunt', 'ผจญภัยเป็น Geralt ล่ามอนสเตอร์ เนื้อเรื่องเข้มข้น'],
  ['1245620', 'ELDEN RING', 'โซลไลก์โลกเปิด ท้าทายบอสโหด สำรวจดันเจียน'],
  ['1086940', "Baldur's Gate 3", 'RPG เทิร์นเบสเนื้อเรื่องลึก เล่น co-op กับเพื่อนได้'],
  ['367520', 'Hollow Knight', 'ผจญภัยในอาณาจักรแมลง ดาบคม บอสโหด เพลงเพราะ'],
  ['105600', 'Terraria', 'ขุด สร้าง สู้บอส แซนด์บ็อกซ์ 2D เล่นกับเพื่อนสนุก'],
  ['413150', 'Stardew Valley', 'ทำฟาร์ม จีบ NPC ใช้ชีวิตสโลว์ไลฟ์ ผ่อนคลาย'],
  ['648800', 'Raft', 'เอาตัวรอดกลางทะเลบนแพไม้ ลอยไปเก็บของกับเพื่อน'],
  ['892970', 'Valheim', 'เป็นไวกิ้งเอาตัวรอด สร้างบ้าน ล่าบอสกับเพื่อน'],
  ['322330', "Don't Starve Together", 'เอาตัวรอดในโลกประหลาดกับเพื่อน หิว หนาว หลอน'],
  ['548430', 'Deep Rock Galactic', 'เป็นคนแคระขุดเหมืองยิงแมลง co-op 4 คน'],
  ['632360', 'Risk of Rain 2', 'โร้กไลก์ยิงแหลก ยิ่งได้ของยิ่งมัน ตายเริ่มใหม่'],
  ['381210', 'Dead by Daylight', 'หนีฆาตกร 4v1 ปั่นไฟ เอาตัวรอดให้ได้'],
  ['739630', 'Phasmophobia', 'ล่าผี co-op 4 คน ใส่หูฟังแล้วหลอนสุด'],
  ['1966720', 'Lethal Company', 'เก็บเศษซากบนดาวร้างกับเพื่อน ฮาปนหลอน'],
  ['1426210', 'It Takes Two', 'เกม co-op สองคน ผจญภัยตัวจิ๋ว เล่นกับแฟนหรือเพื่อนดีมาก'],
  ['2379780', 'Balatro', 'โป๊กเกอร์โร้กไลก์ เล่นเพลินจนลืมเวลา'],
  ['646570', 'Slay the Spire', 'การ์ดเกมโร้กไลก์ วางแผนไต่หอคอย'],
  ['504230', 'Celeste', 'แพลตฟอร์มเมอร์ปีนเขา ยากแต่ประทับใจ'],
  ['255710', 'Cities: Skylines', 'สร้างเมืองทั้งเมือง วางผังยันแก้รถติด'],
  ['294100', 'RimWorld', 'บริหารอาณานิคมบนดาวเอเลี่ยน ดราม่าเกิดตลอด'],
  ['594650', 'Hunt: Showdown 1896', 'เกมยิงล่าค่าหัวที่ต้องรับมือทั้งสัตว์ประหลาดและผู้เล่นอื่น เน้นเสียงและการวางแผนร่วมกับทีม'],
  ['513710', 'SCUM', 'เกมเอาชีวิตรอดที่ต้องหาอาหาร ดูแลร่างกาย สร้างที่พัก และสำรวจพื้นที่อันตราย'],
  ['304930', 'Unturned', 'เอาชีวิตรอดในโลกซอมบี้สไตล์เหลี่ยม รวบรวมทรัพยากรและสร้างฐานกับเพื่อน'],
  ['1623730', 'Palworld', 'สำรวจโลก จับเหล่า Pal สร้างฐานและผจญภัยร่วมกับเพื่อน'],
  ['633230', 'NARUTO TO BORUTO: SHINOBI STRIKER', 'สร้างนินจาของตัวเอง เลือกวิชาและร่วมต่อสู้แบบทีมในโลกนารูโตะ'],
].map(([appId, title, description]) => ({ appId, title, description,
  imageUrl: `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg` }));

const comments = [
  ['c1', '730', 'Counter-Strike 2', 'Nutty', 'ยิงหัวฟินมาก เปิดดิสเล่นกับเพื่อนทุกคืน', 5, '2026-09-12'],
  ['c2', '413150', 'Stardew Valley', 'Fah', 'เล่นก่อนนอนทุกวัน ฟาร์มไม่เสร็จสักที 555', 5, '2026-09-11'],
  ['c3', '1245620', 'ELDEN RING', 'BossKiller', 'ตายไปห้าสิบรอบกว่าจะผ่านบอสตัวแรก แต่สะใจมาก', 4, '2026-09-10'],
  ['c4', '1966720', 'Lethal Company', 'Gop', 'ฮากระจาย เพื่อนกรี๊ดลั่นดิสคอร์ด', 5, '2026-09-09'],
  ['c5', '1091500', 'Cyberpunk 2077', 'Vee', 'แพตช์ใหม่ลื่นขึ้นเยอะ Night City สวยมาก', 4, '2026-09-08'],
  ['c6', '892970', 'Valheim', 'Oat', 'สร้างบ้านกับเพื่อนเพลินจนลืมเวลา', 4, '2026-09-07'],
  ['c7', '2379780', 'Balatro', 'Mint', 'เตือนภัย เล่นแล้ววางไม่ลงจริง', 5, '2026-09-06'],
  ['c8', '1426210', 'It Takes Two', 'Pair', 'เล่นกับแฟนจนจบ ดีที่สุดเกม co-op ที่เคยเล่น', 5, '2026-09-05'],
  ['c9', '739630', 'Phasmophobia', 'Ghost', 'หลอนดี แต่เจอบั๊กผีติดกำแพงบ่อยไปหน่อย', 3, '2026-09-04'],
  ['c10', '548430', 'Deep Rock Galactic', 'Dwarf', 'ROCK AND STONE! เล่นกับตี้ประจำทุกวีค', 4, '2026-09-03'],
  ['c11', '271590', 'GTA V', 'LosSantos', 'สิบปีแล้วยังสนุก เข้า FiveM ทุกวัน', 5, '2026-09-02'],
  ['c12', '367520', 'Hollow Knight', 'Knight', 'บอสโหด เพลงเพราะ รอภาคต่อไม่ไหวแล้ว', 5, '2026-09-01'],
].map(([id, appId, gameTitle, user, text, rating, date]) => (
  {id, appId, gameTitle, user, text, rating, date}
));

const types = { '.html': 'text/html', '.js': 'application/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf' };

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost:8080');
  res.setHeader('Cache-Control', 'no-store');
  if (url.pathname === '/api/games') {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ games }));
    return;
  }
  if (url.pathname === '/api/comments') {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ comments }));
    return;
  }
  const path = resolve(root, `.${decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname)}`);
  if (!path.startsWith(resolve(root) + sep)) {
    res.writeHead(403).end();
    return;
  }
  try {
    const data = await readFile(path);
    res.setHeader('Content-Type', types[extname(path)] ?? 'application/octet-stream');
    res.end(data);
  } catch {
    res.writeHead(404).end('Not found');
  }
}).listen(8080, '127.0.0.1', () => {
  console.log('Web preview: http://localhost:8080');
  console.log('Local fixture API only, not deployed: http://localhost:8080/api/games');
});
