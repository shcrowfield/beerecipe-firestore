import 'package:flutter/material.dart';

const PRIMARY_COLOR = Color.fromRGBO(251, 187, 1, 1);

final appTheme = ThemeData(
    primaryColor: PRIMARY_COLOR,
    appBarTheme: const AppBarTheme(color:PRIMARY_COLOR),
    colorScheme: const ColorScheme.light(secondary: PRIMARY_COLOR,primary:PRIMARY_COLOR ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.brown)
  )
);