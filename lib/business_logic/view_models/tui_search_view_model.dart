// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info_result.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_search_param.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_search_param.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_search_param.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_search_result_item.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message_search_result_item.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';

enum KeywordListMatchType { V2TIM_KEYWORD_LIST_MATCH_TYPE_OR, V2TIM_KEYWORD_LIST_MATCH_TYPE_AND }

class TUISearchViewModel extends ChangeNotifier {
  final FriendshipServices _friendshipServices = serviceLocator<FriendshipServices>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final ConversationService _conversationService = serviceLocator<ConversationService>();
  final GroupServices _groupServices = serviceLocator<GroupServices>();

  List<V2TimFriendInfoResult>? friendList = [];

  List<V2TimMessageSearchResultItem>? msgList = [];
  int msgPage = 0;
  int totalMsgCount = 0;

  int totalMsgInConversationCount = 0;
  List<V2TimMessage> currentMsgListForConversation = [];

  List<V2TimGroupInfo>? groupList = [];

  List<V2TimConversation?> conversationList = [];

  Future<List<V2TimConversation?>?> initConversationMsg() async {
    final conversationResult = await _conversationService.getConversationList(nextSeq: "0", count: 500);
    final conversationListData = conversationResult?.conversationList;
    conversationList = conversationListData ?? [];
    notifyListeners();
    return conversationListData;
  }

  void initSearch() {
    friendList = [];
    msgList = [];
    groupList = [];
    totalMsgCount = 0;
    notifyListeners();
  }

  void searchFriendByKey(String searchKey) async {
    final searchResult =
        await _friendshipServices.searchFriends(searchParam: V2TimFriendSearchParam(keywordList: [searchKey]));
    friendList = searchResult;
    notifyListeners();
  }

  void searchGroupByKey(String searchKey) async {
    final searchResult =
        await _groupServices.searchGroups(searchParam: V2TimGroupSearchParam(keywordList: [searchKey]));
    groupList = searchResult.data ?? [];
    notifyListeners();
  }

  void getMsgForConversation(String keyword, String conversationId, int page) async {
    void clearData() {
      currentMsgListForConversation = [];
      totalMsgInConversationCount = 0;
    }

    if (page == 0) {
      clearData();
    }
    if (keyword.isEmpty) {
      clearData();
      return;
    }
    final searchResult = await _messageService.searchLocalMessages(
        searchParam: V2TimMessageSearchParam(
      keywordList: [keyword],
      pageIndex: page,
      pageSize: 30,
      searchTimePeriod: 0,
      searchTimePosition: 0,
      conversationID: conversationId,
      type: KeywordListMatchType.V2TIM_KEYWORD_LIST_MATCH_TYPE_OR.index,
    ));
    if (searchResult.code == 0 && searchResult.data != null) {
      final messageSearchResultItems = searchResult.data!.messageSearchResultItems!
          .firstWhereOrNull((element) => element.conversationID == conversationId);
      totalMsgInConversationCount = messageSearchResultItems?.messageCount ?? 0;
      currentMsgListForConversation = [
        ...currentMsgListForConversation,
        ...(messageSearchResultItems?.messageList ?? [])
      ];
    }
    notifyListeners();
  }

  void searchMsgByKey(String searchKey, bool isFirst) async {
    if (isFirst == true) {
      msgPage = 0;
      msgList = [];
      totalMsgCount = 0;
    }
    final searchResult = await _messageService.searchLocalMessages(
        searchParam: V2TimMessageSearchParam(
      keywordList: [searchKey],
      pageIndex: msgPage,
      pageSize: 5,
      searchTimePeriod: 0,
      searchTimePosition: 0,
      type: KeywordListMatchType.V2TIM_KEYWORD_LIST_MATCH_TYPE_OR.index,
    ));
    if (searchResult.code == 0 && searchResult.data != null) {
      msgPage++;
      msgList = [...?msgList, ...?searchResult.data!.messageSearchResultItems];
      totalMsgCount = searchResult.data!.totalCount ?? 0;
    }
    notifyListeners();
  }

  void searchByKey(String? searchKey) async {
    if (searchKey == null || searchKey.isEmpty) {
      friendList = [];
      groupList = [];
      msgList = [];
      totalMsgCount = 0;
      notifyListeners();
    } else {
      searchFriendByKey(searchKey);
      searchMsgByKey(searchKey, true);
      searchGroupByKey(searchKey);
    }
  }
}
