import 'package:flutter_zpl_printer/flutter_zpl_printer.dart'
    show TcpConnection, ZebraPrinter;

/// Whether this platform can send to a printer.
const bool printingSupported = true;

/// Connects to the printer at [host] on port 9100, sends [zpl], and
/// disconnects. For Bluetooth LE and USB, see flutter_zpl_printer's example.
Future<void> sendZplToPrinter(String host, String zpl) async {
  final printer = await ZebraPrinter.connect(TcpConnection.zpl(host));
  try {
    await printer.printZpl(zpl);
  } finally {
    await printer.disconnect();
  }
}
