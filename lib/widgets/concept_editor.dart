import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'markdown_toolbar.dart';

class ConceptEditor extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final TextEditingController contentController;
  final String currentEditMode;
  final Function(String) onFormatSelected;
  final VoidCallback onImageSelected;
  final VoidCallback onTap;
  final String? tooltip; // 添加提示文本参数

  const ConceptEditor({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.contentController,
    required this.currentEditMode,
    required this.onFormatSelected,
    required this.onImageSelected,
    required this.onTap,
    this.tooltip, // 添加提示文本参数
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
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
                    '整体概念',
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
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownToolbar(
                          currentEditMode: currentEditMode,
                          onFormatSelected: onFormatSelected,
                          onImageSelected: onImageSelected,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: contentController,
                          maxLines: null,
                          minLines: 5,
                          decoration: InputDecoration(
                            hintText: '输入整体概念...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onTap: onTap,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}