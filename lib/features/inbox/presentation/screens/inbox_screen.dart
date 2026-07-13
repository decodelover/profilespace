/// Inbox Screen — Recruiter Connection Messages
///
/// Displays structured inbound inquiries from recruiters with
/// category tags, company info, and quick-action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message.dart';
import '../bloc/inbox_bloc.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<InboxBloc>()..add(const InboxFetchRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: BlocBuilder<InboxBloc, InboxState>(
          builder: (context, state) {
            if (state is InboxLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            if (state is InboxError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<InboxBloc>()
                            .add(const InboxFetchRequested()),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is InboxLoaded) {
              final messages = state.messages;
              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_outline_rounded,
                            color: AppColors.textMuted, size: 64),
                        const SizedBox(height: AppSpacing.md),
                        Text('No messages yet',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'When recruiters contact you through\nyour portfolio, messages will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () async {
                  context.read<InboxBloc>().add(const InboxFetchRequested());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _InboxCard(msg: msg);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  final Message msg;

  const _InboxCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isHiring = msg.tag.toLowerCase().contains('hiring') ||
        msg.tag.toLowerCase().contains('recruiter');

    // Format date string simply
    final dateStr = '${msg.createdAt.year}-${msg.createdAt.month.toString().padLeft(2, '0')}-${msg.createdAt.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                child: Text(
                  msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : 'R',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.senderName,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(msg.company ?? 'Individual Recruiter',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(dateStr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isHiring ? AppColors.accent : AppColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              msg.tag.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHiring ? AppColors.accent : AppColors.warning,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Message Body
          Text(
            msg.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Launch mail client natively
                  },
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: const Text('Email Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
