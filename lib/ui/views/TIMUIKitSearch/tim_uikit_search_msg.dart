// ignore_for_file: must_be_immutable, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_search_result_item.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message_search_result_item.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_search_view_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/pureUI/tim_uikit_search_item.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/pureUI/tim_uikit_search_folder.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/tim_uikit_search_msg_detail.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/pureUI/tim_uikit_search_showAll.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

class TIMUIKitSearchMsg extends TIMUIKitStatelessWidget {
  List<V2TimMessageSearchResultItem?> msgList;
  int totalMsgCount;
  String keyword;
  final Function(V2TimConversation, V2TimMessage?) onTapConversation;
  final model = serviceLocator<TUISearchViewModel>();
  final Function(V2TimConversation, String) onEnterConversation;

  TIMUIKitSearchMsg(
      {required this.msgList,
      required this.keyword,
      required this.totalMsgCount,
      Key? key,
      required this.onTapConversation,
      required this.onEnterConversation})
      : super(key: key);

  Widget _renderShowALl(bool isShowMore) {
    return (isShowMore == true)
        ? TIMUIKitSearchShowALl(
            textShow: TIM_t("更多聊天记录"),
            onClick: () => {model.searchMsgByKey(keyword, false)},
          )
        : Container();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    List<V2TimConversation?> _conversationList = Provider.of<TUISearchViewModel>(context).conversationList;

    if (msgList.isNotEmpty) {
      return TIMUIKitSearchFolder(folderName: TIM_t("聊天记录"), children: [
        ...msgList.map((conv) {
          V2TimConversation? conversation;
          final index = _conversationList.indexWhere((item) => item!.conversationID == conv?.conversationID);
          if (index > -1) {
            conversation = _conversationList[index]!;
          }
          if (conversation == null) {
            return Container();
          }
          final option1 = conv?.messageCount;
          return TIMUIKitSearchItem(
            onClick: () async {
              onEnterConversation(conversation!, keyword);
            },
            faceUrl: conversation.faceUrl ?? "",
            showName: conversation.showName ?? "",
            lineOne: conversation.showName ?? "",
            lineTwo: TIM_t_para("{{option1}}条相关聊天记录", "$option1条相关聊天记录")(option1: option1),
          );
        }).toList(),
        _renderShowALl(totalMsgCount > msgList.length)
      ]);
    } else {
      return Container();
    }
  }
}
