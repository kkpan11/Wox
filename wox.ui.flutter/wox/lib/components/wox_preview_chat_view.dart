import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:from_css_color/from_css_color.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';
import 'package:wox/components/wox_image_view.dart';
import 'package:wox/entity/wox_hotkey.dart';
import 'package:wox/entity/wox_preview.dart';
import 'package:wox/entity/wox_theme.dart';
import 'package:wox/entity/wox_toolbar.dart';
import 'package:wox/enums/wox_ai_conversation_role_enum.dart';
import 'package:wox/modules/launcher/wox_launcher_controller.dart';
import 'package:wox/utils/log.dart';

class WoxPreviewChatView extends StatefulWidget {
  final WoxPreviewChatData aiChatData;
  final WoxTheme woxTheme;

  const WoxPreviewChatView({super.key, required this.aiChatData, required this.woxTheme});

  @override
  State<WoxPreviewChatView> createState() => _WoxPreviewChatViewState();
}

class _WoxPreviewChatViewState extends State<WoxPreviewChatView> {
  final TextEditingController textController = TextEditingController();
  final WoxLauncherController controller = Get.find<WoxLauncherController>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.scrollToBottomOfAiChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (LoggerSwitch.enablePaintLog) Logger.instance.debug(const UuidV4().generate(), "repaint: chat view");

    return Column(
      children: [
        // AI Model Selection
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: InkWell(
            onTap: () => controller.showActionPanelForModelSelection(const UuidV4().generate(), widget.aiChatData),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: fromCssColor(widget.woxTheme.queryBoxBackgroundColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: fromCssColor(widget.woxTheme.previewPropertyTitleColor).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 20,
                    color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.aiChatData.model.name.isEmpty ? "请选择模型" : widget.aiChatData.model.name,
                      style: TextStyle(
                        color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Messages list
        Expanded(
          child: SingleChildScrollView(
            controller: controller.aiChatScrollController,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: widget.aiChatData.conversations.map((message) => buildMessageItem(message)).toList(),
            ),
          ),
        ),
        // Input box
        Focus(
          onFocusChange: (bool hasFocus) {
            final traceId = const UuidV4().generate();
            if (!hasFocus) {
              controller.updateToolbarByActiveAction(traceId);
            } else {
              controller.updateToolbarByChat(traceId);
            }
          },
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              switch (event.logicalKey) {
                case LogicalKeyboardKey.escape:
                  controller.focusQueryBox();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.enter:
                  sendMessage();
                  return KeyEventResult.handled;
              }
            }

            var pressedHotkey = WoxHotkey.parseNormalHotkeyFromEvent(event);
            if (pressedHotkey == null) {
              return KeyEventResult.ignored;
            }

            // list all models
            if (controller.isActionHotkey(pressedHotkey)) {
              controller.showActionPanelForModelSelection(const UuidV4().generate(), widget.aiChatData);
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: fromCssColor(widget.woxTheme.queryBoxBackgroundColor),
                    borderRadius: BorderRadius.circular(widget.woxTheme.queryBoxBorderRadius.toDouble()),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: textController,
                        focusNode: controller.aiChatFocusNode,
                        decoration: InputDecoration(
                          hintText: '在这里输入消息，按下 ← 发送',
                          hintStyle: TextStyle(color: fromCssColor(widget.woxTheme.previewPropertyTitleColor)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 14,
                          color: fromCssColor(widget.woxTheme.queryBoxFontColor),
                        ),
                      ),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: fromCssColor(widget.woxTheme.previewPropertyTitleColor).withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.link, size: 18),
                              color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_command_key, size: 18),
                              color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.eco_outlined, size: 18),
                              color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: fromCssColor(widget.woxTheme.actionItemActiveBackgroundColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.keyboard_return,
                                    size: 14,
                                    color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '发送',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: fromCssColor(widget.woxTheme.previewPropertyTitleColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void sendMessage() {
    final text = textController.text.trim();
    // Check if AI model is selected
    if (widget.aiChatData.model.name.isEmpty) {
      controller.showToolbarMsg(const UuidV4().generate(), ToolbarMsg(text: "Please select a model", displaySeconds: 3));
      return;
    }
    // check if the text is empty
    if (text.isEmpty) {
      controller.showToolbarMsg(const UuidV4().generate(), ToolbarMsg(text: "Please enter a message", displaySeconds: 3));
      return;
    }

    // append user message to chat data
    widget.aiChatData.conversations.add(WoxPreviewChatConversation(
      id: const UuidV4().generate(),
      role: WoxAIChatConversationRoleEnum.WOX_AIChat_CONVERSATION_ROLE_USER.value,
      text: text,
      images: [],
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    widget.aiChatData.updatedAt = DateTime.now().millisecondsSinceEpoch;

    textController.clear();

    setState(() {});

    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.scrollToBottomOfAiChat();
    });

    controller.sendChatRequest(const UuidV4().generate(), widget.aiChatData);
  }

  Widget buildMessageItem(WoxPreviewChatConversation message) {
    final isUser = message.role == 'user';
    final backgroundColor = isUser ? fromCssColor(widget.woxTheme.resultItemActiveBackgroundColor) : fromCssColor(widget.woxTheme.actionContainerBackgroundColor);
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) buildAvatar(message),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text content
                      MarkdownBody(
                        data: message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: fromCssColor(isUser ? controller.woxTheme.value.resultItemActiveTitleColor : controller.woxTheme.value.resultItemTitleColor),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Images if any
                      if (message.images.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: message.images
                              .map((image) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 200,
                                      child: WoxImageView(woxImage: image),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Text(
                    formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: fromCssColor(controller.woxTheme.value.resultItemSubTitleColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) buildAvatar(message),
        ],
      ),
    );
  }

  Widget buildAvatar(WoxPreviewChatConversation message) {
    final isUser = message.role == 'user';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: fromCssColor(isUser ? widget.woxTheme.actionItemActiveBackgroundColor : widget.woxTheme.resultItemActiveBackgroundColor),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isUser ? 'U' : 'A',
          style: TextStyle(
            color: fromCssColor(isUser ? widget.woxTheme.actionItemActiveFontColor : widget.woxTheme.resultItemActiveTitleColor),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
