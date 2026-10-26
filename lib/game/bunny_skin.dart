import 'package:flutter/material.dart';

class BunnySkin {
  const BunnySkin({
    required this.id,
    required this.body,
    required this.eye,
    required this.innerEar,
    required this.outline,
    required this.cost,
  });

  final String id;
  final Color body;
  final Color eye;
  final Color innerEar;
  final Color outline;
  final int cost;
}

const whiteBunnySkin = BunnySkin(
  id: 'white',
  body: Color(0xFFFFF8EC),
  eye: Color(0xFF2F2A26),
  innerEar: Color(0xFFE7A79E),
  outline: Color(0x8C2F2A26),
  cost: 0,
);

const bunnySkins = [
  whiteBunnySkin,
  BunnySkin(
    id: 'gray',
    body: Color(0xFFD8D4CB),
    eye: Color(0xFF2F2A26),
    innerEar: Color(0xFFD9A5A0),
    outline: Color(0x8C2F2A26),
    cost: 10,
  ),
  BunnySkin(
    id: 'brown',
    body: Color(0xFFC79C74),
    eye: Color(0xFF3A2A20),
    innerEar: Color(0xFFE8B0A5),
    outline: Color(0x8C3A2A20),
    cost: 15,
  ),
  BunnySkin(
    id: 'night',
    body: Color(0xFF3A342E),
    eye: Color(0xFFFFF8EA),
    innerEar: Color(0xFFCA8E8E),
    outline: Color(0xCCFFF8EA),
    cost: 20,
  ),
  BunnySkin(
    id: 'carrot',
    body: Color(0xFFF0C08A),
    eye: Color(0xFF5A3A22),
    innerEar: Color(0xFFE59A8E),
    outline: Color(0x8C5A3A22),
    cost: 25,
  ),
  BunnySkin(
    id: 'lilac',
    body: Color(0xFFC9A7E8),
    eye: Color(0xFF3A2B4A),
    innerEar: Color(0xFFE8A7C4),
    outline: Color(0x8C3A2B4A),
    cost: 40,
  ),
];

BunnySkin skinById(String? id) => bunnySkins.firstWhere(
  (skin) => skin.id == id,
  orElse: () => whiteBunnySkin,
);
