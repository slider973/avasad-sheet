import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import 'package:time_sheet/features/validation/domain/entities/notification.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_detail/validation_detail_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/validation_detail_page.dart';
import 'package:time_sheet/services/injection_container.dart' as di;

/// Page affichant les notifications de l'utilisateur (boucle de feedback
/// employé↔manager). Consomme [ValidationRepository.watchUserNotifications]
/// (PowerSync, offline-first) — voir aussi le badge dans l'AppDrawer.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = di.getIt<ValidationRepository>();
    final userId = SupabaseService.instance.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () => repo.markAllNotificationsAsRead(userId),
          ),
        ],
      ),
      body: StreamBuilder<Either<Failure, List<NotificationEntity>>>(
        stream: repo.watchUserNotifications(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data!.fold(
            (failure) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur: ${failure.message}'),
              ),
            ),
            (notifications) {
              if (notifications.isEmpty) return _buildEmpty();
              return ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _buildTile(context, repo, notifications[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    ValidationRepository repo,
    NotificationEntity n,
  ) {
    final unread = !n.read;
    return ListTile(
      tileColor: unread ? Colors.teal.withValues(alpha: 0.06) : null,
      leading: CircleAvatar(
        backgroundColor: _iconColor(n.type).withValues(alpha: 0.15),
        child: Icon(_iconFor(n.type), color: _iconColor(n.type), size: 20),
      ),
      title: Text(
        n.title,
        style: TextStyle(
          fontWeight: unread ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.body, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(n.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () async {
        if (unread) {
          await repo.markNotificationAsRead(n.id);
        }
        final validationId = n.validationRequestId;
        if (validationId == null || !context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => di.getIt<ValidationDetailBloc>(),
              child: ValidationDetailPage(
                validationId: validationId,
                isManager: n.type == NotificationType.validationRequest,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.validationRequest:
        return Icons.pending_actions;
      case NotificationType.validationFeedback:
        return Icons.fact_check;
      case NotificationType.reminder:
        return Icons.alarm;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.validationRequest:
        return Colors.blue;
      case NotificationType.validationFeedback:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
    }
  }
}
