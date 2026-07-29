import 'package:tunefy/services/search_service.dart';

abstract class SearchEvent {}

class SearchQueryEvent extends SearchEvent {
  final String query;
  final SearchFilter filter;
  SearchQueryEvent(this.query, {this.filter = SearchFilter.all});
}

class SearchFilterEvent extends SearchEvent {
  final SearchFilter filter;
  SearchFilterEvent(this.filter);
}

class SearchSuggestionsEvent extends SearchEvent {
  final String query;
  SearchSuggestionsEvent(this.query);
}

class SearchClearEvent extends SearchEvent {}
