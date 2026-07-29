import 'package:tunefy/services/search_service.dart';

abstract class SearchState {}

class SearchInitState extends SearchState {}

class SearchLoadingState extends SearchState {}

class SearchResultsState extends SearchState {
  final List<SearchResult> results;
  SearchResultsState(this.results);
}

class SearchSuggestionsState extends SearchState {
  final List<SearchSuggestion> suggestions;
  SearchSuggestionsState(this.suggestions);
}

class SearchErrorState extends SearchState {
  final String message;
  SearchErrorState(this.message);
}
