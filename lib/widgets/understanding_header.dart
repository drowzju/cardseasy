import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UnderstandingHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddUnderstanding;

  const UnderstandingHeader({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onAddUnderstanding,
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
              '理解与关联',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/add_key_point.svg', // 复用现有图标
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: '添加理解与关联，即对知识的自我理解、和其他知识的类比关联信息、针对知识的问答',
              onPressed: onAddUnderstanding,
            ),
          ],
        ),
      ),
    );
  }
}