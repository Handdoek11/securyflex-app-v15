import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/guard_notification.dart';
import '../services/guard_notification_service.dart';

/// BLoC for managing notification center state and interactions
/// 
/// Features:
/// - Load and filter notifications
/// - Mark notifications as read/unread
/// - Delete notifications
/// - Real-time updates from GuardNotificationService
/// - Error handling with user-friendly messages
/// - Integration with existing BLoC patterns from the codebase

// Events
abstract class NotificationCenterEvent extends Equatable {
  const NotificationCenterEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationCenterEvent {
  const LoadNotifications();
}

class RefreshNotifications extends NotificationCenterEvent {
  const RefreshNotifications();
}

class FilterNotifications extends NotificationCenterEvent {
  final GuardNotificationType? filter;

  const FilterNotifications(this.filter);

  @override
  List<Object?> get props => [filter];
}

class MarkAsRead extends NotificationCenterEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class MarkAllAsRead extends NotificationCenterEvent {
  const MarkAllAsRead();
}

class DeleteNotification extends NotificationCenterEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class ClearAllNotifications extends NotificationCenterEvent {
  const ClearAllNotifications();
}

// States
abstract class NotificationCenterState extends Equatable {
  const NotificationCenterState();

  @override
  List<Object?> get props => [];
}

class NotificationCenterInitial extends NotificationCenterState {}

class NotificationCenterLoading extends NotificationCenterState {}

class NotificationCenterLoaded extends NotificationCenterState {
  final List<GuardNotification> notifications;
  final List<GuardNotification> filteredNotifications;
  final int unreadCount;
  final GuardNotificationType? currentFilter;

  const NotificationCenterLoaded({
    required this.notifications,
    required this.filteredNotifications,
    required this.unreadCount,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
        notifications,
        filteredNotifications,
        unreadCount,
        currentFilter,
      ];

  NotificationCenterLoaded copyWith({
    List<GuardNotification>? notifications,
    List<GuardNotification>? filteredNotifications,
    int? unreadCount,
    GuardNotificationType? currentFilter,
    bool clearFilter = false,
  }) {
    return NotificationCenterLoaded(
      notifications: notifications ?? this.notifications,
      filteredNotifications: filteredNotifications ?? this.filteredNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentFilter: clearFilter ? null : (currentFilter ?? this.currentFilter),
    );
  }
}

class NotificationCenterError extends NotificationCenterState {
  final String message;

  const NotificationCenterError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC Implementation
class NotificationCenterBloc extends Bloc<NotificationCenterEvent, NotificationCenterState> {
  final GuardNotificationService _notificationService;

  NotificationCenterBloc({
    GuardNotificationService? notificationService,
  })  : _notificationService = notificationService ?? GuardNotificationService.instance,
        super(NotificationCenterInitial()) {
    
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<FilterNotifications>(_onFilterNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
  }

  /// Load notifications from the service
  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationCenterState> emit,
  ) async {
    emit(NotificationCenterLoading());

    try {
      // Initialize notification service if needed
      await _notificationService.initialize();

      // Load notifications
      final notifications = await _notificationService.getNotificationHistory();
      final unreadCount = await _notificationService.getUnreadCount();

      emit(NotificationCenterLoaded(
        notifications: notifications,
        filteredNotifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (error) {
      emit(NotificationCenterError(_getErrorMessage(error)));
    }
  }

  /// Refresh notifications
  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationCenterState> emit,
  ) async {
    try {
      // Load fresh data without showing loading state
      final notifications = await _notificationService.getNotificationHistory(useCache: false);
      final unreadCount = await _notificationService.getUnreadCount();

      if (state is NotificationCenterLoaded) {
        final currentState = state as NotificationCenterLoaded;
        final filteredNotifications = _applyFilter(notifications, currentState.currentFilter);

        emit(currentState.copyWith(
          notifications: notifications,
          filteredNotifications: filteredNotifications,
          unreadCount: unreadCount,
        ));
      } else {
        emit(NotificationCenterLoaded(
          notifications: notifications,
          filteredNotifications: notifications,
          unreadCount: unreadCount,
        ));
      }
    } catch (error) {
      emit(NotificationCenterError(_getErrorMessage(error)));
    }
  }

  /// Filter notifications by type
  void _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationCenterState> emit,
  ) {
    if (state is NotificationCenterLoaded) {
      final currentState = state as NotificationCenterLoaded;
      final filteredNotifications = _applyFilter(currentState.notifications, event.filter);

      emit(currentState.copyWith(
        filteredNotifications: filteredNotifications,
        currentFilter: event.filter,
        clearFilter: event.filter == null,
      ));
    }
  }

  /// Mark a single notification as read
  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationCenterState> emit,
  ) async {
    if (state is NotificationCenterLoaded) {
      final currentState = state as NotificationCenterLoaded;

      try {
        // Optimistic update - update UI immediately
        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        final updatedUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
        final filteredNotifications = _applyFilter(updatedNotifications, currentState.currentFilter);

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          filteredNotifications: filteredNotifications,
          unreadCount: updatedUnreadCount,
        ));

        // Update in service
        final success = await _notificationService.markAsRead(event.notificationId);
        if (!success) {
          // Revert if failed
          emit(currentState);
        }
      } catch (error) {
        // Revert on error
        emit(currentState);
      }
    }
  }

  /// Mark all notifications as read
  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationCenterState> emit,
  ) async {
    if (state is NotificationCenterLoaded) {
      final currentState = state as NotificationCenterLoaded;

      try {
        // Optimistic update - mark all as read
        final updatedNotifications = currentState.notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();

        final filteredNotifications = _applyFilter(updatedNotifications, currentState.currentFilter);

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          filteredNotifications: filteredNotifications,
          unreadCount: 0,
        ));

        // Update each notification in service
        for (final notification in currentState.notifications) {
          if (!notification.isRead) {
            await _notificationService.markAsRead(notification.id);
          }
        }
      } catch (error) {
        // Revert on error
        emit(currentState);
      }
    }
  }

  /// Delete a single notification
  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationCenterState> emit,
  ) async {
    if (state is NotificationCenterLoaded) {
      final currentState = state as NotificationCenterLoaded;

      try {
        // Optimistic update - remove from UI immediately
        final notificationToDelete = currentState.notifications
            .firstWhere((n) => n.id == event.notificationId);

        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != event.notificationId)
            .toList();

        final updatedUnreadCount = !notificationToDelete.isRead 
            ? currentState.unreadCount - 1 
            : currentState.unreadCount;

        final filteredNotifications = _applyFilter(updatedNotifications, currentState.currentFilter);

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          filteredNotifications: filteredNotifications,
          unreadCount: updatedUnreadCount,
        ));

        // Note: GuardNotificationService doesn't have a delete method yet
        // This would need to be implemented in the service
        // await _notificationService.deleteNotification(event.notificationId);
      } catch (error) {
        // Revert on error
        emit(currentState);
      }
    }
  }

  /// Clear all notifications
  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationCenterState> emit,
  ) async {
    if (state is NotificationCenterLoaded) {
      try {
        // Clear all notifications
        final success = await _notificationService.clearAllNotifications();
        
        if (success) {
          emit(const NotificationCenterLoaded(
            notifications: [],
            filteredNotifications: [],
            unreadCount: 0,
          ));
        }
      } catch (error) {
        emit(NotificationCenterError(_getErrorMessage(error)));
      }
    }
  }

  /// Apply filter to notifications list
  List<GuardNotification> _applyFilter(
    List<GuardNotification> notifications,
    GuardNotificationType? filter,
  ) {
    if (filter == null) {
      return notifications;
    }

    return notifications
        .where((notification) => notification.type == filter)
        .toList();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Geen internetverbinding. Controleer je verbinding en probeer opnieuw.';
    } else if (error.toString().contains('permission')) {
      return 'Geen toegang tot notificaties. Controleer je instellingen.';
    } else if (error.toString().contains('timeout')) {
      return 'Verzoek verlopen. Probeer het opnieuw.';
    } else {
      return 'Er ging iets mis bij het laden van notificaties. Probeer het opnieuw.';
    }
  }
}