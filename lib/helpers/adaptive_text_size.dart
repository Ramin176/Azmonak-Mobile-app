import 'package:flutter/material.dart';

class AdaptiveTextSize extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const AdaptiveTextSize({
    Key? key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the base font size (you can adjust the multiplier)
    final double screenWidth = MediaQuery.of(context).size.width;
    // Example: Base font size is 16 on a screen width of 360, scales up/down
    final double baseFontSize = (style?.fontSize ?? 16);
    final double responsiveFontSize = baseFontSize * (screenWidth / 360.0) -3;

    return Text(
      text,
      style: style?.copyWith(fontSize: responsiveFontSize) ?? TextStyle(fontSize: responsiveFontSize),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}