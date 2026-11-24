import 'package:flutter/painting.dart';

/// Светлее на долю [amount] (0..1): цвет смешивается с белым.
Color pixelLighten(Color color, double amount) =>
    Color.lerp(color, const Color(0xFFFFFFFF), amount)!;

/// Темнее на долю [amount] (0..1): цвет смешивается с чёрным.
Color pixelDarken(Color color, double amount) =>
    Color.lerp(color, const Color(0xFF000000), amount)!;
