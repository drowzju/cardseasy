import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/key_point.dart';
import 'markdown_toolbar.dart';
import 'package:flutter/services.dart';
import '../utils/image_handler.dart';

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
  final String? saveDirectory;

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
    required this.saveDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: keyPoints.length,
        itemBuilder: (context, index) {
          final keyPoint = keyPoints[index];
          final bool isSelected = currentKeyPointId == keyPoint.id;
          final bool isExpanded = keyPointExpandedStates[keyPoint.id] ?? true;
          final controller = keyPointControllers[keyPoint.id];

          if (controller == null) return const SizedBox.shrink();

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Row(
                  children: [
                    InkWell(
                      onTap: () => onKeyPointToggleExpanded(keyPoint.id),
                      child: SvgPicture.asset(
                        isExpanded
                            ? 'assets/icons/expand_less.svg'
                            : 'assets/icons/expand_more.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        keyPoint.title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/remove_key_point.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.error,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () => onKeyPointDeleted(keyPoint.id),
                      tooltip: '删除',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                onTap: () => onKeyPointSelected(keyPoint.id),
                selected: isSelected,
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
                              currentEditMode:
                                  isSelected ? currentEditMode : 'text',
                              onFormatSelected: (format) =>
                                  onFormatSelected(format),
                              onImageSelected: onImageSelected,
                            ),
                            const SizedBox(height: 8),
                            KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (KeyEvent event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.keyV &&
                                    HardwareKeyboard
                                        .instance.isControlPressed) {
                                  if (saveDirectory != null) {
                                    ImageHandler.handlePastedImage(
                                        contentController: controller,
                                        saveDirectory: saveDirectory);
                                  }
                                }
                              },
                              child: TextField(
                                controller: controller,
                                maxLines: null,
                                minLines: 3,
                                decoration: InputDecoration(
                                  hintText: '输入关键知识点内容...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: isSelected,
                                  fillColor: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.3)
                                      : null,
                                ),
                                onTap: () => onKeyPointSelected(keyPoint.id),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (index < keyPoints.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        },
      ),
    );
  }
}
