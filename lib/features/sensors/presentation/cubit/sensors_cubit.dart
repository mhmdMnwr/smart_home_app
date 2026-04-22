import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/sensors_repository.dart';
import 'sensors_state.dart';

class SensorsCubit extends Cubit<SensorsState> {
  SensorsCubit({required SensorsRepository sensorsRepository})
      : _sensorsRepository = sensorsRepository,
        super(const SensorsState());

  final SensorsRepository _sensorsRepository;

  static const int _pageLimit = 10;

  Future<void> loadInitial() async {
    await loadHistory(type: SensorType.temperature, page: 1, limit: _pageLimit);
  }

  Future<void> selectType(SensorType type) async {
    emit(state.copyWith(selectedType: type));

    if (type == SensorType.fire) {
      return;
    }

    final current = state.historyStateFor(type);
    if (current.allItems.isNotEmpty || current.isLoading) {
      return;
    }

    await loadHistory(type: type, page: 1, limit: _pageLimit);
  }

  /// Load a specific page and **append** items for infinite scroll.
  Future<void> loadHistory({
    required SensorType type,
    int page = 1,
    int limit = _pageLimit,
  }) async {
    if (type == SensorType.fire) {
      return;
    }

    final current = state.historyStateFor(type);

    _emitTypeState(
      type,
      current.copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      final pageData = await _sensorsRepository.getHistory(
        type: _apiType(type),
        page: page,
        limit: limit,
      );

      final updatedItems = page == 1
          ? pageData.items
          : <dynamic>[...current.allItems, ...pageData.items];

      final hasReachedMax = page >= pageData.totalPages;

      _emitTypeState(
        type,
        current.copyWith(
          isLoading: false,
          errorMessage: null,
          pageData: pageData,
          allItems: List<dynamic>.from(updatedItems).cast(),
          hasReachedMax: hasReachedMax,
          currentPage: page,
        ),
      );
    } on AppException catch (error) {
      _emitTypeState(
        type,
        current.copyWith(
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      _emitTypeState(
        type,
        current.copyWith(
          isLoading: false,
          errorMessage: AppStrings.genericError,
        ),
      );
    }
  }

  /// Called when the user scrolls near the bottom – loads next page.
  Future<void> loadMore(SensorType type) async {
    final current = state.historyStateFor(type);
    if (current.isLoading || current.hasReachedMax) {
      return;
    }

    final nextPage = current.currentPage + 1;
    await loadHistory(type: type, page: nextPage, limit: _pageLimit);
  }

  // Keep legacy helpers for backward compat (unused now but harmless).
  Future<void> goToPreviousPage(SensorType type) async {
    final current = state.historyStateFor(type).pageData;
    if (current == null || current.page <= 1) {
      return;
    }

    await loadHistory(type: type, page: current.page - 1, limit: current.limit);
  }

  Future<void> goToNextPage(SensorType type) async {
    final current = state.historyStateFor(type).pageData;
    if (current == null || current.page >= current.totalPages) {
      return;
    }

    await loadHistory(type: type, page: current.page + 1, limit: current.limit);
  }

  String _apiType(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return 'temperature';
      case SensorType.humidity:
        return 'humidity';
      case SensorType.gas:
        return 'gas';
      case SensorType.fire:
        return 'fire';
    }
  }

  void _emitTypeState(SensorType type, SensorHistoryState next) {
    switch (type) {
      case SensorType.temperature:
        emit(state.copyWith(temperatureState: next));
        return;
      case SensorType.humidity:
        emit(state.copyWith(humidityState: next));
        return;
      case SensorType.gas:
        emit(state.copyWith(gasState: next));
        return;
      case SensorType.fire:
        return;
    }
  }
}
