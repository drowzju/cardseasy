import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/understanding.dart';
import 'markdown_toolbar.dart';

class UnderstandingList extends StatelessWidget {
  final List<Understanding> understandings;
  final Map<String, bool> understandingExpandedStates;
  final Map<String, TextEditingController> understandingControllers;
  final String? currentUnderstandingId;
  final String currentEditMode;
  final Function(String) onUnderstandingSelected;
  final Function(String) onUnderstandingDeleted;
  final Function(String) onUnderstandingToggleExpanded;
  final Function(String) onFormatSelected;
  final VoidCallback onImageSelected;

  const UnderstandingList({
    super.key,
    required this.understandings,
    required this.understandingExpandedStates,
    required this.understandingControllers,
    required this.currentUnderstandingId,
    required this.currentEditMode,
    required this.onUnderstandingSelected,
    required this.onUnderstandingDeleted,
    required this.onUnderstandingToggleExpanded,
    required this.onFormatSelected,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: understandings.length,
        itemBuilder: (context, index) {
          final understanding = understandings[index];
          final isExpanded = understandingExpandedStates[understanding.id] ?? true;
          final isSelected = currentUnderstandingId == understanding.id;
          final controller = understandingControllers[understanding.id];

          if (controller == null) return const SizedBox.shrink();

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Row(
                  children: [
                    InkWell(
                      onTap: () => onUnderstandingToggleExpanded(understanding.id),
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
                        understanding.title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => onUnderstandingDeleted(understanding.id),
                      tooltip: '删除',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                onTap: () => onUnderstandingSelected(understanding.id),
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
                              currentEditMode: isSelected ? currentEditMode : 'text',
                              onFormatSelected: (format) => onFormatSelected(format),
                              onImageSelected: onImageSelected,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller,
                              maxLines: null,
                              minLines: 3,
                              decoration: InputDecoration(
                                hintText: '输入理解与关联内容...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: isSelected,
                                fillColor: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                    : null,
                              ),
                              onTap: () => onUnderstandingSelected(understanding.id),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (index < understandings.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        },
      ),
    );
  }
}