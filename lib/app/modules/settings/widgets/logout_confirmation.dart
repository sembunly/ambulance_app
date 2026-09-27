import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

Future<void> confirmLogout(
  BuildContext context,
  Future<void> Function() logout,
) async {
  final shouldLogout = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text('SIGN_OUT_PROMPT'.tr),
      message: Text('SIGN_OUT_DESCRIPTION'.tr),
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
          child: Text('SIGN_OUT'.tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(sheetContext).pop(false),
        child: Text('CANCEL'.tr),
      ),
    ),
  );
  if (shouldLogout == true && context.mounted) await logout();
}
