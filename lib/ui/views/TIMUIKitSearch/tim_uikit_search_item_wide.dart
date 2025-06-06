import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/theme/color.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';

class TIMUIKitSearchWideItem extends TIMUIKitStatelessWidget {
  final String faceUrl;
  final String showName;
  final String lineOne;
  final String? lineOneRight;
  final String? lineTwo;
  final VoidCallback? onClick;

  TIMUIKitSearchWideItem(
      {Key? key,
      required this.faceUrl,
      required this.showName,
      required this.lineOne,
      this.lineTwo,
      this.lineOneRight,
      this.onClick})
      : super(key: key);

  _renderLineOneRight(String? text, TUITheme theme) {
    if (text != null) {
      return Text(text,
          style: TextStyle(
            fontSize: 10,
            color: theme.weakTextColor,
          ));
    } else {
      return Container();
    }
  }

  _renderLineTwo(String? text, TUITheme theme) {
    return (text != null)
        ? Container(
            margin: const EdgeInsets.only(top: 0),
            child: SelectableText(
              text,
              style: TextStyle(
                  color: theme.weakTextColor, height: 1.5, fontSize: 12),
            ),
          )
        : Container(
            height: 0,
          );
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onClick,
        child: Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: hexToColor("DBDBDB"), width: 0.5))),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Avatar(faceUrl: faceUrl, showName: showName, isShowBigWhenClick: false,),
              ),
              Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          // height: 24,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: Text(
                                lineOne,
                                style: TextStyle(
                                    color: theme.darkTextColor,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w400),
                              )),
                              _renderLineOneRight(lineOneRight, theme),
                            ],
                          ),
                        ),
                        _renderLineTwo(lineTwo, theme),
                      ],
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
