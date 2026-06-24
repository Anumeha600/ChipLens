import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/ui/theme/theme.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // DesignTokens
  // ──────────────────────────────────────────────────────────────────────────

  group('DesignTokens — spacing scale', () {
    test('spacingXS is 4', () => expect(DesignTokens.spacingXS, 4.0));
    test('spacingSM is 8', () => expect(DesignTokens.spacingSM, 8.0));
    test('spacingMD is 16', () => expect(DesignTokens.spacingMD, 16.0));
    test('spacingLG is 24', () => expect(DesignTokens.spacingLG, 24.0));
    test('spacingXL is 32', () => expect(DesignTokens.spacingXL, 32.0));
    test('spacingXXL is 48', () => expect(DesignTokens.spacingXXL, 48.0));
    test('spacingXXXL is 64', () => expect(DesignTokens.spacingXXXL, 64.0));
    test('spacing values are strictly ascending', () {
      expect(DesignTokens.spacingXS, lessThan(DesignTokens.spacingSM));
      expect(DesignTokens.spacingSM, lessThan(DesignTokens.spacingMD));
      expect(DesignTokens.spacingMD, lessThan(DesignTokens.spacingLG));
      expect(DesignTokens.spacingLG, lessThan(DesignTokens.spacingXL));
      expect(DesignTokens.spacingXL, lessThan(DesignTokens.spacingXXL));
    });
  });

  group('DesignTokens — animation durations', () {
    test('defaultAnimation is 200 ms', () {
      expect(DesignTokens.defaultAnimation,
          const Duration(milliseconds: 200));
    });
    test('animationFast < animationNormal', () {
      expect(DesignTokens.animationFast,
          lessThan(DesignTokens.animationNormal));
    });
    test('animationNormal < animationSlow', () {
      expect(DesignTokens.animationNormal,
          lessThan(DesignTokens.animationSlow));
    });
    test('animationSlow < animationVerySlow', () {
      expect(DesignTokens.animationSlow,
          lessThan(DesignTokens.animationVerySlow));
    });
  });

  group('DesignTokens — icon sizes', () {
    test('iconXS is 12', () => expect(DesignTokens.iconXS, 12.0));
    test('iconSM is 16', () => expect(DesignTokens.iconSM, 16.0));
    test('iconMD is 24', () => expect(DesignTokens.iconMD, 24.0));
    test('iconLG is 32', () => expect(DesignTokens.iconLG, 32.0));
    test('iconXL is 48', () => expect(DesignTokens.iconXL, 48.0));
  });

  group('DesignTokens — touch targets', () {
    test('minTouchTarget is 44', () {
      expect(DesignTokens.minTouchTarget, 44.0);
    });
    test('comfortableTouchTarget >= minTouchTarget', () {
      expect(DesignTokens.comfortableTouchTarget,
          greaterThanOrEqualTo(DesignTokens.minTouchTarget));
    });
  });

  group('DesignTokens — layout dimensions', () {
    test('toolbarHeight is 56', () {
      expect(DesignTokens.toolbarHeight, 56.0);
    });
    test('navigationRailWidthExtended > navigationRailWidth', () {
      expect(DesignTokens.navigationRailWidthExtended,
          greaterThan(DesignTokens.navigationRailWidth));
    });
    test('contentWidthNarrow < contentWidthNormal', () {
      expect(DesignTokens.contentWidthNarrow,
          lessThan(DesignTokens.contentWidthNormal));
    });
    test('contentWidthWide < contentWidthMax', () {
      expect(DesignTokens.contentWidthWide,
          lessThan(DesignTokens.contentWidthMax));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppColors
  // ──────────────────────────────────────────────────────────────────────────

  group('AppColors — primitive palette', () {
    test('primary is deep indigo', () {
      expect(AppColors.primary, const Color(0xFF4F46E5));
    });
    test('success is emerald', () {
      expect(AppColors.success, const Color(0xFF10B981));
    });
    test('warning is amber', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });
    test('error is red', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });
    test('info is blue', () {
      expect(AppColors.info, const Color(0xFF3B82F6));
    });
    test('primary and secondary are different colors', () {
      expect(AppColors.primary, isNot(AppColors.secondary));
    });
  });

  group('AppColors — light surface palette', () {
    test('lightSurface is white', () {
      expect(AppColors.lightSurface, const Color(0xFFFFFFFF));
    });
    test('textPrimaryLight is very dark', () {
      expect(AppColors.textPrimaryLight.r, lessThan(0.12));
    });
    test('lightOutline is defined', () {
      expect(AppColors.lightOutline, isA<Color>());
    });
  });

  group('AppColors — dark surface palette', () {
    test('darkSurface is near-black', () {
      expect(AppColors.darkSurface.r, lessThan(0.12));
    });
    test('textPrimaryDark is near-white', () {
      expect(AppColors.textPrimaryDark.r, greaterThan(0.78));
    });
    test('darkBackground is darker than darkSurface', () {
      expect(AppColors.darkBackground.r,
          lessThanOrEqualTo(AppColors.darkSurface.r));
    });
  });

  group('AppColors — color schemes', () {
    test('lightScheme brightness is light', () {
      expect(AppColors.lightScheme.brightness, Brightness.light);
    });
    test('darkScheme brightness is dark', () {
      expect(AppColors.darkScheme.brightness, Brightness.dark);
    });
    test('lightScheme error matches AppColors.error', () {
      expect(AppColors.lightScheme.error, AppColors.error);
    });
    test('darkScheme error matches AppColors.error', () {
      expect(AppColors.darkScheme.error, AppColors.error);
    });
    test('lightScheme surface matches lightSurface', () {
      expect(AppColors.lightScheme.surface, AppColors.lightSurface);
    });
    test('darkScheme surface matches darkSurface', () {
      expect(AppColors.darkScheme.surface, AppColors.darkSurface);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppTypography
  // ──────────────────────────────────────────────────────────────────────────

  group('AppTypography — font sizes', () {
    test('displayLarge is 57', () {
      expect(AppTypography.displayLarge.fontSize, 57.0);
    });
    test('displayMedium is 45', () {
      expect(AppTypography.displayMedium.fontSize, 45.0);
    });
    test('headlineLarge is 32', () {
      expect(AppTypography.headlineLarge.fontSize, 32.0);
    });
    test('headlineMedium is 28', () {
      expect(AppTypography.headlineMedium.fontSize, 28.0);
    });
    test('titleLarge is 22', () {
      expect(AppTypography.titleLarge.fontSize, 22.0);
    });
    test('titleMedium is 16', () {
      expect(AppTypography.titleMedium.fontSize, 16.0);
    });
    test('bodyLarge is 16', () {
      expect(AppTypography.bodyLarge.fontSize, 16.0);
    });
    test('bodyMedium is 14', () {
      expect(AppTypography.bodyMedium.fontSize, 14.0);
    });
    test('bodySmall is 12', () {
      expect(AppTypography.bodySmall.fontSize, 12.0);
    });
    test('labelLarge is 14', () {
      expect(AppTypography.labelLarge.fontSize, 14.0);
    });
    test('caption is 12', () {
      expect(AppTypography.caption.fontSize, 12.0);
    });
  });

  group('AppTypography — font weights', () {
    test('titleMedium is w500', () {
      expect(AppTypography.titleMedium.fontWeight, FontWeight.w500);
    });
    test('labelLarge is w500', () {
      expect(AppTypography.labelLarge.fontWeight, FontWeight.w500);
    });
    test('displayLarge is w400', () {
      expect(AppTypography.displayLarge.fontWeight, FontWeight.w400);
    });
  });

  group('AppTypography — textTheme', () {
    test('textTheme is a TextTheme', () {
      expect(AppTypography.textTheme, isA<TextTheme>());
    });
    test('textTheme.displayLarge is set', () {
      expect(AppTypography.textTheme.displayLarge, AppTypography.displayLarge);
    });
    test('textTheme.bodyMedium is set', () {
      expect(AppTypography.textTheme.bodyMedium, AppTypography.bodyMedium);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppRadius
  // ──────────────────────────────────────────────────────────────────────────

  group('AppRadius — BorderRadius values', () {
    test('none equals BorderRadius.zero', () {
      expect(AppRadius.none, BorderRadius.zero);
    });
    test('xs is 4 dp', () {
      expect(AppRadius.xs, const BorderRadius.all(Radius.circular(4.0)));
    });
    test('sm is 8 dp', () {
      expect(AppRadius.sm, const BorderRadius.all(Radius.circular(8.0)));
    });
    test('md is 12 dp', () {
      expect(AppRadius.md, const BorderRadius.all(Radius.circular(12.0)));
    });
    test('lg is 16 dp', () {
      expect(AppRadius.lg, const BorderRadius.all(Radius.circular(16.0)));
    });
    test('xl is 24 dp', () {
      expect(AppRadius.xl, const BorderRadius.all(Radius.circular(24.0)));
    });
    test('pill has a very large radius', () {
      expect(AppRadius.pill.topLeft.x, greaterThan(999.0));
    });
  });

  group('AppRadius — Radius values', () {
    test('radiusXS is 4 dp', () {
      expect(AppRadius.radiusXS, const Radius.circular(4.0));
    });
    test('radiusMD is 12 dp', () {
      expect(AppRadius.radiusMD, const Radius.circular(12.0));
    });
    test('radii are ascending', () {
      expect(AppRadius.radiusXS.x, lessThan(AppRadius.radiusSM.x));
      expect(AppRadius.radiusSM.x, lessThan(AppRadius.radiusMD.x));
      expect(AppRadius.radiusMD.x, lessThan(AppRadius.radiusLG.x));
      expect(AppRadius.radiusLG.x, lessThan(AppRadius.radiusXL.x));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppElevation
  // ──────────────────────────────────────────────────────────────────────────

  group('AppElevation — values', () {
    test('level0 is 0', () => expect(AppElevation.level0, 0.0));
    test('level1 is 1', () => expect(AppElevation.level1, 1.0));
    test('level2 is 3', () => expect(AppElevation.level2, 3.0));
    test('level3 is 6', () => expect(AppElevation.level3, 6.0));
    test('dialog is 24', () => expect(AppElevation.dialog, 24.0));
    test('menu is 8', () => expect(AppElevation.menu, 8.0));
    test('floating is 6', () => expect(AppElevation.floating, 6.0));
    test('levels are strictly ascending', () {
      expect(AppElevation.level0, lessThan(AppElevation.level1));
      expect(AppElevation.level1, lessThan(AppElevation.level2));
      expect(AppElevation.level2, lessThan(AppElevation.level3));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppIcons
  // ──────────────────────────────────────────────────────────────────────────

  group('AppIcons — icon data', () {
    test('dashboard has valid codePoint', () {
      expect(AppIcons.dashboard.codePoint, greaterThan(0));
    });
    test('folder has valid codePoint', () {
      expect(AppIcons.folder.codePoint, greaterThan(0));
    });
    test('settings has valid codePoint', () {
      expect(AppIcons.settings.codePoint, greaterThan(0));
    });
    test('search has valid codePoint', () {
      expect(AppIcons.search.codePoint, greaterThan(0));
    });
    test('play has valid codePoint', () {
      expect(AppIcons.play.codePoint, greaterThan(0));
    });
    test('stop has valid codePoint', () {
      expect(AppIcons.stop.codePoint, greaterThan(0));
    });
    test('success has valid codePoint', () {
      expect(AppIcons.success.codePoint, greaterThan(0));
    });
    test('warning has valid codePoint', () {
      expect(AppIcons.warning.codePoint, greaterThan(0));
    });
    test('failure has valid codePoint', () {
      expect(AppIcons.failure.codePoint, greaterThan(0));
    });
    test('verification has valid codePoint', () {
      expect(AppIcons.verification.codePoint, greaterThan(0));
    });
    test('all icons are distinct', () {
      final codePoints = {
        AppIcons.dashboard.codePoint,
        AppIcons.folder.codePoint,
        AppIcons.settings.codePoint,
        AppIcons.search.codePoint,
        AppIcons.success.codePoint,
        AppIcons.warning.codePoint,
        AppIcons.failure.codePoint,
      };
      expect(codePoints.length, 7);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppTheme
  // ──────────────────────────────────────────────────────────────────────────

  group('AppTheme — construction', () {
    test('light theme creates without throwing', () {
      expect(() => AppTheme.light, returnsNormally);
    });
    test('dark theme creates without throwing', () {
      expect(() => AppTheme.dark, returnsNormally);
    });
    test('light and dark themes are different', () {
      expect(AppTheme.light, isNot(equals(AppTheme.dark)));
    });
  });

  group('AppTheme — Material 3', () {
    test('light uses Material 3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
    });
    test('dark uses Material 3', () {
      expect(AppTheme.dark.useMaterial3, isTrue);
    });
    test('light colorScheme is light brightness', () {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    });
    test('dark colorScheme is dark brightness', () {
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });
  });

  group('AppTheme — sub-themes', () {
    test('light snackBar uses floating behavior', () {
      expect(AppTheme.light.snackBarTheme.behavior,
          SnackBarBehavior.floating);
    });
    test('dark snackBar uses floating behavior', () {
      expect(AppTheme.dark.snackBarTheme.behavior,
          SnackBarBehavior.floating);
    });
    test('light card has AppElevation.level1', () {
      expect(AppTheme.light.cardTheme.elevation, AppElevation.level1);
    });
    test('dark card has AppElevation.level1', () {
      expect(AppTheme.dark.cardTheme.elevation, AppElevation.level1);
    });
    test('light divider thickness is 1', () {
      expect(AppTheme.light.dividerTheme.thickness, 1.0);
    });
    test('dark divider thickness is 1', () {
      expect(AppTheme.dark.dividerTheme.thickness, 1.0);
    });
    test('light input decoration is filled', () {
      expect(AppTheme.light.inputDecorationTheme.filled, isTrue);
    });
    test('dark input decoration is filled', () {
      expect(AppTheme.dark.inputDecorationTheme.filled, isTrue);
    });
    test('light appBar has zero elevation', () {
      expect(AppTheme.light.appBarTheme.elevation, AppElevation.level0);
    });
    test('dark appBar has zero elevation', () {
      expect(AppTheme.dark.appBarTheme.elevation, AppElevation.level0);
    });
    test('light navigationBar uses onlyShowSelected label', () {
      expect(AppTheme.light.navigationBarTheme.labelBehavior,
          NavigationDestinationLabelBehavior.onlyShowSelected);
    });
  });
}
