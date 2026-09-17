import '../../manage_imports.dart';

enum DialogType { CONFIRMATION, ACCEPT, DELETE, UPDATE, ADD, RETRY }

enum DialogAnimation {
  DEFAULT,
  ROTATE,
  SLIDE_TOP_BOTTOM,
  SLIDE_BOTTOM_TOP,
  SLIDE_LEFT_RIGHT,
  SLIDE_RIGHT_LEFT,
  SCALE
}

Color getDialogPrimaryColor(
  BuildContext context,
  DialogType dialogType,
  Color? primaryColor,
) {
  if (primaryColor != null) return primaryColor;
  Color color;

  switch (dialogType) {
    case DialogType.DELETE:
      color = Colors.red;
      break;
    case DialogType.UPDATE:
      color = Colors.amber;
      break;
    case DialogType.CONFIRMATION:
    case DialogType.ADD:
    case DialogType.RETRY:
      color = Colors.blue;
      break;
    case DialogType.ACCEPT:
      color = Colors.green;
      break;
  }
  return color;
}

String getPositiveText(DialogType dialogType) {
  String positiveText = "";

  switch (dialogType) {
    case DialogType.CONFIRMATION:
      positiveText = "Yes";
      break;
    case DialogType.DELETE:
      positiveText = "Delete";
      break;
    case DialogType.UPDATE:
      positiveText = "Update";
      break;
    case DialogType.ADD:
      positiveText = "Add";
      break;
    case DialogType.ACCEPT:
      positiveText = "Accept";
      break;
    case DialogType.RETRY:
      positiveText = "Retry";
      break;
  }
  return positiveText;
}

String getTitle(DialogType dialogType) {
  String titleText = "";

  switch (dialogType) {
    case DialogType.CONFIRMATION:
      titleText = "Are you sure want to perform this action?";
      break;
    case DialogType.DELETE:
      titleText = "Do you want to delete?";
      break;
    case DialogType.UPDATE:
      titleText = "Do you want to update?";
      break;
    case DialogType.ADD:
      titleText = "Do you want to add?";
      break;
    case DialogType.ACCEPT:
      titleText = "Do you want to accept?";
      break;
    case DialogType.RETRY:
      titleText = "Click to retry";
      break;
  }
  return titleText;
}

Widget getIcon(DialogType dialogType, {double? size}) {
  Icon icon;

  switch (dialogType) {
    case DialogType.CONFIRMATION:
    case DialogType.RETRY:
    case DialogType.ACCEPT:
      icon = Icon(Icons.done, size: size ?? 20, color: Colors.white);
      break;
    case DialogType.DELETE:
      icon = Icon(Icons.delete_forever_outlined,
          size: size ?? 20, color: Colors.white);
      break;
    case DialogType.UPDATE:
      icon = Icon(Icons.edit, size: size ?? 20, color: Colors.white);
      break;
    case DialogType.ADD:
      icon = Icon(Icons.add, size: size ?? 20, color: Colors.white);
      break;
  }
  return icon;
}

Widget? getCenteredImage(
    BuildContext context, DialogType dialogType, Color? primaryColor) {
  Widget? widget;

  switch (dialogType) {
    case DialogType.CONFIRMATION:
      widget = Container(
        decoration: BoxDecoration(
          color: getDialogPrimaryColor(context, dialogType, primaryColor)
              .withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.warning_amber_rounded,
            color: getDialogPrimaryColor(context, dialogType, primaryColor),
            size: 40),
        padding: EdgeInsets.all(16),
      );
      break;
    case DialogType.DELETE:
      widget = Container(
        decoration: BoxDecoration(
            color: getDialogPrimaryColor(context, dialogType, primaryColor)
                .withValues(alpha: 0.2),
            shape: BoxShape.circle),
        child: Icon(Icons.close,
            color: getDialogPrimaryColor(context, dialogType, primaryColor),
            size: 40),
        padding: EdgeInsets.all(16),
      );
      break;
    case DialogType.UPDATE:
      widget = Container(
        decoration: BoxDecoration(
            color: getDialogPrimaryColor(context, dialogType, primaryColor)
                .withValues(alpha: 0.2),
            shape: BoxShape.circle),
        child: Icon(Icons.edit_outlined,
            color: getDialogPrimaryColor(context, dialogType, primaryColor),
            size: 40),
        padding: EdgeInsets.all(16),
      );
      break;
    case DialogType.ADD:
    case DialogType.ACCEPT:
      widget = Container(
        decoration: BoxDecoration(
          color: getDialogPrimaryColor(context, dialogType, primaryColor)
              .withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.done_outline,
            color: getDialogPrimaryColor(context, dialogType, primaryColor),
            size: 40),
        padding: EdgeInsets.all(16),
      );
      break;
    case DialogType.RETRY:
      widget = Container(
        decoration: BoxDecoration(
          color: getDialogPrimaryColor(context, dialogType, primaryColor)
              .withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.refresh_rounded,
            color: getDialogPrimaryColor(context, dialogType, primaryColor),
            size: 40),
        padding: EdgeInsets.all(16),
      );
      break;
  }
  return widget;
}

Widget defaultPlaceHolder(
  BuildContext context,
  DialogType dialogType,
  double? height,
  double? width,
  Color? primaryColor, {
  Widget? child,
  ShapeBorder? shape,
}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: getDialogPrimaryColor(context, dialogType, primaryColor)
          .withValues(alpha: 0.2),
    ),
    alignment: Alignment.center,
    child: child ?? getCenteredImage(context, dialogType, primaryColor),
  );
}

Widget buildTitleWidget(
  BuildContext context,
  DialogType dialogType,
  Color? primaryColor,
  Widget? customCenterWidget,
  double height,
  double width,
  String? centerImage,
  ShapeBorder? shape,
) {
  if (customCenterWidget != null) {
    return Container(
      child: customCenterWidget,
      constraints: BoxConstraints(maxHeight: height, maxWidth: width),
    );
  } else {
    if (centerImage != null) {
      return Image.network(
        centerImage,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, object, stack) {
          log(object.toString());
          return defaultPlaceHolder(
              context, dialogType, height, width, primaryColor,
              shape: shape);
        },
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return defaultPlaceHolder(
            context,
            dialogType,
            height,
            width,
            primaryColor,
            shape: shape,
            child: Loader(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return defaultPlaceHolder(
          context, dialogType, height, width, primaryColor,
          shape: shape);
    }
  }
}

/// show confirm dialog box
Future<bool?> showConfirmDialogCustom(
  BuildContext context, {
  required Function(BuildContext) onAccept,
  String? title,
  String? subTitle,
  String? positiveText,
  String? negativeText,
  String? centerImage,
  Widget? customCenterWidget,
  Color? primaryColor,
  Color? positiveTextColor,
  Color? negativeTextColor,
  ShapeBorder? shape,
  Function(BuildContext)? onCancel,
  bool barrierDismissible = true,
  double? height,
  double? width,
  bool cancelable = true,
  Color? barrierColor,
  DialogType dialogType = DialogType.CONFIRMATION,
  DialogAnimation dialogAnimation = DialogAnimation.DEFAULT,
  Duration? transitionDuration,
  Curve curve = Curves.easeInBack,
}) async {
  hideKeyboard(context);

  return await showGeneralDialog(
    context: context,
    barrierColor: barrierColor ?? Color(0x8C0B1220),
    barrierDismissible: barrierDismissible,
    barrierLabel: '',
    transitionDuration: transitionDuration ?? Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => SizedBox.shrink(),
    transitionBuilder: (_, animation, secondaryAnimation, child) {
      final isDanger = dialogType == DialogType.DELETE;
      final accent = isDanger ? Color(0xFFD93025) : (primaryColor ?? getDialogPrimaryColor(_, dialogType, null));
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      IconData icon;
      switch (dialogType) {
        case DialogType.DELETE:
          icon = Icons.close_rounded;
          break;
        case DialogType.ACCEPT:
          icon = Icons.check_rounded;
          break;
        case DialogType.UPDATE:
          icon = Icons.edit_rounded;
          break;
        case DialogType.ADD:
          icon = Icons.add_rounded;
          break;
        case DialogType.RETRY:
          icon = Icons.refresh_rounded;
          break;
        case DialogType.CONFIRMATION:
          icon = Icons.help_outline_rounded;
          break;
      }

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 28),
            shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 26, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    customCenterWidget ??
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
                          child: Icon(icon, color: accent, size: 30),
                        ),
                    SizedBox(height: 16),
                    Text(
                      title ?? getTitle(dialogType),
                      style: boldTextStyle(size: 17),
                      textAlign: TextAlign.center,
                    ),
                    if ((subTitle ?? '').isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(subTitle!, style: secondaryTextStyle(size: 14), textAlign: TextAlign.center),
                    ],
                    SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: negativeTextColor ?? textPrimaryColorGlobal,
                                side: BorderSide(color: Color(0xFFE2E6ED), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                if (cancelable) Navigator.pop(_, false);
                                onCancel?.call(_);
                              },
                              child: FittedBox(child: Text(negativeText ?? language.cancel, style: boldTextStyle(size: 15, color: negativeTextColor ?? textPrimaryColorGlobal))),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                // close this popup first: the action may open its own dialog (e.g. the closing
                                // odometer on End Ride) and popping afterwards would close that dialog instead
                                if (cancelable) Navigator.pop(context, true);
                                onAccept.call(context);
                              },
                              child: FittedBox(child: Text(positiveText ?? getPositiveText(dialogType), style: boldTextStyle(size: 15, color: positiveTextColor ?? Colors.white))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget dialogAnimatedWrapperWidget({
  required Animation<double> animation,
  required Widget child,
  required DialogAnimation dialogAnimation,
  required Curve curve,
}) {
  switch (dialogAnimation) {
    case DialogAnimation.ROTATE:
      return Transform.rotate(
        angle: radians(animation.value * 360),
        child: Opacity(
            opacity: animation.value,
            child: FadeTransition(opacity: animation, child: child)),
      );

    case DialogAnimation.SLIDE_TOP_BOTTOM:
      final curvedValue = curve.transform(animation.value) - 1.0;

      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * 300, 0.0),
        child: Opacity(
            opacity: animation.value,
            child: FadeTransition(opacity: animation, child: child)),
      );

    case DialogAnimation.SCALE:
      return Transform.scale(
          scale: animation.value,
          child: FadeTransition(opacity: animation, child: child));

    case DialogAnimation.SLIDE_BOTTOM_TOP:
      return SlideTransition(
        position: Tween(begin: Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: curve))
            .animate(animation),
        child: Opacity(
            opacity: animation.value,
            child: FadeTransition(opacity: animation, child: child)),
      );

    case DialogAnimation.SLIDE_LEFT_RIGHT:
      return SlideTransition(
        position: Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: curve))
            .animate(animation),
        child: Opacity(
            opacity: animation.value,
            child: FadeTransition(opacity: animation, child: child)),
      );

    case DialogAnimation.SLIDE_RIGHT_LEFT:
      return SlideTransition(
        position: Tween(begin: Offset(-1, 0), end: Offset.zero)
            .chain(CurveTween(curve: curve))
            .animate(animation),
        child: Opacity(
            opacity: animation.value,
            child: FadeTransition(opacity: animation, child: child)),
      );

    case DialogAnimation.DEFAULT:
      return FadeTransition(opacity: animation, child: child);
  }
}
