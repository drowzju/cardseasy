import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeyPointsHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddKeyPoint;
  final String? tooltip; // 添加提示文本参数

  const KeyPointsHeader({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onAddKeyPoint,
    this.tooltip, // 添加提示文本参数
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleExpanded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SvgPicture.asset(
                isExpanded
                    ? 'assets/icons/expand_less.svg'
                    : 'assets/icons/expand_more.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const Text(
              '关键知识点',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (tooltip != null) // 添加提示图标
              Tooltip(
                message: tooltip!,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            const Spacer(),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/add_key_point.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: '添加关键知识点，即针对知识点展开的细化条目',
              onPressed: onAddKeyPoint,
            ),
          ],
        ),
      ),
    );
  }
}