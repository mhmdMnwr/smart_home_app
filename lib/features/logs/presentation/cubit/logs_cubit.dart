import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/logs_repository.dart';
import 'logs_state.dart';

class LogsCubit extends Cubit<LogsState> {
  LogsCubit({
    required LogsRepository logsRepository,
  })  : _logsRepository = logsRepository,
        super(const LogsState());

  final LogsRepository _logsRepository;

  Future<void> loadPage({int page = 1}) async {
    if (state.isLoading) {
      return;
    }

    final safePage = page < 1 ? 1 : page;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final pageData = await _logsRepository.getLogs(
        page: safePage,
        limit: state.limit,
      );
      emit(state.copyWith(
        logs: pageData.items,
        total: pageData.total,
        currentPage: safePage,
        isLoading: false,
        errorMessage: null,
      ));
    } on AppException catch (error) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: AppStrings.genericError,
      ));
    }
  }

  Future<void> loadNextPage() async {
    if (state.currentPage >= state.totalPages) {
      return;
    }
    await loadPage(page: state.currentPage + 1);
  }

  Future<void> loadPreviousPage() async {
    if (state.currentPage <= 1) {
      return;
    }
    await loadPage(page: state.currentPage - 1);
  }
}
