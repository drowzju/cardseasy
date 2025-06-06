import 'package:flutter/material.dart';

class MarkdownFormatter {
  // 格式化文本
  static void formatText({
    required TextEditingController controller,
    required String format,
    required Function(String) showFormatHint,
  }) {
    final TextEditingValue currentValue = controller.value;
    final int selectionStart = currentValue.selection.baseOffset;
    final int selectionEnd = currentValue.selection.extentOffset;
    
    // 确保选择范围有效
    if (selectionStart < 0 || selectionEnd < 0) {
      showFormatHint('请先选择要格式化的文本');
      return;
    }
    
    // 确保选择范围在文本长度内
    final int textLength = currentValue.text.length;
    if (selectionStart > textLength || selectionEnd > textLength) {
      showFormatHint('文本选择范围无效，请重新选择');
      return;
    }
    
    // 确保起始位置不大于结束位置
    final int validStart = selectionStart <= selectionEnd ? selectionStart : selectionEnd;
    final int validEnd = selectionStart <= selectionEnd ? selectionEnd : selectionStart;
    
    String selectedText = '';
    String newText = '';
    String prefix = '';
    String suffix = '';
    
    // 获取选中的文本
    if (validStart != validEnd) {
      try {
        selectedText = currentValue.text.substring(validStart, validEnd);
      } catch (e) {
        print('获取选中文本失败: $e');
        showFormatHint('获取选中文本失败，请重新选择');
        return;
      }
    } else {
      // 如果是需要选中文本的格式，但没有选中文本，显示提示
      if (_needsSelectedText(format)) {
        showFormatHint('请先选择要设置为${_getFormatName(format)}的文本');
        return;
      }
    }
    
    // 根据不同的格式设置前缀和后缀
    final FormatResult formatResult = _getFormatPrefixSuffix(format, selectedText);
    prefix = formatResult.prefix;
    suffix = formatResult.suffix;
    
    // 特殊处理列表格式
    if ((format == 'list' || format == 'numbered_list') && selectedText.contains('\n')) {
      _handleListFormat(controller, format, selectedText, validStart, validEnd);
      return;
    }
    
    // 构建新文本
    try {
      if (selectedText.isEmpty) {
        newText = currentValue.text.substring(0, validStart) + 
                  prefix + suffix + 
                  currentValue.text.substring(validEnd);
        
        // 设置新的光标位置
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: validStart + prefix.length),
        );
      } else {
        newText = currentValue.text.substring(0, validStart) + 
                  prefix + selectedText + suffix + 
                  currentValue.text.substring(validEnd);
        
        // 设置新的选择范围
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: validStart + prefix.length,
            extentOffset: validStart + prefix.length + selectedText.length,
          ),
        );
      }
    } catch (e) {
      print('应用格式失败: $e');
      showFormatHint('应用格式失败: $e');
    }
    
    // 新增格式冲突检测
    if (_hasConflictingFormat(currentValue.text, format, validStart, validEnd)) {
      showFormatHint('不能在此处应用该格式，可能与其他格式冲突');
      return;
    }
  }
  
  // 判断格式是否需要选中文本
  static bool _needsSelectedText(String format) {
    return [
      'bold', 'italic', 'list', 'numbered_list',
      'code_block', 'highlight'  // 添加高亮到需要选中文本的格式列表
    ].contains(format);
  }
  
  // 获取格式名称
  static String _getFormatName(String format) {
    switch (format) {
      case 'bold': return '粗体';
      case 'italic': return '斜体';
      case 'list': return '无序列表';
      case 'numbered_list': return '有序列表';
      case 'code_block': return '代码块';
      case 'quote': return '引用';
      case 'hr': return '分割线';
      case 'highlight': return '高亮';  // 添加高亮格式名称
      default: return format;
    }
  }
  
  // 获取格式的前缀和后缀
  static FormatResult _getFormatPrefixSuffix(String format, String selectedText) {
    String prefix = '';
    String suffix = '';
    
    switch (format) {
      case 'bold':
        prefix = '**';
        suffix = '**';
        break;
      case 'italic':
        prefix = '_';
        suffix = '_';
        break;
      case 'highlight':  // 添加高亮格式处理
        prefix = '==';
        suffix = '==';
        break;
      case 'heading1':
        prefix = '# ';
        suffix = '';
        break;
      case 'heading2':
        prefix = '## ';
        suffix = '';
        break;
      case 'heading3':
        prefix = '### ';
        suffix = '';
        break;
      case 'list':
        prefix = '- ';
        suffix = '';
        break;
      case 'numbered_list':
        prefix = '1. ';
        suffix = '';
        break;
      case 'code_block':
        // 代码块需要在前后添加换行和三个反引号
        if (!selectedText.startsWith('\n')) {
          prefix = '\n```\n';
        } else {
          prefix = '```\n';
        }
        if (!selectedText.endsWith('\n')) {
          suffix = '\n```\n';
        } else {
          suffix = '```\n';
        }
        break;
      case 'link':
        // 如果选中文本包含表格结构，则不应用链接格式
        if (selectedText.contains('| --- |')) {
          return FormatResult('', '');
        }
        prefix = '[';
        suffix = '](链接URL)';
        break;
      case 'table':
        // 如果选中文本包含链接结构，则不应用表格格式
        if (selectedText.contains('[]()')) {
          return FormatResult('', '');
        }
        prefix = '\n| 列1 | 列2 | 列3 |\n| --- | --- | --- |\n| 内容1 | 内容2 | 内容3 |\n';
        suffix = '';
        break;
      case 'quote':
        prefix = '> ';
        suffix = '';
        break;
      case 'hr':
        prefix = '\n---\n';
        suffix = '';
        break;
    }

    return FormatResult(prefix, suffix);
  }
  
  // 处理列表格式
  static void _handleListFormat(
    TextEditingController controller,
    String format,
    String selectedText,
    int validStart,
    int validEnd
  ) {
    final List<String> lines = selectedText.split('\n');
    final List<String> formattedLines = [];
    
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.isNotEmpty) {
        if (format == 'list') {
          // 检查是否已经是无序列表项
          if (line.startsWith('- ')) {
            formattedLines.add(line);
          } else {
            formattedLines.add('- $line');
          }
        } else { // numbered_list
          // 检查是否已经是有序列表项
          final RegExp orderedListRegex = RegExp(r'^\d+\.\s');
          if (orderedListRegex.hasMatch(line)) {
            formattedLines.add(line);
          } else {
            formattedLines.add('${i + 1}. $line');
          }
        }
      } else {
        formattedLines.add(line); // 保留空行
      }
    }
    
    // 使用新的格式化文本替换选中文本
    final String newText = controller.text.substring(0, validStart) +
                formattedLines.join('\n') +
                controller.text.substring(validEnd);
    
    // 设置新的选择范围
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: validStart,
        extentOffset: validStart + formattedLines.join('\n').length,
      ),
    );
  }
  
  // 为了兼容现有代码，添加insertFormat方法
  static void insertFormat(TextEditingController controller, String format) {
    formatText(
      controller: controller,
      format: format,
      showFormatHint: (message) {
        print(message); // 简单打印消息，实际应用中可能需要更好的处理方式
      },
    );
  }
  
  // 新增冲突检测方法
  static bool _hasConflictingFormat(String text, String format, int start, int end) {
    final selectedText = text.substring(start, end);
    
    // 检测表格与链接的冲突
    if (format == 'table' && selectedText.contains('[]()')) {
      return true;
    }
    if (format == 'link' && selectedText.contains('| --- |')) {
      return true;
    }
    
    return false;
  }
}

// 格式化结果类
class FormatResult {
  final String prefix;
  final String suffix;
  
  FormatResult(this.prefix, this.suffix);
}