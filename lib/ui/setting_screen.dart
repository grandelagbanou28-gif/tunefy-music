import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/ui/profile_screen.dart';
import 'package:tunefy/services/server_config_service.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.blackColor,
      appBar: AppBar(
        backgroundColor: const Color(0xff191919),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 65,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontFamily: "AB",
            fontSize: 16,
            color: MyColors.whiteColor,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            HapticService.tap();
            Navigator.pop(context);
          },
          child: Image.asset("images/icon_arrow_left.png"),
        ),
      ),
      body: const Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: CustomScrollView(
              slivers: [
                _ProfileSection(),
                _ServerSettingsSection(),
                _SettingsOptionChip(title: "Account"),
                _SettingsOptionChip(title: "Data Saver"),
                _SettingsOptionChip(title: "Languages"),
                _SettingsOptionChip(title: "Playback"),
                _SettingsOptionChip(title: "Explicit Content"),
                _SettingsOptionChip(title: "Devices"),
                _SettingsOptionChip(title: "Car"),
                _SettingsOptionChip(title: "Social"),
                _SettingsOptionChip(title: "Voice Assistant & Apps"),
                _SettingsOptionChip(title: "Audio Quality"),
                _SettingsOptionChip(title: "Storage"),
              ],
            ),
          ),
          BottomPlayer(),
        ],
      ),
    );
  }
}

class _ServerSettingsSection extends StatefulWidget {
  const _ServerSettingsSection();

  @override
  State<_ServerSettingsSection> createState() => _ServerSettingsSectionState();
}

class _ServerSettingsSectionState extends State<_ServerSettingsSection> {
  late TextEditingController _urlController;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ServerConfigService.serverUrl);
    _isEnabled = ServerConfigService.isEnabled;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 25),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: MyColors.darkGreyColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Custom Server",
                    style: TextStyle(
                      fontFamily: "AB",
                      fontSize: 16,
                      color: MyColors.whiteColor,
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() => _isEnabled = value);
                      ServerConfigService.setEnabled(value);
                    },
                    activeThumbColor: MyColors.greenColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Stream URL",
                style: TextStyle(
                  fontFamily: "AM",
                  fontSize: 13,
                  color: MyColors.lightGrey,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _urlController,
                style: const TextStyle(
                  fontFamily: "AM",
                  fontSize: 14,
                  color: MyColors.whiteColor,
                ),
                decoration: InputDecoration(
                  hintText: "http://192.168.1.104:43665",
                  hintStyle: const TextStyle(
                    fontFamily: "AM",
                    fontSize: 14,
                    color: MyColors.lightGrey,
                  ),
                  filled: true,
                  fillColor: MyColors.blackColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  ServerConfigService.setServerUrl(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsOptionChip extends StatelessWidget {
  const _SettingsOptionChip({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: "AM",
                fontSize: 16,
                color: MyColors.whiteColor,
              ),
            ),
            Image.asset("images/icon_arrow_right.png"),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 45),
        child: GestureDetector(
          onTap: () {
            HapticService.tap();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticService.tap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundImage: AssetImage("images/hivefy_logo.png"),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Mohammad",
                          style: TextStyle(
                            fontFamily: "AB",
                            fontSize: 18,
                            color: MyColors.whiteColor,
                          ),
                        ),
                        Text(
                          "View Profile",
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 13,
                            color: MyColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Image.asset("images/icon_arrow_right.png"),
            ],
          ),
        ),
      ),
    );
  }
}
