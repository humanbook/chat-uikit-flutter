// ignore_for_file: must_be_immutable

import 'package:azlistview_all_platforms/azlistview_all_platforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable_plus_plus/flutter_slidable_plus_plus.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:provider/provider.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/optimize_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/az_list_view.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/radio_button.dart';
import 'package:tencent_cloud_chat_uikit/theme/color.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme_view_model.dart';

class GroupProfileMemberList extends StatefulWidget {
  static String AT_ALL_USER_ID = "__kImSDK_MesssageAtALL__";
  final List<V2TimGroupMemberFullInfo?> memberList;
  final Function(String userID)? removeMember;
  final bool canSlideDelete;
  final bool canSelectMember;
  final bool canAtAll;

  // when the @ need filter some group types
  final String? groupType;
  final Function(List<V2TimGroupMemberFullInfo> selectedMember)? onSelectedMemberChange;
  // notice: onTapMemberItem and onSelectedMemberChange use together will triger together
  final Function(V2TimGroupMemberFullInfo memberInfo, TapDownDetails? tapDetails)? onTapMemberItem;
  // When sliding to the bottom bar callBack
  final Function()? touchBottomCallBack;

  final int? maxSelectNum;

  Widget? customTopArea;

  GroupProfileMemberList({
    Key? key,
    required this.memberList,
    this.groupType,
    this.removeMember,
    this.canSlideDelete = true,
    this.canSelectMember = false,
    this.canAtAll = false,
    this.onSelectedMemberChange,
    this.onTapMemberItem,
    this.customTopArea,
    this.touchBottomCallBack,
    this.maxSelectNum,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupProfileMemberListState();
}

class _GroupProfileMemberListState extends TIMUIKitState<GroupProfileMemberList> {
  List<V2TimGroupMemberFullInfo> selectedMemberList = [];

  _getShowName(V2TimGroupMemberFullInfo? item) {
    final friendRemark = item?.friendRemark ?? "";
    final nameCard = item?.nameCard ?? "";
    final nickName = item?.nickName ?? "";
    final userID = item?.userID ?? "";
    return friendRemark.isNotEmpty
        ? friendRemark
        : nameCard.isNotEmpty
            ? nameCard
            : nickName.isNotEmpty
                ? nickName
                : userID;
  }

  List<ISuspensionBeanImpl> _getShowList(List<V2TimGroupMemberFullInfo?> memberList) {
    final List<ISuspensionBeanImpl> showList = List.empty(growable: true);
    for (var i = 0; i < memberList.length; i++) {
      final item = memberList[i];
      final showName = _getShowName(item);
      if (item?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER ||
          item?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN) {
        showList.add(ISuspensionBeanImpl(memberInfo: item, tagIndex: "@"));
      } else {
        String pinyin = PinyinHelper.getPinyinE(showName);
        String tag = pinyin.substring(0, 1).toUpperCase();
        if (RegExp("[A-Z]").hasMatch(tag)) {
          showList.add(ISuspensionBeanImpl(memberInfo: item, tagIndex: tag));
        } else {
          showList.add(ISuspensionBeanImpl(memberInfo: item, tagIndex: "#"));
        }
      }
    }

    SuspensionUtil.sortListBySuspensionTag(showList);

    // add @everyone item
    if (widget.canAtAll) {
      final canAtGroupType = ["Work", "Public", "Meeting"];
      if (canAtGroupType.contains(widget.groupType)) {
        showList.insert(
            0,
            ISuspensionBeanImpl(
                memberInfo:
                    V2TimGroupMemberFullInfo(userID: GroupProfileMemberList.AT_ALL_USER_ID, nickName: TIM_t("所有人")),
                tagIndex: ""));
      }
    }

    return showList;
  }

  Widget _buildListItem(BuildContext context, V2TimGroupMemberFullInfo memberInfo) {
    final theme = Provider.of<TUIThemeViewModel>(context).theme;
    final isDesktopScreen = TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;
    final isGroupMember = memberInfo.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER;
    return Container(
        color: Colors.white,
        child: Slidable(
            endActionPane: widget.canSlideDelete && isGroupMember
                ? ActionPane(motion: const DrawerMotion(), children: [
                    SlidableAction(
                      onPressed: (_) {
                        if (widget.removeMember != null) {
                          widget.removeMember!(memberInfo.userID);
                        }
                      },
                      flex: 1,
                      backgroundColor: theme.cautionColor ?? CommonColor.cautionColor,
                      autoClose: true,
                      label: TIM_t("删除"),
                    )
                  ])
                : null,
            child: Column(children: [
              ListTile(
                tileColor: Colors.black,
                title: Row(
                  children: [
                    if (widget.canSelectMember)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: CheckBoxButton(
                            onChanged: (isChecked) {
                              if (isChecked) {
                                if (widget.maxSelectNum != null && selectedMemberList.length >= widget.maxSelectNum!) {
                                  return;
                                }
                                selectedMemberList.add(memberInfo);
                              } else {
                                selectedMemberList.removeWhere((element) => element.userID == memberInfo.userID);
                              }

                              if (widget.onSelectedMemberChange != null) {
                                widget.onSelectedMemberChange!(selectedMemberList);
                              }
                              setState(() {});
                            },
                            isChecked: selectedMemberList
                                .where((element) => element.userID == memberInfo.userID)
                                .toList()
                                .isNotEmpty),
                      ),
                    Container(
                      width: isDesktopScreen ? 30 : 36,
                      height: isDesktopScreen ? 30 : 36,
                      margin: const EdgeInsets.only(right: 10),
                      child: Avatar(
                        faceUrl: memberInfo.faceUrl ?? "",
                        showName: _getShowName(memberInfo),
                        type: 1,
                      ),
                    ),
                    Text(_getShowName(memberInfo), style: TextStyle(fontSize: isDesktopScreen ? 14 : 16)),
                    memberInfo.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER
                        ? Container(
                            margin: const EdgeInsets.only(left: 5),
                            child: Text(TIM_t("群主"),
                                style: TextStyle(
                                  color: theme.ownerColor,
                                  fontSize: isDesktopScreen ? 10 : 12,
                                )),
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.ownerColor ?? CommonColor.ownerColor, width: 1),
                              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                            ),
                          )
                        : memberInfo.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN
                            ? Container(
                                margin: const EdgeInsets.only(left: 5),
                                child: Text(TIM_t("管理员"),
                                    style: TextStyle(
                                      color: theme.adminColor,
                                      fontSize: 12,
                                    )),
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.adminColor ?? CommonColor.adminColor, width: 1),
                                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                ),
                              )
                            : Container()
                  ],
                ),
                onTap: () {
                  if (widget.onTapMemberItem != null) {
                    widget.onTapMemberItem!(memberInfo, null);
                  }
                  if (widget.canSelectMember) {
                    final isChecked = selectedMemberList.contains(memberInfo);
                    if (isChecked) {
                      selectedMemberList.remove(memberInfo);
                    } else {
                      if (widget.maxSelectNum != null && selectedMemberList.length >= widget.maxSelectNum!) {
                        return;
                      }
                      selectedMemberList.add(memberInfo);
                    }
                    if (widget.onSelectedMemberChange != null) {
                      widget.onSelectedMemberChange!(selectedMemberList);
                    }
                    setState(() {});
                  }
                },
              ),
              Divider(thickness: 1, indent: 74, endIndent: 0, color: theme.weakBackgroundColor, height: 0)
            ])));
  }

  static Widget getSusItem(BuildContext context, TUITheme theme, String tag, {double susHeight = 40}) {
    if (tag == '@') {
      tag = TIM_t("群主、管理员");
    }
    return Container(
      height: susHeight,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 16.0),
      color: theme.weakBackgroundColor,
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        softWrap: true,
        style: TextStyle(
          fontSize: 14.0,
          color: theme.darkTextColor,
        ),
      ),
    );
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    final isDesktopScreen = TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;

    final throteFunction = OptimizeUtils.throttle((ScrollNotification notification) {
      final pixels = notification.metrics.pixels;
      // 总像素高度
      final maxScrollExtent = notification.metrics.maxScrollExtent;
      // 滑动百分比
      final progress = pixels / maxScrollExtent;
      if (progress >= 0.9 && widget.touchBottomCallBack != null) {
        widget.touchBottomCallBack!();
      }
    }, 300);
    final showList = _getShowList(widget.memberList);
    return Container(
      color: isDesktopScreen ? null : theme.weakBackgroundColor,
      child: SafeArea(
          child: Column(
        children: [
          widget.customTopArea != null ? widget.customTopArea! : Container(),
          Expanded(
              child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              throteFunction(notification);
              return true;
            },
            child: (showList.isEmpty)
                ? Center(
                    child: Text(TIM_t("暂无群成员")),
                  )
                : Container(
                    padding: isDesktopScreen ? const EdgeInsets.symmetric(horizontal: 16) : null,
                    child: AZListViewContainer(
                        memberList: showList,
                        susItemBuilder: (context, index) {
                          final model = showList[index];
                          return getSusItem(context, theme, model.getSuspensionTag());
                        },
                        itemBuilder: (context, index) {
                          final memberInfo = showList[index].memberInfo as V2TimGroupMemberFullInfo;

                          return _buildListItem(context, memberInfo);
                        }),
                  ),
          ))
        ],
      )),
    );
  }
}
