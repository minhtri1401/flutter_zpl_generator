/// Whether this platform can send to a printer.
const bool printingSupported = false;

Future<void> sendZplToPrinter(String host, String zpl) =>
    throw UnsupportedError('Printing is not available on this platform.');
