import 'package:flutter/material.dart';

class MarkdownToolbar extends StatelessWidget {
  final String currentEditMode;
  final Function(String) onFormatSelected;
  final VoidCallback onImageSelected;

  const MarkdownToolbar({
    Key? key,
    required this.currentEditMode,
    required this.onFormatSelected,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: '粗体',
            format: 'bold',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: '斜体',
            format: 'italic',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: '无序列表',
            format: 'list',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: '有序列表',
            format: 'numbered_list',
            context: context,
          ),

          _buildToolbarButton(
            icon: Icons.code_rounded,
            tooltip: '代码块',
            format: 'codeblock',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.table_chart,
            tooltip: '表格',
            format: 'table',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: '链接',
            format: 'link',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.format_quote,
            tooltip: '引用',
            format: 'quote',
            context: context,
          ),
          _buildToolbarButton(
            icon: Icons.horizontal_rule,
            tooltip: '分割线',
            format: 'hr',
            context: context,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '插入图片',
            onPressed: onImageSelected,
            color: currentEditMode == 'image' ? Colors.blue : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required String format,
    required BuildContext context,
  }) {
    final bool isActive = currentEditMode == format;
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => onFormatSelected(format),
      color: isActive ? Colors.blue : null,
    );
  }
}