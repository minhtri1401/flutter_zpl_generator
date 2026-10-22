import 'enums.dart';
import 'gs1/gs1_element_string.dart';
import 'zpl_barcode.dart';
import 'zpl_barcode_enums.dart';

/// Emits the symbology command (`^BC`, `^BQ`, …) plus the `^FD…^FS` field
/// for a [ZplBarcode]. Kept separate from the command class so each
/// symbology's parameter order stays readable in one place.
///
/// Parameter references: ZPL II Programming Guide, "Bar Codes" chapter.
String emitBarcodeSymbology(ZplBarcode b) {
  final o = orientationCode(b.orientation);
  final f = b.printInterpretationLine ? 'Y' : 'N';
  final g = b.printInterpretationLineAbove ? 'Y' : 'N';
  final h = b.height;

  final sb = StringBuffer();
  switch (b.type) {
    case ZplBarcodeType.code128:
      // ^BCo,h,f,g,e,m — e: UCC check digit, m: mode (A = automatic subset,
      // N = no selected mode: only a leading >9 / >: / >; start code applies)
      final m = b.code128Mode == ZplCode128Mode.none ? 'N' : 'A';
      sb.writeln('^BC$o,$h,$f,$g,N,$m');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.gs1_128:
      // Mode D: the printer starts with FNC1 and strips the "(AI)"
      // parentheses, but adds no separator after a variable-length AI, so
      // chained AIs get an explicit >8 (FNC1).
      sb.writeln('^BC$o,$h,$f,$g,N,D');
      sb.writeln('^FD${Gs1ElementString.modeDFieldData(b.data)}^FS');

    case ZplBarcodeType.code39:
      // ^B3o,e,h,f,g — e: Mod-43 check digit
      sb.writeln('^B3$o,N,$h,$f,$g');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.code93:
      // ^BAo,h,f,g,e
      sb.writeln('^BA$o,$h,$f,$g,N');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.interleaved2of5:
      // ^B2o,h,f,g,e,j — e: Mod-10 check digit, j: print check digit
      sb.writeln('^B2$o,$h,$f,$g,N,N');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.qrCode:
      // ^BQo,model,magnification,errorCorrection
      // ^FD<ecc>A,<data> — "A" = automatic input mode. Without this prefix
      // the printer consumes the first data characters as parameters.
      final ecc = b.qrErrorCorrection.code;
      sb.writeln('^BQ$o,2,${b.magnification},$ecc');
      sb.writeln('^FD${ecc}A,${b.data}^FS');

    case ZplBarcodeType.dataMatrix:
      // ^BXo,h,q — h: module height, q: quality (200 = ECC 200)
      // GS1 adds g (escape character, set explicitly because the default
      // differs by firmware) and sends FNC1 as "~1" and GS as "~d029".
      final fnc1 = b.gs1 ? _gs1DataMatrixData(b.data) : null;
      if (fnc1 == null) {
        sb.writeln('^BX$o,$h,200');
        sb.writeln('^FD${b.data}^FS');
      } else {
        sb.writeln('^BX$o,$h,200,,,,~');
        sb.writeln('^FD$fnc1^FS');
      }

    case ZplBarcodeType.pdf417:
      // ^B7o,h,s,c,r,t — h: row height, s: security 0-8, c: columns 1-30,
      // r: rows 3-90 (blank = auto), t: truncate
      final cols = b.pdf417Columns?.toString() ?? '';
      sb.writeln('^B7$o,$h,${b.pdf417SecurityLevel},$cols,,N');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.aztec:
      // ^BOo,b,e,f,t,g — b: magnification, e: extended channel,
      // f: error control (0 = default), t: menu symbol, g: symbol count
      sb.writeln('^BO$o,${b.magnification},N,0,N,1');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.ean13:
      // ^BEo,h,f,g
      sb.writeln('^BE$o,$h,$f,$g');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.ean8:
      // ^B8o,h,f,g
      sb.writeln('^B8$o,$h,$f,$g');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.upcA:
      // ^BUo,h,f,g,e — e: print check digit
      sb.writeln('^BU$o,$h,$f,$g,N');
      sb.writeln('^FD${b.data}^FS');

    case ZplBarcodeType.upcE:
      // ^B9o,h,f,g,e — e: print check digit
      sb.writeln('^B9$o,$h,$f,$g,Y');
      sb.writeln('^FD${b.data}^FS');
  }
  return sb.toString();
}

/// ZPL orientation letter for [ZplOrientation].
String orientationCode(ZplOrientation orientation) => switch (orientation) {
  ZplOrientation.normal => 'N',
  ZplOrientation.rotated90 => 'R',
  ZplOrientation.inverted180 => 'I',
  ZplOrientation.readFromBottomUp270 => 'B',
};

/// The FNC1 form of GS1 [text], or null when [text] is not a parenthesised
/// element string or a value holds the escape character.
String? _gs1DataMatrixData(String text) {
  try {
    return Gs1ElementString.parenthesisedToFnc1(text);
  } on FormatException {
    return null;
  }
}
