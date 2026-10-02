/// Sends ZPL to a Zebra printer over Wi-Fi using flutter_zpl_printer.
///
/// flutter_zpl_printer uses `dart:io` and `dart:ffi`, which don't exist on
/// the web, so the web build gets a stub instead.
library;

export 'send_to_printer_stub.dart'
    if (dart.library.io) 'send_to_printer_io.dart';
