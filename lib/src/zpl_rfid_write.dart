import 'enums.dart';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Represents the ^RF (RFID Read/Write Format) sequence.
///
/// Encodes raw string data directly to the RFID chip's memory layer.
/// This is used inside Zebra hardware capable of simultaneous ink-printing
/// and RFID-radio encoding (such as the ZT411 RFID printer).
class ZplRfidWrite extends ZplCommand {
  /// The payload to burn onto the chip.
  final String data;

  /// The operation specifying what the printer will perform with the tag.
  final RfidOperation operation;

  /// The payload encoding format.
  /// If set to [RfidDataFormat.hex], the [data] string must ONLY contain
  /// hexadecimal characters (0-9, A-F) safely matching parity length.
  final RfidDataFormat format;

  /// The starting block/word/byte depending on Gen 2 memory bank setup.
  final int startingBlock;

  /// The number of bytes to read/write. If omitted, the printer automatically
  /// matches the data length string.
  final int? byteCount;

  /// The Gen 2 tag memory bank. EPC (1) is the standard EPC identifier slot.
  final RfidMemoryBank memoryBank;

  /// Ensure we execute this logically
  const ZplRfidWrite({
    required this.data,
    this.operation = RfidOperation.write,
    this.format = RfidDataFormat.hex,
    this.startingBlock = 0,
    this.byteCount,
    this.memoryBank = RfidMemoryBank.epc,
  });

  @override
  String toZpl(ZplConfiguration context) {
    // 1. Data Type Validation Safety Check (runs in ALL build modes)
    if (format == RfidDataFormat.hex && !RegExp(r'^[0-9A-Fa-f]+$').hasMatch(data)) {
      throw ArgumentError(
        'ZplRfidWrite: hex format requires valid hex characters (0-9, A-F) only, got "$data"',
      );
    }

    // 2. Syntax mappings
    final o = _mapOp(operation);
    final f = _mapFormat(format);
    final m = _mapBank(memoryBank);
    final n = byteCount != null ? byteCount.toString() : '';

    // Build the format: ^RFo,f,b,n,m
    String command = '^RF$o,$f,$startingBlock,$n,$m';

    // Build the data append sequence -> ^FDpayload^FS
    return '$command^FD$data^FS';
  }

  String _mapOp(RfidOperation op) {
    switch (op) {
      case RfidOperation.write:
        return 'W';
      case RfidOperation.writeWithLock:
        return 'L';
      case RfidOperation.read:
        return 'R';
      case RfidOperation.readPassword:
        return 'P';
      case RfidOperation.specifyPassword:
        return 'S';
      case RfidOperation.encode:
        return 'E';
    }
  }

  String _mapFormat(RfidDataFormat f) {
    switch (f) {
      case RfidDataFormat.ascii:
        return 'A';
      case RfidDataFormat.hex:
        return 'H';
      case RfidDataFormat.epc:
        return 'E';
    }
  }

  String _mapBank(RfidMemoryBank b) {
    switch (b) {
      case RfidMemoryBank.reserved:
        return '0';
      case RfidMemoryBank.epc:
        return '1';
      case RfidMemoryBank.tid:
        return '2';
      case RfidMemoryBank.user:
        return '3';
    }
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}
