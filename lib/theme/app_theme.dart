import 'package:flutter/material.dart';

// ─── Global theme notifier ────────────────────────────────────────────────────
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// ─── Color palette ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const primary        = Color(0xFF4F46E5); // Deep Indigo
  static const primaryLight   = Color(0xFF6366F1);
  static const primaryLighter = Color(0xFFEEF2FF);
  static const secondary      = Color(0xFF7C3AED); // Electric Purple

  static const success        = Color(0xFF10B981); // Emerald
  static const successDark    = Color(0xFF059669);
  static const successBg      = Color(0xFFF0FDF4);
  static const successBorder  = Color(0xFFBBF7D0);

  static const warning        = Color(0xFFF59E0B); // Amber
  static const warningDark    = Color(0xFFD97706);
  static const warningBg      = Color(0xFFFEF3C7);
  static const warningBorder  = Color(0xFFFDE68A);

  static const error          = Color(0xFFEF4444); // Red
  static const errorDark      = Color(0xFFDC2626);
  static const errorBg        = Color(0xFFFEE2E2);
  static const errorBorder    = Color(0xFFFECACA);

  static const info           = Color(0xFF3B82F6); // Blue
  static const infoBg         = Color(0xFFEFF6FF);

  static const teal           = Color(0xFF0D9488);
  static const tealBg         = Color(0xFFF0FDFA);
  static const orange         = Color(0xFFF97316);

  // Light mode surfaces
  static const bgLight        = Color(0xFFF8FAFC);
  static const surfaceLight   = Color(0xFFFFFFFF);
  static const borderLight    = Color(0xFFE8EAED);
  static const borderLighter  = Color(0xFFF1F3F5);

  static const textPrimary    = Color(0xFF111827);
  static const textSecondary  = Color(0xFF6B7280);
  static const textTertiary   = Color(0xFF9CA3AF);

  // Dark mode surfaces (GitHub Dark / Linear Dark inspired — NO pure black)
  static const bgDark         = Color(0xFF0D0F17);
  static const surfaceDark    = Color(0xFF161822);
  static const surfaceDark2   = Color(0xFF1E2030);
  static const surfaceDark3   = Color(0xFF252840);
  static const borderDark     = Color(0xFF2A2D3E);

  static const textPrimaryDk  = Color(0xFFE8EAED);
  static const textSecondaryDk= Color(0xFF9CA3AF);
  static const textTertiaryDk = Color(0xFF6B7280);
}

// ─── Gradients ────────────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  static const hero = LinearGradient(
    colors: [Color(0xFF3730A3), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroDark = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF2E1065)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primary = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const teal = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amber = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const green = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Shadows ──────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─── BuildContext helpers ─────────────────────────────────────────────────────
extension AppContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface     => isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
  Color get surface2    => isDark ? AppColors.surfaceDark2 : AppColors.bgLight;
  Color get border      => isDark ? AppColors.borderDark   : AppColors.borderLight;
  Color get bgColor     => isDark ? AppColors.bgDark       : AppColors.bgLight;
  Color get textPrimary => isDark ? AppColors.textPrimaryDk: AppColors.textPrimary;
  Color get textSecondary => isDark
      ? AppColors.textSecondaryDk
      : AppColors.textSecondary;

  List<BoxShadow> get cardShadow =>
      isDark ? [] : AppShadows.card;
}

// ─── ThemeData ────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      space: 1,
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark2,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDk,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryDk,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryDk),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      space: 1,
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark3,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ─── Shared shimmer widget ────────────────────────────────────────────────────
class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const AppShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final base   = isDark ? AppColors.surfaceDark2 : const Color(0xFFE8EAED);
    final shine  = isDark ? AppColors.surfaceDark3 : const Color(0xFFF5F7FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: [base, shine, base],
          ),
        ),
      ),
    );
  }
}

// ─── Shared pressable card ────────────────────────────────────────────────────
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableCard({super.key, required this.child, this.onTap});

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── Page route helper ────────────────────────────────────────────────────────
PageRouteBuilder<T> slideRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (context, animation, _) => page,
  transitionsBuilder: (context, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.03, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
  ),
  transitionDuration: const Duration(milliseconds: 230),
);
