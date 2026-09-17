import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Colors.dart';

/// S Taxi design tokens: royal blue brand, white surfaces, soft grey-blue fills.
class BrandTokens {
  static const blue = brandBlue;
  static const blueDark = Color(0xFF072C6E);
  static const blueSoft = Color(0xFFEAF1FC);
  static const ink = Color(0xFF14181F);
  static const inkSoft = Color(0xFF5B6472);
  static const line = Color(0xFFE6E9EF);
  static const fill = Color(0xFFF4F6FA);
  static const page = Color(0xFFF6F8FB);
  static const success = Color(0xFF1E9E57);
  static const warning = Color(0xFFE08A00);
  static const danger = Color(0xFFD93025);

  static const radius = 14.0;
  static const radiusLarge = 22.0;
  static const font = 'Poppins';

  static List<BoxShadow> softShadow = [BoxShadow(color: Color(0x140A3D96), blurRadius: 18, offset: Offset(0, 6))];
}

class BrandTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: BrandTokens.blue, brightness: Brightness.light).copyWith(
      primary: BrandTokens.blue,
      onPrimary: Colors.white,
      primaryContainer: BrandTokens.blueSoft,
      onPrimaryContainer: BrandTokens.blueDark,
      secondary: BrandTokens.blue,
      surface: Colors.white,
      onSurface: BrandTokens.ink,
      onSurfaceVariant: BrandTokens.inkSoft,
      surfaceTint: Colors.transparent,
      // Material 3 builds these from the seed and they show as lavender on sheets/dialogs
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Colors.white,
      surfaceContainerHighest: BrandTokens.fill,
      outline: BrandTokens.line,
      outlineVariant: BrandTokens.line,
      error: BrandTokens.danger,
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(BrandTokens.radius));
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: BrandTokens.font);

    return base.copyWith(
      primaryColor: BrandTokens.blue,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: BrandTokens.line,
      splashFactory: InkRipple.splashFactory,
      textTheme: base.textTheme.apply(bodyColor: BrandTokens.ink, displayColor: BrandTokens.ink, fontFamily: BrandTokens.font),
      iconTheme: IconThemeData(color: BrandTokens.ink),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: BrandTokens.blue, circularTrackColor: BrandTokens.blueSoft),
      dividerTheme: DividerThemeData(color: BrandTokens.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: BrandTokens.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: BrandTokens.font, color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark),
      ),
      cardTheme: CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: BrandTokens.line)), margin: EdgeInsets.zero),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.white,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(BrandTokens.radiusLarge))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BrandTokens.radiusLarge)),
        titleTextStyle: TextStyle(fontFamily: BrandTokens.font, color: BrandTokens.ink, fontSize: 18, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(fontFamily: BrandTokens.font, color: BrandTokens.inkSoft, fontSize: 14, height: 1.4),
      ),
      popupMenuTheme: PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent, shape: shape),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, indicatorColor: BrandTokens.blueSoft),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: Colors.white, selectedItemColor: BrandTokens.blue, unselectedItemColor: BrandTokens.inkSoft, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandTokens.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BrandTokens.line,
          elevation: 0,
          minimumSize: Size(64, 50),
          shape: shape,
          textStyle: TextStyle(fontFamily: BrandTokens.font, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: BrandTokens.blue, foregroundColor: Colors.white, minimumSize: Size(64, 50), shape: shape, textStyle: TextStyle(fontFamily: BrandTokens.font, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: BrandTokens.blue, minimumSize: Size(64, 50), shape: shape, side: BorderSide(color: BrandTokens.line, width: 1.2), textStyle: TextStyle(fontFamily: BrandTokens.font, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: BrandTokens.blue, textStyle: TextStyle(fontFamily: BrandTokens.font, fontWeight: FontWeight.w600))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandTokens.fill,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(fontFamily: BrandTokens.font, color: Color(0xFF98A1AE), fontSize: 14),
        labelStyle: TextStyle(fontFamily: BrandTokens.font, color: BrandTokens.inkSoft, fontSize: 14),
        floatingLabelStyle: TextStyle(fontFamily: BrandTokens.font, color: BrandTokens.blue, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(BrandTokens.radius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BrandTokens.radius), borderSide: BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BrandTokens.radius), borderSide: BorderSide(color: BrandTokens.blue, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BrandTokens.radius), borderSide: BorderSide(color: BrandTokens.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BrandTokens.radius), borderSide: BorderSide(color: BrandTokens.danger, width: 1.4)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: BrandTokens.blue,
        side: BorderSide(color: BrandTokens.line),
        labelStyle: TextStyle(fontFamily: BrandTokens.font, fontSize: 13, color: BrandTokens.ink),
        secondaryLabelStyle: TextStyle(fontFamily: BrandTokens.font, fontSize: 13, color: Colors.white),
        shape: StadiumBorder(),
        showCheckmark: false,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BrandTokens.blue : Colors.transparent),
        side: BorderSide(color: Color(0xFFB7BFCB), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BrandTokens.blue : Color(0xFFB7BFCB))),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BrandTokens.success : Color(0xFFCBD2DC)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(backgroundColor: BrandTokens.ink, behavior: SnackBarBehavior.floating, shape: shape, contentTextStyle: TextStyle(fontFamily: BrandTokens.font, color: Colors.white)),
      listTileTheme: ListTileThemeData(iconColor: BrandTokens.inkSoft, titleTextStyle: TextStyle(fontFamily: BrandTokens.font, color: BrandTokens.ink, fontSize: 15, fontWeight: FontWeight.w500)),
      tabBarTheme: TabBarThemeData(labelColor: BrandTokens.blue, unselectedLabelColor: BrandTokens.inkSoft, indicatorColor: BrandTokens.blue, dividerColor: Colors.transparent),
      textSelectionTheme: TextSelectionThemeData(cursorColor: BrandTokens.blue, selectionHandleColor: BrandTokens.blue, selectionColor: BrandTokens.blue.withValues(alpha: 0.25)),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
