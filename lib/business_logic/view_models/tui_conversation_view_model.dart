// ignore_for_file: unnecessary_getters_setters

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_search_param.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_search_param.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/conversation_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

List<T> removeDuplicates<T>(List<T> list, bool Function(T first, T second) isEqual) {
  List<T> output = [];
  for (var i = 0; i < list.length; i++) {
    bool found = false;
    for (var j = 0; j < output.length; j++) {
      if (isEqual(list[i], output[j])) {
        found = true;
      }
    }
    if (!found) {
      output.add(list[i]);
    }
  }

  return output;
}

class TUIConversationViewModel extends ChangeNotifier {
  static const String conversationC2CPrefix = "c2c_";
  static const String conversationGroupPrefix = "group_";

  final TUISelfInfoViewModel selfInfoViewModel = serviceLocator<TUISelfInfoViewModel>();
  final ConversationService _conversationService = serviceLocator<ConversationService>();
  final FriendshipServices _friendshipServices = serviceLocator<FriendshipServices>();
  final TUIChatGlobalModel _chatGlobalModel = serviceLocator<TUIChatGlobalModel>();
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimConversationListener _conversationListener;
  List<V2TimConversation?> _conversationList = [];
  static V2TimConversation? _selectedConversation;
  Map<String, String> webDraftMap = {};

  bool _haveMoreData = true;
  int _totalUnReadCount = 0;
  String? _scrollToConversation;
  final TUIChatGlobalModel globalChatModel = serviceLocator<TUIChatGlobalModel>();

  String _nextSeq = "0";
  ConversationLifeCycle? _lifeCycle;

  List<V2TimConversation?> get conversationList {
    if (PlatformUtils().isWeb) {
      try {
        _conversationList.sort((a, b) {
          return b!.lastMessage!.timestamp!.compareTo(a!.lastMessage!.timestamp!);
        });

        final pinnedConversation = _conversationList.where((element) => element?.isPinned == true).toList();
        _conversationList.removeWhere((element) => element?.isPinned == true);
        _conversationList = [...pinnedConversation, ..._conversationList];
        // ignore: empty_catches
      } catch (e) {}
    } else {
      _conversationList.sort((a, b) => b!.orderkey!.compareTo(a!.orderkey!));
    }
    return _conversationList;
  }

  V2TimConversation? getConversation(String conversationID) {
    return _conversationList.firstWhereOrNull((element) => element?.conversationID == conversationID);
  }

  String? get scrollToConversation => _scrollToConversation;

  set scrollToConversation(String? value) {
    _scrollToConversation = value;
    notifyListeners();
  }

  void clearScrollToConversation() {
    _scrollToConversation = null;
  }

  bool get haveMoreData {
    return _haveMoreData;
  }

  int get totalUnReadCount => _totalUnReadCount;

  set totalUnReadCount(int value) {
    _totalUnReadCount = value;
  }

  set lifeCycle(ConversationLifeCycle? value) {
    _lifeCycle = value;
  }

  set conversationList(List<V2TimConversation?> conversationList) {
    _conversationList = conversationList;
    notifyListeners();
  }

  set selectedConversation(V2TimConversation? value) {
    _selectedConversation = value;
    notifyListeners();
  }

  V2TimConversation? get selectedConversation {
    return _selectedConversation;
  }

  static V2TimConversation? of() {
    return _selectedConversation;
  }

  TUIConversationViewModel() {
    _conversationListener = V2TimConversationListener(onConversationChanged: (conversationList) {
      _onConversationListChanged(conversationList);
    }, onNewConversation: (conversationList) {
      _addNewConversation(conversationList);
    }, onTotalUnreadMessageCountChanged: (totalUnread) {
      _totalUnReadCount = totalUnread;
      _chatGlobalModel.totalUnReadCount = totalUnread;
      notifyListeners();
    }, onSyncServerFinish: () {
      // Remove the process to load such a many of conversations after launching
      if (!PlatformUtils().isWeb) {
        loadInitConversation();
      }
    }, onConversationDeleted: (List<String> conversationIDList) {
      _onConversationDeleted(conversationIDList);
      for (var conversationID in conversationIDList) {
        String resultID = "";
        if (conversationID.startsWith(conversationC2CPrefix)) {
          resultID = conversationID.replaceFirst(conversationC2CPrefix, "");
        } else if (conversationID.startsWith(conversationGroupPrefix)) {
          resultID = conversationID.replaceFirst(conversationGroupPrefix, "");
        }

        if (resultID != "") {
          _chatGlobalModel.removeMessageList(resultID);
        }
      }
    });
  }

  loadInitConversation() async {
    await loadData(count: 40);
    // Remove the process to load such a many of conversations after launching
    // if (selfInfoViewModel.globalConfig?.isPreloadMessagesAfterInit ?? true) {
    //   _chatGlobalModel.initMessageMapFromLocalDatabase(_conversationList);
    // }
  }

  initConversation() async {
    clearData();
    loadInitConversation();
  }

  Future<void> loadData({required int count}) async {
    _haveMoreData = true;
    final isRefresh = _nextSeq == "0";
    final conversationResult = await _conversationService.getConversationList(nextSeq: _nextSeq, count: count);
    _nextSeq = conversationResult?.nextSeq ?? "";
    final conversationList = conversationResult?.conversationList;
    if (conversationList != null) {
      if (conversationList.isEmpty || conversationList.length < count) {
        _haveMoreData = false;
      }
      List<V2TimConversation?> combinedConversationList = [];
      if (isRefresh) {
        combinedConversationList = conversationList;
      } else {
        combinedConversationList = [..._conversationList, ...conversationList];
      }
      final List<V2TimConversation?> finalConversationList =
          await _lifeCycle?.conversationListWillMount(combinedConversationList) ?? combinedConversationList;
      _conversationList = removeDuplicates<V2TimConversation?>(
          finalConversationList, (item1, item2) => item1?.conversationID == item2?.conversationID);
      notifyListeners();
    }
    _totalUnReadCount = await _conversationService.getTotalUnreadCount();
    notifyListeners();
    return;
  }

  void setSelectedConversation(V2TimConversation conversation) {
    _selectedConversation = conversation;
    notifyListeners();
  }

  Future<V2TimCallback> pinConversation({
    required String conversationID,
    required bool isPinned,
  }) {
    return _conversationService.pinConversation(conversationID: conversationID, isPinned: isPinned);
  }

  Future<V2TimCallback?> clearHistoryMessage({required String convID, required int convType}) async {
    if (_lifeCycle?.shouldClearHistoricalMessageForConversation != null &&
        await _lifeCycle!.shouldClearHistoricalMessageForConversation(convID) == false) {
      return null;
    }

    globalChatModel.setMessageList(convID, []);

    if (convType == 1) {
      return _messageService.clearC2CHistoryMessage(userID: convID);
    } else {
      return _messageService.clearGroupHistoryMessage(groupID: convID);
    }
  }

  searchFriends(String searchKey) async {
    final res = await _friendshipServices.searchFriends(searchParam: V2TimFriendSearchParam(keywordList: [searchKey]));
    return res;
  }

  Future<V2TimCallback?> deleteConversation({required String conversationID}) async {
    if (_lifeCycle?.shouldDeleteConversation != null &&
        await _lifeCycle!.shouldDeleteConversation(conversationID) == false) {
      return null;
    }
    final res = await _conversationService.deleteConversation(conversationID: conversationID);
    if (res.code == 0) {
      _conversationList.removeWhere((element) => element?.conversationID == conversationID);
      notifyListeners();
    }
    return res;
  }

  _onConversationListChanged(List<V2TimConversation> list) {
    for (int element = 0; element < list.length; element++) {
      int index = _conversationList.indexWhere((item) => item!.conversationID == list[element].conversationID);
      if (index > -1) {
        _conversationList.setAll(index, [list[element]] as List<V2TimConversation?>);
      } else {
        _conversationList.add(list[element]);
      }
    }

    notifyListeners();
  }

  _onConversationDeleted(List<String> list) {
    for (int i = 0; i < list.length; i++) {
      int index = _conversationList.indexWhere((item) => item!.conversationID == list[i]);
      if (index > -1) {
        _conversationList.removeAt(index);
        _conversationList = removeDuplicates<V2TimConversation?>(
            _conversationList, (item1, item2) => item1?.conversationID == item2?.conversationID);
      }
    }
    notifyListeners();
  }

  _addNewConversation(List<V2TimConversation> list) {
    _conversationList.addAll(list);
    _conversationList = removeDuplicates<V2TimConversation?>(
        _conversationList, (item1, item2) => item1?.conversationID == item2?.conversationID);
    notifyListeners();
  }

  setConversationListener() {
    _conversationService.addConversationListener(listener: _conversationListener);
  }

  removeConversationListener() {
    _conversationService.removeConversationListener(listener: _conversationListener);
  }

  Future<V2TimCallback> setConversationDraft({
    required String conversationID,
    String? draftText,
    bool isTopic = false,
    String? groupID,
    bool isAllowWeb = true,
  }) async {
    assert(!isTopic || (groupID != null && groupID.isNotEmpty),
        "When 'isTopic' is true, 'groupID' must not be null or empty.");
    if (PlatformUtils().isWeb && isAllowWeb) {
      webDraftMap[conversationID] = draftText ?? "";
      return V2TimCallback(code: 0, desc: "");
    } else {
      if (isTopic) {
        final topicInfoList = await TencentImSDKPlugin.v2TIMManager
            .getGroupManager()
            .getTopicInfoList(groupID: groupID!, topicIDList: [conversationID]);
        final topicInfo = topicInfoList.data?.first.topicInfo;
        topicInfo?.draftText = draftText;
        final res = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setTopicInfo(topicInfo: topicInfo!);
        return res;
      } else {
        return _conversationService.setConversationDraft(conversationID: conversationID, draftText: draftText);
      }
    }
  }

  clearWebDraft({
    required String conversationID,
  }) {
    webDraftMap[conversationID] = "";
  }

  String? getWebDraft({
    required String conversationID,
  }) {
    return TencentUtils.checkString(webDraftMap[conversationID]);
  }

  clearData() {
    _conversationList = [];
    _selectedConversation = null;
    _nextSeq = "0";
    _haveMoreData = true;
    notifyListeners();
  }

  refresh({int count = 100}) {
    _nextSeq = "0";
    _haveMoreData = true;
    loadData(count: count);
  }
}
