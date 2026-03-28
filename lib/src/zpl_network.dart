import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Network Boot Print Server Check (`^NB`)
/// Sets the interval for the print server to check for a boot block.
class ZplNetworkBoot extends ZplCommand {
  final int check;

  const ZplNetworkBoot({required this.check});

  @override
  String toZpl(ZplConfiguration context) => '^NB$check\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Primary Network Device (`^NC`)
/// Sets the primary network device.
class ZplNetworkDevice extends ZplCommand {
  final int device;

  const ZplNetworkDevice({required this.device});

  @override
  String toZpl(ZplConfiguration context) => '^NC$device\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Network Connect (`~NC`)
/// Connects to a secondary network.
class ZplNetworkConnect extends ZplCommand {
  final String networkId;

  const ZplNetworkConnect({required this.networkId});

  @override
  String toZpl(ZplConfiguration context) => '~NC$networkId\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Modify Network Settings (`^ND`)
/// Changes network parameters for a specific device.
class ZplNetworkSettings extends ZplCommand {
  final int device;
  final String? res;
  final String? ip;
  final String? mask;
  final String? gateway;
  final String? wins;
  final int? timeout;
  final int? secs;
  final String? arp;
  final int? port;

  const ZplNetworkSettings({
    required this.device,
    this.res,
    this.ip,
    this.mask,
    this.gateway,
    this.wins,
    this.timeout,
    this.secs,
    this.arp,
    this.port,
  }) : assert(arp == null || arp == 'Y' || arp == 'N', 'ARP must be Y or N');

  @override
  String toZpl(ZplConfiguration context) {
    return '^ND$device,${res ?? ''},${ip ?? ''},${mask ?? ''},${gateway ?? ''},${wins ?? ''},${timeout ?? ''},${secs ?? ''},${arp ?? ''},${port ?? ''}\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Network ID Number (`^NI`)
/// Assigns a Network ID number.
class ZplNetworkId extends ZplCommand {
  final String networkId;

  const ZplNetworkId({required this.networkId});

  @override
  String toZpl(ZplConfiguration context) => '^NI$networkId\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Configure SNMP (`^NN`)
/// Sets the parameters for SNMP.
class ZplNetworkSnmp extends ZplCommand {
  final String? name;
  final String? contact;
  final String? location;
  final String? getCommunity;
  final String? setCommunity;
  final String? trapCommunity;

  const ZplNetworkSnmp({
    this.name,
    this.contact,
    this.location,
    this.getCommunity,
    this.setCommunity,
    this.trapCommunity,
  });

  @override
  String toZpl(ZplConfiguration context) {
    return '^NN${name ?? ''},${contact ?? ''},${location ?? ''},${getCommunity ?? ''},${setCommunity ?? ''},${trapCommunity ?? ''}\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Set Primary Device (`^NP`)
/// Defines the primary connection device.
class ZplNetworkPrimaryDevice extends ZplCommand {
  final int device;

  const ZplNetworkPrimaryDevice({required this.device});

  @override
  String toZpl(ZplConfiguration context) => '^NP$device\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Set All Network Printers Transparent (`~NR`)
class ZplNetworkPrintersTransparentAll extends ZplCommand {
  const ZplNetworkPrintersTransparentAll();

  @override
  String toZpl(ZplConfiguration context) => '~NR\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Modify Wired Network Settings (`^NS`)
/// Configures network settings.
class ZplNetworkWiredSettings extends ZplCommand {
  final String? res;
  final String? ip;
  final String? mask;
  final String? gateway;
  final String? wins;
  final int? timeout;
  final int? secs;
  final String? arp;
  final int? port;

  const ZplNetworkWiredSettings({
    this.res,
    this.ip,
    this.mask,
    this.gateway,
    this.wins,
    this.timeout,
    this.secs,
    this.arp,
    this.port,
  }) : assert(arp == null || arp == 'Y' || arp == 'N', 'ARP must be Y or N');

  @override
  String toZpl(ZplConfiguration context) {
    return '^NS${res ?? ''},${ip ?? ''},${mask ?? ''},${gateway ?? ''},${wins ?? ''},${timeout ?? ''},${secs ?? ''},${arp ?? ''},${port ?? ''}\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Set Current Printer Transparent (`~NT`)
class ZplNetworkPrinterTransparentCurrent extends ZplCommand {
  const ZplNetworkPrinterTransparentCurrent();

  @override
  String toZpl(ZplConfiguration context) => '~NT\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Configure SMTP (`^NT`)
/// Sets the email server routing parameters.
class ZplNetworkSmtp extends ZplCommand {
  final String server;
  final String? domain;

  const ZplNetworkSmtp({required this.server, this.domain});

  @override
  String toZpl(ZplConfiguration context) {
    return '^NT$server,${domain ?? ''}\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}

/// Set Password Timeout (`^NW`)
/// Sets the duration before a password expires physically.
class ZplNetworkPasswordTimeout extends ZplCommand {
  final int timeout;

  const ZplNetworkPasswordTimeout({required this.timeout});

  @override
  String toZpl(ZplConfiguration context) => '^NW$timeout\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}
