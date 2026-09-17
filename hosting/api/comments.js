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

module.exports = function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Accept, Content-Type');
  res.setHeader('Cache-Control', 'no-store');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET, OPTIONS');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  return res.status(200).json({ comments });
};
