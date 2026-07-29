import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tunefy/bloc/podcast/podcast_bloc.dart';
import 'package:tunefy/bloc/podcast/podcast_state.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/data/model/podcast.dart';
import 'package:tunefy/ui/dashboard_screen.dart';
import 'package:tunefy/widgets/podcast_avatar_widget.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class ChoosePodcastScreen extends StatelessWidget {
  const ChoosePodcastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.darkGreyColor,
      body: SafeArea(
        child: BlocBuilder<PodcastBloc, PodcastState>(
          builder: (context, state) {
            if (state is PodcastListState) {
              return Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  CustomScrollView(
                    slivers: [
                      const SliverPadding(
                        padding: EdgeInsets.only(
                            top: 25, right: 25, left: 25, bottom: 5),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              SizedBox(
                                height: 75,
                                width: 245,
                                child: Text(
                                  "Now choose some podcasts.",
                                  style: TextStyle(
                                    fontFamily: "AB",
                                    fontSize: 26,
                                    color: MyColors.whiteColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const _SearchBox(),
                      _PodcastList(getList: state.podcastList),
                    ],
                  ),
                  Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyColors.blackColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 55),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(25),
                          ),
                        ),
                        backgroundColor: MyColors.whiteColor,
                      ),
                      onPressed: () {
                        HapticService.tap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashBoardScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontFamily: "AB",
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Center(
              child: Text(
                "Snap! Error Happened",
                style: TextStyle(
                  fontFamily: "AB",
                  fontSize: 18,
                  color: MyColors.whiteColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PodcastList extends StatelessWidget {
  const _PodcastList({required this.getList});
  final List<Podcast> getList;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 90),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return PodcastAvatarWidget(
              podcast: getList[index],
            );
          },
          childCount: getList.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 165,
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 35, right: 25, left: 25),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 42,
          decoration: const BoxDecoration(
            color: MyColors.whiteColor,
            borderRadius: BorderRadius.all(
              Radius.circular(7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Image.asset("images/icon_Search.png"),
                const Expanded(
                  child: TextField(
                    style: TextStyle(
                      fontFamily: "AM",
                      fontSize: 16,
                      color: MyColors.blackColor,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(top: 15, left: 15),
                      hintText: "Search",
                      hintStyle: TextStyle(
                        fontFamily: "AM",
                        color: MyColors.blackColor,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          style: BorderStyle.none,
                          width: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
