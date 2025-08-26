// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';

class CurvedHeader extends StatelessWidget {
  final String title;
  final double height;
  final double curveHeight;
  final Color textColor;
  final double fontSize;

  const CurvedHeader({
    super.key,
    required this.title,
    this.height = 150,
    this.curveHeight = 30,
    this.textColor = Colors.white,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/fondo.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          //* Overlay de cristal con opacidad
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),
          ),
          
          //* Contenido del header - Alineado exactamente con el botón
          Positioned(
            top: MediaQuery.of(context).padding.top + 16, //* Centrado vertical con el botón
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  //* Shadow para el texto para mejor legibilidad
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}