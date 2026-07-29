import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class ScanSpotifyCodeScreen extends StatelessWidget {
  const ScanSpotifyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.blackColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 25,
              ),
              Container(
                height: 16,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: MyColors.darkGreyColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  HapticService.tap();
                  Navigator.pop(context);
                },
                child: Image.asset(
                  "images/icon_back.png",
                  height: 15,
                  width: 15,
                ),
              ),
              const SizedBox(
                height: 70,
              ),
              Center(
                child: Container(
                  height: 241,
                  width: 241,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      width: 2,
                      color: MyColors.whiteColor,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 35,
              ),
              Center(
                child: Image.asset("images/icon_wave.png"),
              ),
              const SizedBox(
                height: 18,
              ),
              const Center(
                child: SizedBox(
                  width: 251,
                  child: Text(
                    "Point your camera at a Spotify code.",
                    style: TextStyle(
                      fontFamily: "AB",
                      color: MyColors.whiteColor,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(
                height: 35,
              ),
              const Center(
                child: Text(
                  "Select from photos",
                  style: TextStyle(
                    fontFamily: "AB",
                    fontSize: 14,
                    color: MyColors.whiteColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
