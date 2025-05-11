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
            format: 'code_block',
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
          _buildImageButton(context),
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: onPressed ?? () {
            onFormatSelected(format);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(
              svgPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isActive 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: '插入图片',
        child: InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: onImageSelected,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(
              'assets/icons/image.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn
              ),
            ),
          ),
        ),
      ),
    );
  }
}