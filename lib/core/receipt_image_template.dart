import 'package:flutter/material.dart';

/// Font sizes for bet table rows only (header/footer use [ReceiptFieldRect.fontSize]).
class ReceiptFontSizes {
  /// ល.រ, លេខ, ចាក់, ប៉ុស្តិ៍, សរុប
  final List<double> rowColumns;
  /// Post column shrinks by text length: ≤5, ≤9, ≤13, longer chars.
  final List<double> postByLength;

  const ReceiptFontSizes({
    this.rowColumns = const [12, 12, 12, 11, 12],
    this.postByLength = const [12, 11, 10, 9],
  });

  double postFontSizeFor(String post) {
    final len = post.length;
    if (len <= 5) return postByLength[0];
    if (len <= 9) return postByLength[1];
    if (len <= 13) return postByLength[2];
    return postByLength[3];
  }
}

/// Normalized rectangle on a header/footer image (fractions 0–1).
class ReceiptFieldRect {
  final double left;
  final double top;
  final double width;
  final double height;
  final double fontSize;
  /// When set, size scales by digit count (use on total field).
  final List<double>? fontSizesByDigits;

  const ReceiptFieldRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.fontSize = 12,
    this.fontSizesByDigits,
  });

  double fontSizeFor({int? digitCount}) {
    if (fontSizesByDigits != null && digitCount != null) {
      if (digitCount <= 5) return fontSizesByDigits![0];
      if (digitCount == 6) return fontSizesByDigits![1];
      if (digitCount == 7) return fontSizesByDigits![2];
      return fontSizesByDigits![3];
    }
    return fontSize;
  }
}

/// Per-branch image receipt layout. Clone this class to add branch2, branch4, etc.
class ImageReceiptTemplate {
  final String id;
  final String headerAsset;
  final String footerAsset;
  final double headerWidth;
  final double headerHeight;
  final double footerWidth;
  final double footerHeight;
  final Color fieldTextColor;
  /// Name + bill on dark header bars; defaults to [fieldTextColor].
  final Color? headerBarTextColor;
  final Color rowBackgroundColor;
  final Color rowTextColor;
  final List<double> colFractions;
  final ReceiptFieldRect nameField;
  final ReceiptFieldRect billField;
  final ReceiptFieldRect dateField;
  final ReceiptFieldRect lotteryField;
  final ReceiptFieldRect entryTimeField;
  final ReceiptFieldRect totalField;
  final ReceiptFieldRect? agentField;
  final ReceiptFieldRect? branchField;
  final Color? agentTextColor;
  final Color footerAgentColor;
  final Color footerEntryTimeColor;
  final Color totalFieldColor;
  final ReceiptFontSizes fonts;
  /// Extra left padding per bet row column (ល.រ, លេខ, ចាក់, ប៉ុស្តិ៍, សរុប).
  final List<double> rowColumnLeftPad;

  const ImageReceiptTemplate({
    required this.id,
    required this.headerAsset,
    required this.footerAsset,
    required this.headerWidth,
    required this.headerHeight,
    required this.footerWidth,
    required this.footerHeight,
    required this.fieldTextColor,
    this.headerBarTextColor,
    required this.rowBackgroundColor,
    required this.rowTextColor,
    required this.colFractions,
    required this.nameField,
    required this.billField,
    required this.dateField,
    required this.lotteryField,
    required this.entryTimeField,
    required this.totalField,
    this.agentField,
    this.branchField,
    this.agentTextColor,
    this.footerAgentColor = Colors.white,
    this.footerEntryTimeColor = Colors.white,
    this.totalFieldColor = Colors.white,
    this.fonts = const ReceiptFontSizes(),
    this.rowColumnLeftPad = const [0, 0, 0, 0, 0],
  });

  double get headerAspect => headerWidth / headerHeight;
  double get footerAspect => footerWidth / footerHeight;

  static ImageReceiptTemplate? forBranch(String branch) {
    switch (branch) {
      case 'branch1':
        return branch1;
      case 'branch3':
        return branch3;
      case 'branch4':
        return branch4;
      // branch2 → null → code-designed receipt in receipt_preview.dart
      default:
        return null;
    }
  }

  // ── branch1 (header1.jpg 1280×593, bottom1.jpg 1280×316) ──
  static const branch1 = ImageReceiptTemplate(
    id: 'branch1',
    headerAsset: 'assets/header1.jpg',
    footerAsset: 'assets/bottom1.jpg',
    headerWidth: 1280,
    headerHeight: 593,
    footerWidth: 1280,
    footerHeight: 316,
    fieldTextColor: Color(0xFF1B3B6F),
    rowBackgroundColor: Colors.white,
    rowTextColor: Color(0xFF1B3B6F),
    colFractions: [0.10, 0.22, 0.18, 0.22, 0.28],
    nameField: ReceiptFieldRect(
      left: 0.22,
      top: 0.38,
      width: 0.3,
      height: 0.10,
      fontSize: 12,
    ),
    billField: ReceiptFieldRect(
      left: 0.20,
      top: 0.62,
      width: 0.24,
      height: 0.10,
      fontSize: 12,
    ),
    dateField: ReceiptFieldRect(
      left: 0.66,
      top: 0.37,
      width: 0.30,
      height: 0.10,
      fontSize: 12
    ),
    lotteryField: ReceiptFieldRect(
      left: 0.66,
      top: 0.62,
      width: 0.30,
      height: 0.10,
      fontSize: 12,
    ),
    agentField: ReceiptFieldRect(
      left: 0.11,
      top: 0.08,
      width: 0.26,
      height: 0.32,
      fontSize: 12,
    ),
    entryTimeField: ReceiptFieldRect(
      left: 0.44,
      top: 0.08,
      width: 0.22,
      height: 0.32,
      fontSize: 12,
    ),
    totalField: ReceiptFieldRect(
      left: 0.70,
      top: 0.32,
      width: 0.24,
      height: 0.64,
      fontSize: 18,
      fontSizesByDigits: [18, 16, 14, 12],
    ),
    fonts: ReceiptFontSizes(
      rowColumns: [12, 12, 12, 11, 12],
      postByLength: [12, 11, 10, 9],
    ),
  );

  // ── branch3 (header.jpg 900×421, bottom.jpg 900×243) ──
  static const branch3 = ImageReceiptTemplate(
    id: 'branch3',
    headerAsset: 'assets/header.jpg',
    footerAsset: 'assets/bottom.jpg',
    headerWidth: 900,
    headerHeight: 421,
    footerWidth: 900,
    footerHeight: 243,
    fieldTextColor: Color(0xFF4A2F14),
    rowBackgroundColor: Color(0xFFFFF9EE),
    rowTextColor: Color(0xFF4A2F14),
    colFractions: [0.10, 0.22, 0.18, 0.22, 0.28],
    nameField: ReceiptFieldRect(
      left: 0.23,
      top: 0.365,
      width: 0.24,
      height: 0.13,
      fontSize: 12,
    ),
    billField: ReceiptFieldRect(
      left: 0.27,
      top: 0.595,
      width: 0.18,
      height: 0.13,
      fontSize: 12,
    ),
    dateField: ReceiptFieldRect(
      left: 0.68,
      top: 0.37,
      width: 0.28,
      height: 0.13,
      fontSize: 12,
    ),
    lotteryField: ReceiptFieldRect(
      left: 0.62,
      top: 0.595,
      width: 0.36,
      height: 0.13,
      fontSize: 12,
    ),
    entryTimeField: ReceiptFieldRect(
      left: 0.24,
      top: 0.1,
      width: 0.18,
      height: 0.34,
      fontSize: 12,
    ),
    totalField: ReceiptFieldRect(
      left: 0.64,
      top: 0.06,
      width: 0.22,
      height: 0.36,
      fontSize: 14,
      fontSizesByDigits: [14, 13, 12, 11],
    ),
    branchField: ReceiptFieldRect(
      left: 0.69,
      top: 0.62,
      width: 0.22,
      height: 0.34,
      fontSize: 12,
    ),
    agentTextColor: Color(0xFFB8860B),
    fonts: ReceiptFontSizes(
      rowColumns: [12, 12, 12, 11, 12],
      postByLength: [12, 11, 10, 9],
    ),
  );

  // ── branch4 (header4.jpg 1280×600, bottom4.jpg 1280×568) ──
  static const branch4 = ImageReceiptTemplate(
    id: 'branch4',
    headerAsset: 'assets/header4.jpg',
    footerAsset: 'assets/bottom4.jpg',
    headerWidth: 1280,
    headerHeight: 600,
    footerWidth: 1280,
    footerHeight: 568,
    fieldTextColor: Color(0xFF8B1A1A),
    headerBarTextColor: Colors.white,
    rowBackgroundColor: Color(0xFFFFF5E6),
    rowTextColor: Color(0xFF8B1A1A),
    colFractions: [0.09, 0.21, 0.17, 0.25, 0.28],
    nameField: ReceiptFieldRect(
      left: 0.33,
      top: 0.39,
      width: 0.26,
      height: 0.09,
      fontSize: 12,
    ),
    billField: ReceiptFieldRect(
      left: 0.32,
      top: 0.60,
      width: 0.26,
      height: 0.09,
      fontSize: 12,
    ),
    dateField: ReceiptFieldRect(
      left: 0.68,
      top: 0.39,
      width: 0.34,
      height: 0.09,
      fontSize: 12,
    ),
    lotteryField: ReceiptFieldRect(
      left: 0.68,
      top: 0.60,
      width: 0.34,
      height: 0.09,
      fontSize: 12,
    ),
    agentField: ReceiptFieldRect(
      left: 0.17,
      top: 0.1,
      width: 0.28,
      height: 0.14,
      fontSize: 12,
    ),
    entryTimeField: ReceiptFieldRect(
      left: 0.42,
      top: 0.1,
      width: 0.22,
      height: 0.14,
      fontSize: 11,
    ),
    totalField: ReceiptFieldRect(
      left: 0.58,
      top: 0.28,
      width: 0.36,
      height: 0.52,
      fontSize: 22,
      fontSizesByDigits: [22, 20, 18, 16],
    ),
    footerAgentColor: Colors.white,
    footerEntryTimeColor: Colors.white,
    totalFieldColor: Color(0xFFC62828),
    rowColumnLeftPad: [0, 45, 45, 40, 0],
    fonts: ReceiptFontSizes(
      rowColumns: [12, 12, 12, 11, 12],
      postByLength: [11, 10, 10, 9],
    ),
  );
}
