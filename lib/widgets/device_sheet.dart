import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_device_detection/audio_device_detection.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/services/haptic_service.dart';

class DeviceSheet extends StatefulWidget {
  const DeviceSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.darkGreyColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => const DeviceSheet(),
    );
  }

  @override
  State<DeviceSheet> createState() => _DeviceSheetState();
}

class _DeviceSheetState extends State<DeviceSheet> {
  List<AudioDevice> _devices = [];
  StreamSubscription<AudioDevice>? _sub;
  bool _permissionDenied = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print('[DeviceSheet] _init called');
    final bt = await Permission.bluetoothConnect.request();
    print('[DeviceSheet] bluetoothConnect permission: ${bt.isGranted}');
    if (bt.isGranted) {
      try {
        _devices = await AudioDeviceDetection.instance.getConnectedDevices();
        print('[DeviceSheet] connected devices: ${_devices.length}');
        for (final d in _devices) {
          print('[DeviceSheet]   - ${d.name} (${d.protocol.name})');
        }
      } catch (e) {
        print('[DeviceSheet] error getting devices: $e');
      }
      _sub = AudioDeviceDetection.instance.onDeviceStateChanged.listen((d) {
        print('[DeviceSheet] device state changed: ${d.name} connected=${d.isConnected}');
        _devices = [..._devices.where((x) => x.name != d.name)];
        if (d.isConnected) _devices = [..._devices, d];
        if (mounted) setState(() {});
      });
    } else {
      _permissionDenied = true;
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  IconData _iconForProtocol(AudioProtocol protocol) {
    switch (protocol) {
      case AudioProtocol.bluetoothA2dp:
      case AudioProtocol.bluetoothHfp:
      case AudioProtocol.bluetoothLe:
        return Icons.bluetooth;
      case AudioProtocol.wired:
        return Icons.headset;
      case AudioProtocol.speaker:
      case AudioProtocol.earpiece:
        return Icons.phone_android;
      case AudioProtocol.airplay:
      case AudioProtocol.wifi:
        return Icons.wifi;
      case AudioProtocol.unknown:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Devices available',
              style: TextStyle(fontFamily: "AB", fontSize: 16, color: Colors.white),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _DeviceTile(
            icon: Icons.phone_android,
            name: 'This phone',
            subtitle: 'Phone speaker',
            isActive: _devices.isEmpty,
            isCurrent: true,
            onTap: () => Navigator.pop(context),
          ),
          ..._devices.map((d) => _DeviceTile(
            icon: _iconForProtocol(d.protocol),
            name: d.name,
            subtitle: d.protocol.name.toUpperCase(),
            isActive: true,
            isCurrent: false,
            onTap: () => Navigator.pop(context),
          )),
          if (_permissionDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.white38, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bluetooth permission required',
                          style: TextStyle(fontFamily: "AB", fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Allow Tunefy to access Bluetooth to detect connected devices.',
                          style: TextStyle(fontFamily: "AM", fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_devices.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_searching, color: Colors.white38, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Connect a Bluetooth device to play music',
                      style: TextStyle(fontFamily: "AM", fontSize: 12, color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final bool isActive;
  final bool isCurrent;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.isActive,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCurrent ? MyColors.greenColor : Colors.white,
        size: 24,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontFamily: "AM",
          fontSize: 14,
          color: isCurrent ? MyColors.greenColor : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: "AM",
          fontSize: 11,
          color: isCurrent ? MyColors.greenColor.withValues(alpha: 0.6) : Colors.white38,
        ),
      ),
      trailing: isCurrent
          ? const Icon(Icons.volume_up, color: MyColors.greenColor, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
