import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/bold.svg',
            tooltip: '粗体',
            format: 'bold',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/italic.svg',
            tooltip: '斜体',
            format: 'italic',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/list_bulleted.svg',
            tooltip: '无序列表',
            format: 'list',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/list_numbered.svg',
            tooltip: '有序列表',
            format: 'numbered_list',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/code_block.svg',
            tooltip: '代码块',
            format: 'codeblock',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/table.svg',
            tooltip: '表格',
            format: 'table',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/link.svg',
            tooltip: '链接',
            format: 'link',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/quote.svg',
            tooltip: '引用',
            format: 'quote',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/horizontal_rule.svg',
            tooltip: '分割线',
            format: 'hr',
            context: context,
          ),
          _buildSvgToolbarButton(
            svgPath: 'assets/icons/image.svg',
            tooltip: '插入图片',
            format: 'image',
            context: context,
            onPressed: onImageSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildSvgToolbarButton({
    required String svgPath,
    required String tooltip,
    required String format,
    required BuildContext context,
    VoidCallback? onPressed,
  }) {
    final bool isActive = currentEditMode == format;
    final Color iconColor = isActive 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    
    return IconButton(
      icon: SvgPicture.asset(
        svgPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      tooltip: tooltip,
      onPressed: onPressed ?? () => onFormatSelected(format),
    );
  }
}