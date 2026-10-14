import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.identity, this.size = 40});
  final String identity;
  final double size;

  String get _seed {
    var hash = 2166136261;
    for (final unit in identity.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: ColoredBox(
        color: const Color(0xFFE9EEF5),
        child: SvgPicture.network(
          'https://api.dicebear.com/10.x/clay/svg?seed=$_seed',
          fit: BoxFit.cover,
          placeholderBuilder: (_) =>
              const Center(child: CupertinoActivityIndicator(radius: 8)),
          errorBuilder: (_, error, stackTrace) => Icon(
            CupertinoIcons.person_fill,
            size: size * 0.5,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ),
    ),
  );
}
