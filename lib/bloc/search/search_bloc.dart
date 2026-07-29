import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tunefy/bloc/search/search_event.dart';
import 'package:tunefy/bloc/search/search_state.dart';
import 'package:tunefy/services/search_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  Timer? _debounce;
  String _lastQuery = '';
  SearchFilter _currentFilter = SearchFilter.all;

  SearchBloc() : super(SearchInitState()) {
    on<SearchQueryEvent>((event, emit) async {
      _lastQuery = event.query;
      _currentFilter = event.filter;
      if (event.query.trim().isEmpty) {
        emit(SearchInitState());
        return;
      }

      emit(SearchLoadingState());
      final results = await SearchService.search(event.query, filter: event.filter);
      if (results.isNotEmpty) {
        emit(SearchResultsState(results));
      } else {
        emit(SearchErrorState('Aucun résultat pour "${event.query}"'));
      }
    });

    on<SearchFilterEvent>((event, emit) async {
      _currentFilter = event.filter;
      if (_lastQuery.isNotEmpty) {
        emit(SearchLoadingState());
        final results = await SearchService.search(_lastQuery, filter: event.filter);
        if (results.isNotEmpty) {
          emit(SearchResultsState(results));
        } else {
          emit(SearchErrorState('Aucun résultat'));
        }
      }
    });

    on<SearchSuggestionsEvent>((event, emit) async {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () async {
        if (event.query.length < 2) {
          emit(SearchInitState());
          return;
        }
        final suggestions = await SearchService.getSuggestions(event.query);
        emit(SearchSuggestionsState(suggestions));
      });
    });

    on<SearchClearEvent>((event, emit) {
      _debounce?.cancel();
      _lastQuery = '';
      _currentFilter = SearchFilter.all;
      emit(SearchInitState());
    });
  }

  SearchFilter get currentFilter => _currentFilter;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
