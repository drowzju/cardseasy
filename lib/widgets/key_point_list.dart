import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/key_point.dart';
import 'markdown_toolbar.dart';

class KeyPointList extends StatelessWidget {
  final List<KeyPoint> keyPoints;
  final Map<String, bool> keyPointExpandedStates;
  final Map<String, TextEditingController> keyPointControllers;
  final String? currentKeyPointId;
  final String currentEditMode;
  final Function(String) onKeyPointSelected;
  final Function(String) onKeyPointDeleted;
  final Function(String) onKeyPointToggleExpanded;
  final Function(String) onFormatSelected;
  final VoidCallback onImageSelected;

  const KeyPointList({
    super.key,
    required this.keyPoints,
    required this.keyPointExpandedStates,
    required this.keyPointControllers,
    required this.currentKeyPointId,
    required this.currentEditMode,
    required this.onKeyPointSelected,
    required this.onKeyPointDeleted,
    required this.onKeyPointToggleExpanded,
    required this.onFormatSelected,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (keyPoints.isEmpty) {
      return const Center(child: Text('点击 + 添加关键知识点'));
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: keyPoints.length,
        itemBuilder: (context, index) {
          final keyPoint = keyPoints[index];
          final bool isSelected = currentKeyPointId == keyPoint.id;

          // 确保每个知识点都有展开状态
          final bool isExpanded = keyPointExpandedStates[keyPoint.id] ?? true;

          return Column(
            children: [
              ListTile(
                leading: IconButton(
                  icon: SvgPicture.asset(
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
                  tooltip: isExpanded ? '折叠' : '展开',
                  onPressed: () => onKeyPointToggleExpanded(keyPoint.id),
                ),
                title: Text(keyPoint.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/remove_key_point.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.error,
                          BlendMode.srcIn,
                        ),
                      ),
                      tooltip: '删除此知识点',
                      onPressed: () => onKeyPointDeleted(keyPoint.id),
                    ),
                  ],
                ),
                onTap: () => onKeyPointSelected(keyPoint.id),
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ),
              if (isSelected && isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      MarkdownToolbar(
                        currentEditMode: currentEditMode,
                        onFormatSelected: onFormatSelected,
                        onImageSelected: onImageSelected,
                      ),
                      Container(
                        height: 150,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: TextField(
                          controller: keyPointControllers[keyPoint.id],
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: '在这里输入知识点内容。支持文本和图片',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}