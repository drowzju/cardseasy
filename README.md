# CardsEasy

## 项目介绍

CardsEasy 是一款专为终身学习者设计的知识卡片管理应用，基于 Flutter 框架开发，支持多平台部署。应用结合认知科学的验证理论（如记忆原理、费曼学习法等），帮助用户更有效地思考、学习、记忆和复习知识。

### 主要功能

- **结构化知识管理**：将知识分为整体概念、关键知识点和理解与关联三部分
- **Markdown 支持**：使用 Markdown 格式记录和渲染内容，支持图片、代码块、表格等
- **图片管理**：支持图片粘贴和插入，自动保存到卡片目录
- **自测评价**：支持对知识掌握程度进行自我评价，记录学习进度
- **智能排序**：根据学习状态和遗忘规律智能排序卡片，优先复习薄弱知识
- **多平台支持**：使用 Flutter 框架，支持 Windows、macOS、Linux、Android、iOS 等平台

## 安装与构建

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### 依赖安装

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

### 构建发布版本

#### Windows

```bash
flutter build windows --release
```

#### TODO 支持其他平台

## 使用指南

### 创建卡片盒

1. 在主界面点击「添加卡片盒」按钮
2. 选择或创建一个目录作为卡片盒存储位置
3. 卡片盒将显示在主界面列表中

### 创建卡片

1. 点击卡片盒进入详情页面
2. 点击右下角「+」按钮创建新卡片
3. 填写卡片标题
4. 编辑整体概念、添加关键知识点和理解关联
5. 点击「保存」按钮完成创建

### 卡片预览与自测

1. 在卡片盒详情页面点击卡片进入预览界面
2. 默认进入「预览」模式，可查看完整内容
3. 点击「自测」按钮进入自测模式
4. 自测完成后，为自己的掌握程度评分（1-10分）
5. 评分将保存为卡片元数据，用于智能排序

### 卡片排序

卡片盒详情页面支持多种排序方式：
- 按标题排序
- 按创建时间排序
- 按自测评分排序（默认）
- 按最后测试日期排序

## 卡片模板

每张卡片包含以下结构：
- **卡片标题**：简明扼要地概括卡片内容
- **整体概念**：对知识点的整体描述（例如：美洲狮是生活在美洲的大型食肉动物）
- **关键知识点**：可添加多个，用于记录核心知识（如：美洲狮的食性、美洲狮的身体特征）
- **理解与关联**：可添加多个，用于记录知识间的联系（如：猫科大类的分类、有关美洲狮的纪录片）

## 架构设计

### 图示

```
+------------------+     +------------------+     +------------------+
|      主界面       |     |     卡片盒管理    |     |     卡片管理      |
|  HomeScreen     |---->| CardBoxService  |     |  CardService    |
+------------------+     +------------------+     +------------------+
         |                       ^                       ^
         v                       |                       |
+------------------+     +------------------+     +------------------+
|    卡片盒详情     |---->|    卡片创建      |---->|    卡片预览      |
|CardBoxDetailScreen|     |CardCreateScreen |     |CardPreviewScreen|
+------------------+     +------------------+     +------------------+
         |                       |                       |
         |                       v                       v
         |               +------------------+     +------------------+
         |               |    编辑组件      |     |    渲染组件      |
         |               |  ConceptEditor  |     | MarkdownRenderer |
         |               |  KeyPointList   |     | CardPreviewPanel |
         |               |UnderstandingList|     |                  |
         |               +------------------+     +------------------+
         |                       ^                       ^
         v                       |                       |
+------------------+     +------------------+     +------------------+
|    元数据管理     |     |    工具类        |     |    数据模型      |
| MetadataManager  |<----| ImageHandler    |<----|   CardModel     |
+------------------+     | CardParser      |     |   CardBox       |
                         | CardSaver       |     |   KeyPoint      |
                         |                 |     |   Understanding  |
                         +------------------+     |   CardMetadata  |
                                                  +------------------+
```

### 1. 核心模块 数据模型 (Models)
- **CardBox**: 卡片盒模型，包含 id、name 和 path 属性，代表一个知识领域的卡片集合
- **CardModel**: 卡片模型，包含标题、内容、文件路径等信息，代表单个知识卡片
- **KeyPoint**: 关键知识点模型，包含 id、标题和内容，用于结构化记录重要概念
- **Understanding**: 理解与关联模型，包含 id、标题和内容，用于记录对知识的理解和关联
- **CardMetadata**: 卡片元数据，包含自测评分和最后测试日期，用于跟踪学习进度 

### 服务层 (Services)
- **CardBoxService**: 管理卡片盒的创建、获取和删除，负责卡片盒的持久化存储
- **CardService**: 管理卡片的保存、加载和获取，负责卡片内容的文件操作

### 2. 界面模块 主要界面
- **HomeScreen**: 应用主界面，显示卡片盒列表，是用户的入口点，直接调用 CardBoxService
- **CardBoxDetailScreen**: 卡片盒详情页面，显示卡片列表，支持多种排序方式，调用 CardService 和 MetadataManager
- **CardCreateScreen**: 卡片创建/编辑页面，提供结构化的知识录入界面，使用多个编辑组件
- **CardPreviewScreen**: 卡片预览和自测页面，支持知识复习和自我评价，使用 MarkdownRenderer 渲染内容 

### 组件 (Widgets)
- **ConceptEditor**: 整体概念编辑组件，用于编辑卡片的主要内容，被 CardCreateScreen 使用
- **KeyPointList**: 关键知识点列表组件，用于管理多个知识点，被 CardCreateScreen 使用
- **UnderstandingList**: 理解与关联列表组件，用于管理多个理解和关联，被 CardCreateScreen 使用
- **MarkdownRenderer**: Markdown 渲染组件，负责将 Markdown 内容转换为可视化界面，被 CardPreviewPanel 和 CardPreviewScreen 使用
- **CardPreviewPanel**: 卡片预览面板，用于实时预览卡片内容，使用 MarkdownRenderer 渲染内容

### 3. 工具类 (Utils)
- **ImageHandler**: 处理图片选择和粘贴，支持将图片保存到卡片目录，被编辑组件使用
- **CardParser**: 解析卡片内容，从 Markdown 中提取结构化数据，被 CardPreviewScreen 使用
- **CardSaver**: 保存卡片到文件系统，处理文件和目录操作，被 CardCreateScreen 使用
- **MetadataManager**: 管理卡片元数据，处理评分和测试日期的存储，被 CardPreviewScreen 和 CardBoxDetailScreen 使用

## 数据流向
1. **卡片盒管理流程**:
   
   - 用户在 HomeScreen 创建或选择卡片盒
   - HomeScreen 调用 CardBoxService 管理卡片盒
   - CardBoxService 通过 SharedPreferences 保存卡片盒信息
2. **卡片创建流程**:
   
   - 用户从 CardBoxDetailScreen 进入 CardCreateScreen
   - CardCreateScreen 使用 ConceptEditor、KeyPointList 和 UnderstandingList 组件进行编辑
   - 编辑完成后，通过 CardSaver 将内容保存为 Markdown 文件
3. **卡片预览和自测流程**:
   
   - 用户从 CardBoxDetailScreen 进入 CardPreviewScreen
   - CardPreviewScreen 使用 MarkdownRenderer 渲染卡片内容
   - 自测评分通过 MetadataManager 保存到元数据文件
   - 返回 CardBoxDetailScreen 时，更新卡片元数据和排序
4. **卡片排序和筛选流程**:
   
   - CardBoxDetailScreen 从 CardService 获取卡片列表
   - 通过 MetadataManager 获取每个卡片的元数据
   - 根据元数据进行排序和筛选

## 贡献指南

欢迎贡献代码、报告问题或提出改进建议。请遵循以下步骤：

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request


