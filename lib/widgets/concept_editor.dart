import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'markdown_toolbar.dart';

class ConceptEditor extends StatelessWidget {
  final bool isExpanded;
  final Function() onToggleExpanded;
  final TextEditingController contentController;
  final String currentEditMode;
  final Function(String) onFormatSelected;
  final VoidCallback onImageSelected;
  final VoidCallback onTap;

  const ConceptEditor({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.contentController,
    required this.currentEditMode,
    required this.onFormatSelected,
    required this.onImageSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: isExpanded
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: MarkdownToolbar(
                          currentEditMode: currentEditMode,
                          onFormatSelected: onFormatSelected,
                          onImageSelected: onImageSelected,
                        ),
                      ),
                      GestureDetector(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            height: 150,
                            child: TextField(
                              controller: contentController,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
                                hintText:
                                    '在这里输入概念内容。支持文本和图片\n选中文字后点击上方按钮可应用粗体、斜体等格式',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}