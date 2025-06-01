import 'package:flutter/material.dart';
import '../widgets/markdown_renderer.dart';

class SingleItemSelfTestCompareDialog extends StatefulWidget {
  final String cardTitle;
  final String itemTitle;
  final String itemContent;
  final String parentTitle;
  final String cardDirectoryPath;
  final String? initialTestContent;
  final Function(String) onTestContentChanged;

  const SingleItemSelfTestCompareDialog({
    super.key,
    required this.cardTitle,
    required this.itemTitle,
    required this.itemContent,
    required this.parentTitle,
    required this.cardDirectoryPath,
    this.initialTestContent,
    required this.onTestContentChanged,
  });

  @override
  State<SingleItemSelfTestCompareDialog> createState() => _SingleItemSelfTestCompareDialogState();
}

class _SingleItemSelfTestCompareDialogState extends State<SingleItemSelfTestCompareDialog> {
  late TextEditingController _testController;
  bool _showOriginalContent = false;
  
  @override
  void initState() {
    super.initState();
    _testController = TextEditingController(text: widget.initialTestContent ?? '');
  }

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  Color get _sectionColor {
    switch (widget.parentTitle) {
      case '关键知识点':
        return Colors.blue.shade700;
      case '理解与关联':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.parentTitle} - ${widget.itemTitle}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onTestContentChanged(_testController.text);
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 1,
        ),
        body: Row(
          children: [
            // 左侧原始内容区域
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 原始内容标题栏
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _sectionColor.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.parentTitle == '关键知识点' 
                                ? Icons.bookmark 
                                : Icons.link,
                            color: _sectionColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.itemTitle,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _sectionColor,
                              ),
                            ),
                          ),
                          // 显示/隐藏按钮
                          IconButton(
                            icon: Icon(
                              _showOriginalContent
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _sectionColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _showOriginalContent = !_showOriginalContent;
                              });
                            },
                            tooltip: _showOriginalContent ? '隐藏原始内容' : '显示原始内容',
                          ),
                        ],
                      ),
                    ),
                    // 原始内容区域
                    Expanded(
                      child: AnimatedCrossFade(
                        firstChild: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: MarkdownRenderer(
                              data: widget.itemContent,
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                              cardDirectoryPath: widget.cardDirectoryPath,
                            ),
                          ),
                        ),
                        secondChild: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '原始内容已隐藏\n点击右上角眼睛图标显示',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        crossFadeState: _showOriginalContent
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 右侧自测输入区域
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 自测输入标题栏
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '自测输入',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        // 添加占位空间，与左侧按钮对齐
                        SizedBox(
                          width: 40, // IconButton 的默认宽度
                          height: 40, // IconButton 的默认高度
                        ),
                      ],
                    ),
                  ),
                  // 自测输入区域
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _testController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '在这里输入你对"${widget.itemTitle}"的理解和记忆...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _sectionColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        onChanged: (value) {
                          widget.onTestContentChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '提示：先尝试回忆，再对比原始内容',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onTestContentChanged(_testController.text);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sectionColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section类定义（如果不在其他地方定义的话）
class Section {
  final String title;
  final String content;
  final int level;
  final String? parentTitle;

  Section({
    required this.title,
    required this.content,
    required this.level,
    this.parentTitle,
  });
}