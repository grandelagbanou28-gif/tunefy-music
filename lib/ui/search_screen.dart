import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tunefy/bloc/search/search_bloc.dart';
import 'package:tunefy/bloc/search/search_event.dart';
import 'package:tunefy/bloc/search/search_state.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/ui/track_detail_screen.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SearchBloc _searchBloc = SearchBloc();
  final List<SearchResult> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _searchBloc.add(SearchQueryEvent(widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.blackColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: BlocProvider.value(
          value: _searchBloc,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _SearchHeader(controller: _controller, bloc: _searchBloc),
                _FilterChips(bloc: _searchBloc),
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      if (state is SearchLoadingState) {
                        return const Center(child: CircularProgressIndicator(color: MyColors.whiteColor));
                      }
                      if (state is SearchResultsState) {
                        return _SearchResults(results: state.results, onPlay: _playTrack);
                      }
                      if (state is SearchErrorState) {
                        return Center(
                          child: Text(state.message, style: const TextStyle(fontFamily: "AM", color: MyColors.lightGrey, fontSize: 15)),
                        );
                      }
                      if (state is SearchSuggestionsState) {
                        return _SuggestionsList(
                          suggestions: state.suggestions,
                          onTap: (query) {
                            _controller.text = query;
                            _searchBloc.add(SearchQueryEvent(query));
                          },
                        );
                      }
                      return _RecentSearches(
                        searches: _recentSearches,
                        onRemove: (item) { setState(() { _recentSearches.remove(item); }); },
                        onTap: (query) {
                          _controller.text = query;
                          _searchBloc.add(SearchQueryEvent(query));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playTrack(SearchResult result) {
    if (result.videoId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackDetailScreen(
          title: result.title,
          artist: result.subtitle,
          imageUrl: result.imageUrl,
          videoId: result.videoId,
        ),
      ),
    );
    if (!_recentSearches.any((r) => r.id == result.id)) {
      setState(() { _recentSearches.insert(0, result); });
    }
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final SearchBloc bloc;

  const _SearchHeader({required this.controller, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 35,
            width: MediaQuery.of(context).size.width - 102.5,
            decoration: const BoxDecoration(
              color: MyColors.darkGreyColor,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Image.asset("images/icon_search_transparent.png", color: MyColors.whiteColor),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(fontFamily: "AM", fontSize: 16, color: MyColors.whiteColor),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(top: 10, left: 15),
                        hintText: "Search",
                        hintStyle: TextStyle(fontFamily: "AM", color: MyColors.whiteColor, fontSize: 15),
                        border: OutlineInputBorder(borderSide: BorderSide(style: BorderStyle.none, width: 0)),
                      ),
                      onChanged: (value) {
                        if (value.length >= 2) {
                          bloc.add(SearchSuggestionsEvent(value));
                        }
                      },
                      onSubmitted: (value) {
                        bloc.add(SearchQueryEvent(value));
                      },
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticService.tap();
                        controller.clear();
                        bloc.add(SearchClearEvent());
                      },
                      child: const Icon(Icons.close, color: MyColors.whiteColor, size: 20),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () { Navigator.pop(context); },
            child: const Text("Cancel", style: TextStyle(fontFamily: "AM", color: MyColors.whiteColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final SearchBloc bloc;
  const _FilterChips({required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final currentFilter = bloc.currentFilter;
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: SearchFilter.values.map((filter) {
              final isActive = currentFilter == filter;
              final label = _filterLabel(filter);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => bloc.add(SearchFilterEvent(filter)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? MyColors.whiteColor : MyColors.darkGreyColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: "AM",
                          fontSize: 13,
                          color: isActive ? MyColors.blackColor : MyColors.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _filterLabel(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.all: return 'All';
      case SearchFilter.songs: return 'Songs';
      case SearchFilter.albums: return 'Albums';
      case SearchFilter.artists: return 'Artists';
      case SearchFilter.playlists: return 'Playlists';
    }
  }
}

class _SearchResults extends StatelessWidget {
  final List<SearchResult> results;
  final Function(SearchResult) onPlay;

  const _SearchResults({required this.results, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final typeIcon = _getTypeIcon(result.type);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: result.type == 'artist' ? BorderRadius.circular(25) : BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: result.imageUrl ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: MyColors.darkGreyColor,
                child: Icon(
                  result.type == 'artist' ? Icons.person : Icons.music_note,
                  color: MyColors.whiteColor,
                ),
              ),
            ),
          ),
          title: Text(
            result.title,
            style: const TextStyle(fontFamily: "AM", fontSize: 15, color: MyColors.whiteColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              if (typeIcon != null) ...[
                Icon(typeIcon, size: 12, color: MyColors.lightGrey),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  result.subtitle,
                  style: const TextStyle(fontFamily: "AM", fontSize: 13, color: MyColors.lightGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: result.videoId != null
              ? GestureDetector(
                  onTap: () => onPlay(result),
                  child: const Icon(Icons.play_circle_outline, color: MyColors.whiteColor, size: 28),
                )
              : null,
        );
      },
    );
  }

  IconData? _getTypeIcon(String type) {
    switch (type) {
      case 'album': return Icons.album;
      case 'artist': return Icons.person;
      case 'playlist': return Icons.queue_music;
      default: return null;
    }
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<SearchSuggestion> suggestions;
  final Function(String) onTap;

  const _SuggestionsList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: const Icon(Icons.search, color: MyColors.lightGrey, size: 22),
          title: Text(
            suggestions[index].query,
            style: const TextStyle(fontFamily: "AM", fontSize: 15, color: MyColors.whiteColor),
          ),
          onTap: () => onTap(suggestions[index].query),
        );
      },
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final List<SearchResult> searches;
  final Function(SearchResult) onRemove;
  final Function(String) onTap;

  const _RecentSearches({required this.searches, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: MyColors.lightGrey, size: 60),
            SizedBox(height: 20),
            Text("Search for songs, albums, artists...", style: TextStyle(fontFamily: "AM", color: MyColors.lightGrey, fontSize: 15)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 15, bottom: 20),
          child: Text("Recent searches", style: TextStyle(fontFamily: "AM", fontWeight: FontWeight.w400, color: MyColors.whiteColor, fontSize: 17)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searches.length,
            itemBuilder: (context, index) {
              final item = searches[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: MyColors.darkGreyColor,
                      child: const Icon(Icons.music_note, color: MyColors.whiteColor),
                    ),
                  ),
                ),
                title: Text(item.title, style: const TextStyle(fontFamily: "AM", fontSize: 15, color: MyColors.whiteColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.subtitle, style: const TextStyle(fontFamily: "AM", fontSize: 13, color: MyColors.lightGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: GestureDetector(
                  onTap: () => onRemove(item),
                  child: const Icon(Icons.close, color: MyColors.lightGrey, size: 18),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
