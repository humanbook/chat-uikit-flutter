// ignore_for_file: unnecessary_getters_setters, avoid_print

import 'package:flutter/cupertino.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_filter_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/receive_message_opt_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_operation_result.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_search_param.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_search_result.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_search_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/group_profile_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/core_services_implements.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';

class TUIGroupProfileModel extends ChangeNotifier {
  final CoreServicesImpl _coreServices = serviceLocator<CoreServicesImpl>();
  final GroupServices _groupServices = serviceLocator<GroupServices>();
  final ConversationService _conversationService = serviceLocator<ConversationService>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final FriendshipServices _friendshipServices = serviceLocator<FriendshipServices>();
  GroupProfileLifeCycle? _lifeCycle;

  V2TimConversation? _conversation;
  String _groupID = "";
  List<V2TimFriendInfo>? _contactList;
  List<V2TimGroupMemberFullInfo?>? _groupMemberList;
  String _groupMemberListSeq = "0";
  V2TimGroupInfo? _groupInfo;
  Function(V2TimGroupMemberFullInfo groupMemberFullInfo, TapDownDetails? tapDetails)? onClickUser;

  GroupProfileLifeCycle? get lifeCycle => _lifeCycle;

  set lifeCycle(GroupProfileLifeCycle? value) {
    _lifeCycle = value;
  }

  V2TimConversation? get conversation => _conversation;

  set conversation(V2TimConversation? value) {
    _conversation = value;
  }

  String get groupID => _groupID;

  set groupID(String value) {
    _groupID = value;
  }

  List<V2TimFriendInfo> get contactList => _contactList ?? [];

  set contactList(List<V2TimFriendInfo> value) {
    _contactList = value;
  }

  List<V2TimGroupMemberFullInfo?> get groupMemberList => _groupMemberList ?? [];

  set groupMemberList(List<V2TimGroupMemberFullInfo?> value) {
    _groupMemberList = value;
  }

  V2TimGroupInfo? get groupInfo => _groupInfo;

  set groupInfo(V2TimGroupInfo? value) {
    _groupInfo = value;
  }

  void loadData(String groupID) {
    _groupID = groupID;
    loadGroupInfo(groupID);
    loadGroupMemberList(groupID: groupID);
    _loadConversation();
    _loadContactList();
  }

  loadGroupInfo(String groupID) async {
    final groupInfo = await _groupServices.getGroupsInfo(groupIDList: [groupID]);
    if (groupInfo != null) {
      final groupRes = groupInfo.first;
      if (groupRes.resultCode == 0) {
        _groupInfo = groupRes.groupInfo;
      }
    }
    notifyListeners();
  }

  Future<void> loadGroupMemberList({required String groupID, int count = 100, String? seq}) async {
    final String? nextSeq = await _loadGroupMemberListFunction(groupID: groupID, seq: seq, count: count);
    if (nextSeq != null && nextSeq != "0" && nextSeq != "") {
      return await loadGroupMemberList(groupID: groupID, count: count, seq: nextSeq);
    } else {
      notifyListeners();
    }
  }

  Future<String?> _loadGroupMemberListFunction({required String groupID, int count = 100, String? seq}) async {
    if (seq == null || seq == "" || seq == "0") {
      _groupMemberList?.clear();
    }
    final res = await _groupServices.getGroupMemberList(
        groupID: groupID,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL,
        count: count,
        nextSeq: seq ?? _groupMemberListSeq);
    final groupMemberListRes = res.data;
    if (res.code == 0 && groupMemberListRes != null) {
      final groupMemberListTemp = groupMemberListRes.memberInfoList ?? [];
      // TODO
      outputLogger.i(
          "loadGroupMemberListfinish,groupMemberListTemp, ${groupMemberListRes.nextSeq},  ${groupMemberListTemp.length}");
      _groupMemberList = [...?_groupMemberList, ...groupMemberListTemp];
      _groupMemberListSeq = groupMemberListRes.nextSeq ?? "0";
    }
    return groupMemberListRes?.nextSeq;
  }

  _loadConversation() async {
    conversation = await _conversationService.getConversation(conversationID: "group_$_groupID");
  }

  _loadContactList() async {
    final res = await _friendshipServices.getFriendList();
    _contactList = res;
  }

  pinedConversation(bool isPined) async {
    await _conversationService.pinConversation(conversationID: "group_$_groupID", isPinned: isPined);
    conversation?.isPinned = isPined;
    notifyListeners();
  }

  setMessageDisturb(bool value) async {
    final res = await _messageService.setGroupReceiveMessageOpt(
        groupID: _groupID,
        opt: value ? ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE : ReceiveMsgOptEnum.V2TIM_RECEIVE_MESSAGE);
    if (res.code == 0) {
      conversation?.recvOpt =
          (value ? ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE : ReceiveMsgOptEnum.V2TIM_RECEIVE_MESSAGE).index;
    }
    notifyListeners();
  }

  Future<V2TimValueCallback<V2GroupMemberInfoSearchResult>> searchGroupMember(
      V2TimGroupMemberSearchParam searchParam) async {
    final res = await _groupServices.searchGroupMembers(searchParam: searchParam);

    if (res.code == 0) {}
    return res;
  }

  Future<V2TimCallback?> setGroupName(String groupName) async {
    if (_groupInfo != null) {
      String? originalGroupName = _groupInfo?.groupName;
      _groupInfo?.groupName = groupName;
      V2TimGroupInfo v2timGroupInfo = V2TimGroupInfo(groupID: _groupID, groupType: _groupInfo!.groupType);
      v2timGroupInfo.groupName = groupName;
      final response = await _groupServices.setGroupInfo(info: v2timGroupInfo);
      if (response.code != 0) {
        _groupInfo?.groupName = originalGroupName;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  setGroupNotification(String notification) async {
    if (_groupInfo != null) {
      V2TimGroupInfo v2timGroupInfo = V2TimGroupInfo(groupID: _groupID, groupType: _groupInfo!.groupType);
      v2timGroupInfo.notification = notification;
      final response = await _groupServices.setGroupInfo(info: v2timGroupInfo);
      if (response.code == 0) {
        notifyListeners();
        _groupInfo?.notification = notification;
      }
    }
  }

  String getSelfNameCard() {
    try {
      final loginUserID = _coreServices.loginUserInfo?.userID;
      String nameCard = "";
      if (_groupMemberList != null) {
        nameCard = groupMemberList.firstWhere((element) => element?.userID == loginUserID)?.nameCard ?? "";
      }

      return nameCard;
    } catch (err) {
      return "";
    }
  }

  Future<V2TimCallback?> setNameCard(String nameCard) async {
    final loginUserID = _coreServices.loginUserInfo?.userID;
    if (loginUserID != null) {
      final res = await _groupServices.setGroupMemberInfo(groupID: _groupID, userID: loginUserID, nameCard: nameCard);
      if (res.code == 0) {
        final targetIndex = _groupMemberList?.indexWhere((element) => element?.userID == loginUserID);
        if (targetIndex != -1) {
          _groupMemberList![targetIndex!]!.nameCard = nameCard;
          notifyListeners();
        }
      }
      return res;
    }
    return null;
  }

  Future<V2TimCallback?> setGroupAddOpt(int addOpt) async {
    if (_groupInfo != null) {
      int? originalAddopt = _groupInfo?.groupAddOpt;
      _groupInfo?.groupAddOpt = addOpt;
      V2TimGroupInfo v2timGroupInfo = V2TimGroupInfo(groupID: _groupID, groupType: _groupInfo!.groupType);
      v2timGroupInfo.groupAddOpt = addOpt;
      final response = await _groupServices.setGroupInfo(info: v2timGroupInfo);
      if (response.code != 0) {
        _groupInfo?.groupAddOpt = originalAddopt;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  Future<V2TimCallback> setMemberToNormal(String userID) async {
    final res = await _groupServices.setGroupMemberRole(
        groupID: _groupID, userID: userID, role: GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_MEMBER);
    if (res.code == 0) {
      final targetIndex = _groupMemberList!.indexWhere((e) => e!.userID == userID);
      if (targetIndex != -1) {
        final targetElem = _groupMemberList![targetIndex];
        targetElem?.role = GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER;
        _groupMemberList![targetIndex] = targetElem;
      }
      notifyListeners();
    }
    return res;
  }

  Future<V2TimCallback> setMemberToAdmin(String userID) async {
    final res = await _groupServices.setGroupMemberRole(
        groupID: _groupID, userID: userID, role: GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_ADMIN);
    if (res.code == 0) {
      final targetIndex = _groupMemberList!.indexWhere((e) => e!.userID == userID);
      if (targetIndex != -1) {
        final targetElem = _groupMemberList![targetIndex];
        targetElem?.role = GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN;
        _groupMemberList![targetIndex] = targetElem;
      }
      notifyListeners();
    }
    return res;
  }

  void onOwnerChanged(String? userID) {
    if (userID == null) {
      return;
    }

    // 把之前的群主更新为普通成员
    final preOwnerIndex =
        _groupMemberList!.indexWhere((e) => e!.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER);
    if (preOwnerIndex != -1) {
      final preOwnerElem = _groupMemberList![preOwnerIndex];
      preOwnerElem?.role = GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER;

      print("preOwnerUserID: ${preOwnerElem?.userID}");
    }

    // 设置新的群主
    final targetIndex = _groupMemberList!.indexWhere((e) => e!.userID == userID);
    if (targetIndex != -1) {
      final targetElem = _groupMemberList![targetIndex];
      targetElem?.role = GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER;
      _groupMemberList![targetIndex] = targetElem;

      print("newOwnerUserID: ${targetElem?.userID}");
    }

    notifyListeners();
  }

  bool canInviteMember() {
    final groupType = _groupInfo?.groupType;
    return groupType == GroupType.Work || groupType == "Private";
  }

  bool canKickOffMember() {
    final isGroupOwner = _groupInfo?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER;
    final isAdmin = _groupInfo?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN;
    if (_groupInfo?.groupType == GroupType.Work) {
      /// work 群主才能踢人
      return isGroupOwner;
    }

    if (_groupInfo?.groupType == GroupType.Public || _groupInfo?.groupType == GroupType.Meeting) {
      /// public || meeting 群主和管理员可以踢人
      return isGroupOwner || isAdmin;
    }

    return false;
  }

  Future<V2TimCallback?> setMuteAll(bool muteAll) async {
    if (_groupInfo != null) {
      _groupInfo?.isAllMuted = muteAll;
      V2TimGroupInfo v2timGroupInfo = V2TimGroupInfo(groupID: _groupID, groupType: _groupInfo!.groupType);
      v2timGroupInfo.isAllMuted = muteAll;
      final response = await _groupServices.setGroupInfo(info: v2timGroupInfo);
      if (response.code != 0) {
        _groupInfo?.isAllMuted = muteAll;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  Future<V2TimCallback?> muteGroupMember(String userID, bool isMute, int? serverTime) async {
    const muteTime = 315360000;
    final res = await _groupServices.muteGroupMember(groupID: _groupID, userID: userID, seconds: isMute ? muteTime : 0);
    if (res.code == 0) {
      final targetIndex = _groupMemberList!.indexWhere((e) => e!.userID == userID);
      if (targetIndex != -1) {
        final targetElem = _groupMemberList![targetIndex];
        targetElem?.muteUntil = isMute ? (serverTime ?? 0) + muteTime : 0;
        _groupMemberList![targetIndex] = targetElem;
      }
      notifyListeners();
    }
    return null;
  }

  Future<V2TimCallback> kickOffMember(List<String> userIDs) async {
    final res = await _groupServices.kickGroupMember(groupID: _groupID, memberList: userIDs);
    return res;
  }

  Future<V2TimValueCallback<List<V2TimGroupMemberOperationResult>>> inviteUserToGroup(List<String> userIDS) async {
    final res = await _groupServices.inviteUserToGroup(groupID: _groupID, userList: userIDS);
    return res;
  }
}
