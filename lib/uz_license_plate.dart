// Uzbekistan license plate widget — config-driven layouts derived from the same
// RegExp ordering as [CarNumber.getNumberType] in `car_number.dart`.
//
// Figma: Mobile-App 18533:89042 — no side dots; outer radii 5/3 (large/small), inner
// stroke #282828; vertical divider full row height; region column ~19.4% width.

import 'dart:io';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'uz_license_plate_impl.dart';
