import 'package:flutter/material.dart';

const blue = Color(0xFF0878FF);
const ink = Color(0xFF18212F);
const muted = Color(0xFF7C8492);
const paleBlue = Color(0xFFEFF5FF);
const border = Color(0xFFE9EDF3);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    surface: Colors.white,
    onSurface: ink,
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFBFD),
  fontFamilyFallback: const [
    'Hiragino Sans',
    'Noto Sans JP',
    'Yu Gothic',
    'sans-serif',
  ],
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: ink),
    bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ink),
    titleLarge: TextStyle(
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFAFBFD),
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFDFEFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: border, width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: blue, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  dividerTheme: const DividerThemeData(color: border, thickness: 1),
);

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: border.withValues(alpha: .8)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF233A5A).withValues(alpha: .045),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class IconBubble extends StatelessWidget {
  const IconBubble(this.icon, {super.key, this.size = 48, this.color = blue});
  final IconData icon;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .075),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: size * .49),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 23),
          if (busy || icon != null) const SizedBox(width: 10),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
