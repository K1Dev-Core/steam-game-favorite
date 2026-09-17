import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyDiaryApp());
}

class MyDiaryApp extends StatelessWidget {
  const MyDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'MyDiary',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: CupertinoColors.activeBlue,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: 'บันทึก',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.info),
            label: 'เกี่ยวกับ',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) =>
              index == 0 ? const DiaryListPage() : const AboutPage(),
        );
      },
    );
  }
}

class DiaryListPage extends StatelessWidget {
  const DiaryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('บันทึกของฉัน')),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              children: [
                Text(
                  'บันทึกประจำวัน',
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.navLargeTitleTextStyle,
                ),
                const SizedBox(height: 6),
                const Text(
                  'เรื่องราวเล็ก ๆ ของฉันในแต่ละวัน',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                ...List.generate(
                  diaries.length,
                  (index) => _DiaryCard(diary: diaries[index], index: index),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showComingSoon(context),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('เพิ่มบันทึก'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('ฟีเจอร์นี้จะเพิ่มในสัปดาห์หน้า'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final Diary diary;
  final int index;

  const _DiaryCard({required this.diary, required this.index});

  static const colors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemTeal,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPink,
    CupertinoColors.systemGreen,
  ];

  @override
  Widget build(BuildContext context) {
    // ใช้สีต่างกันตามลำดับการ์ด และวนกลับไปใช้สีเดิมเมื่อรายการเยอะ
    final color = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => DiaryDetailPage(diary: diary)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.book, color: color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      diary.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      diary.date,
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.tertiaryLabel,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Diary {
  final String title;
  final String content;
  final String date;

  const Diary({required this.title, required this.content, required this.date});
}

const List<Diary> diaries = [
  Diary(
    title: 'วันแรกของการเรียน Flutter',
    content: 'วันนี้ได้เริ่มเขียนแอปตัวแรก รู้สึกตื่นเต้นมาก',
    date: '1 มิ.ย. 2569',
  ),
  Diary(
    title: 'เข้าใจ Widget แล้ว',
    content: 'ทุกอย่างใน Flutter คือ Widget เหมือนต่อเลโก้',
    date: '3 มิ.ย. 2569',
  ),
  Diary(
    title: 'ทำ ListView สำเร็จ',
    content: 'วันนี้ทำรายการเลื่อนได้ ภูมิใจจัง',
    date: '5 มิ.ย. 2569',
  ),
  Diary(
    title: 'เรียนรู้การใช้สี',
    content: 'ได้ลองตกแต่งแอปด้วยสีและไอคอนต่าง ๆ',
    date: '7 มิ.ย. 2569',
  ),
  Diary(
    title: 'สร้างหน้ารายละเอียด',
    content: 'วันนี้ฝึกส่งข้อมูลไปแสดงในหน้าใหม่',
    date: '3 ก.ย. 2569',
  ),
];

class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('รายละเอียดบันทึก'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                diary.title,
                style: CupertinoTheme.of(
                  context,
                ).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 10),
              Text(
                diary.date,
                style: const TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 25),
              Container(height: 1, color: CupertinoColors.separator),
              const SizedBox(height: 25),
              Text(
                diary.content,
                style: const TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 17,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('เกี่ยวกับแอป')),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.book_fill,
                    size: 44,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'MyDiary',
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.navLargeTitleTextStyle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'แอปสมุดบันทึกส่วนตัว',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 22),
                const Text('สร้างโดย วชิรวิทย์ วงค์แสง'),
                const SizedBox(height: 5),
                const Text('รหัสนักศึกษา 67011212055'),
                const SizedBox(height: 18),
                const Text(
                  'เวอร์ชัน 1.0',
                  style: TextStyle(
                    color: CupertinoColors.tertiaryLabel,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
