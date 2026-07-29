import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/ui/create_email_screen.dart';
import 'package:tunefy/ui/dashboard_screen.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: MyColors.blackColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "images/onboarding_background.png",
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Millions of songs.",
              style: TextStyle(
                fontFamily: "AB",
                fontSize: 28,
                color: MyColors.whiteColor,
              ),
            ),
            const Text(
              "Free on Spotify.",
              style: TextStyle(
                fontFamily: "AB",
                fontSize: 28,
                color: MyColors.whiteColor,
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            const _ActionButtons(),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(MediaQuery.of(context).size.width, 49),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              backgroundColor: MyColors.greenColor,
            ),
            onPressed: () {
              HapticService.tap();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateEmailScreen(),
                ),
              );
            },
            child: const Text(
              "ُSign up free",
              style: TextStyle(
                fontFamily: "AB",
                fontSize: 16,
                color: MyColors.blackColor,
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          OutlinedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(MediaQuery.of(context).size.width, 49),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              side: const BorderSide(
                width: 1,
                color: MyColors.lightGrey,
              ),
            ),
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset("images/icon_google.png"),
                const Text(
                  "Continue with google",
                  style: TextStyle(
                    fontFamily: "AB",
                    fontSize: 16,
                    color: MyColors.whiteColor,
                  ),
                ),
                const SizedBox(
                  height: 18,
                  width: 18,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          OutlinedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(MediaQuery.of(context).size.width, 49),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              side: const BorderSide(
                width: 1,
                color: MyColors.lightGrey,
              ),
            ),
            onPressed: () {},
            child: Row(
              children: [
                Image.asset("images/icon_facebook.png"),
                const Flexible(
                  child: Text(
                    "Continue with Facebook",
                    style: TextStyle(
                      fontFamily: "AB",
                      fontSize: 16,
                      color: MyColors.whiteColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: 18,
                  width: 18,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          OutlinedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(MediaQuery.of(context).size.width, 49),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              side: const BorderSide(
                width: 1,
                color: MyColors.lightGrey,
              ),
            ),
            onPressed: () {},
            child: Row(
              children: [
                Image.asset("images/icon_apple.png"),
                const Flexible(
                  child: Text(
                    "Continue with Apple",
                    style: TextStyle(
                      fontFamily: "AB",
                      fontSize: 16,
                      color: MyColors.whiteColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: 18,
                  width: 18,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          GestureDetector(
            onTap: () {
              HapticService.tap();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const DashBoardScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Continue without account",
              style: TextStyle(
                fontFamily: "AB",
                fontSize: 16,
                color: MyColors.lightGrey,
                decoration: TextDecoration.underline,
                decorationColor: MyColors.lightGrey,
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          const Text(
            "Log in",
            style: TextStyle(
              fontFamily: "AB",
              fontSize: 16,
              color: MyColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }
}
