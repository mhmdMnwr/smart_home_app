import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/logs_cubit.dart';
import '../cubit/logs_state.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  void initState() {
    super.initState();
    context.read<LogsCubit>().loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: const Color(0xFF0F1117),
      ),
      body: BlocBuilder<LogsCubit, LogsState>(
        builder: (context, state) {
          if (state.isLoading && state.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<LogsCubit>().loadPage(
                            page: state.currentPage,
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.logs.isEmpty) {
            return Center(
              child: Text(
                'No logs found',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<LogsCubit>().loadPage(
                        page: state.currentPage,
                      ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: state.logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = state.logs[index];
                      return _LogTile(
                        device: log.device,
                        message: log.message,
                        createdAt: log.createdAt,
                      );
                    },
                  ),
                ),
              ),
              _PaginationBar(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.state});

  final LogsState state;

  @override
  Widget build(BuildContext context) {
    final canGoPrev = !state.isLoading && state.currentPage > 1;
    final canGoNext = !state.isLoading && state.currentPage < state.totalPages;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141925),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoPrev
                  ? () => context.read<LogsCubit>().loadPreviousPage()
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Page ${state.currentPage}/${state.totalPages}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed:
                  canGoNext ? () => context.read<LogsCubit>().loadNextPage() : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.device,
    required this.message,
    required this.createdAt,
  });

  final String device;
  final String message;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.isNotEmpty ? device : 'Unknown device',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final mo = date.month.toString().padLeft(2, '0');
    return '$dd/$mo/${date.year} $hh:$mm';
  }
}
