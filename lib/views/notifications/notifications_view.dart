import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/navigation_service.dart';
import '../../models/notification/notification_model.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final userId = authVM.user?.userID;
      if (userId != null) {
        context.read<NotificationViewModel>().fetchNotifications(userId);
      }
    });
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    final authVM = context.read<AuthViewModel>();
    final notVM = context.read<NotificationViewModel>();
    final token = authVM.user?.token;

    if (token != null) {
      // Mark as read without awaiting to proceed quickly
      notVM.markAsRead(token, notification.id);
    }

    NavigationService().handleDeepLink(
      type: notification.type,
      typeId: int.tryParse(notification.typeId) ?? 0,
      url: notification.url,
      title: notification.title,
    );
  }

  void _showActions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Seçenekler'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Tümünü Okundu İşaretle'),
            onPressed: () {
              Navigator.pop(context);
              final authVM = context.read<AuthViewModel>();
              final notVM = context.read<NotificationViewModel>();
              if (authVM.user?.token != null) {
                notVM.markAllAsRead(authVM.user!.token);
              }
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Tümünü Sil'),
            onPressed: () {
              Navigator.pop(context);
              final authVM = context.read<AuthViewModel>();
              final notVM = context.read<NotificationViewModel>();
              if (authVM.user?.token != null) {
                notVM.deleteAllNotifications(authVM.user!.token);
              }
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('İptal'),
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Bildirimler'),
        backgroundColor: Colors.white,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis_circle),
          onPressed: () => _showActions(context),
        ),
      ),
      backgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background Color
      child: SafeArea(
        child: Consumer<NotificationViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      child: const Text('Tekrar Dene'),
                      onPressed: () {
                        final userId = context
                            .read<AuthViewModel>()
                            .user
                            ?.userID;
                        if (userId != null) {
                          viewModel.fetchNotifications(userId);
                        }
                      },
                    ),
                  ],
                ),
              );
            }

            if (viewModel.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.bell_slash,
                      size: 64,
                      color: CupertinoColors.systemGrey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bildiriminiz bulunmamaktadır.',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                final notification = viewModel.notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: Key(notification.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      final token = context.read<AuthViewModel>().user?.token;
                      if (token != null) {
                        viewModel.deleteNotification(token, notification.id);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _handleNotificationTap(notification),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dot for unread status
                                  if (!notification.isRead)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 6,
                                        right: 8,
                                      ),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: CupertinoColors.activeBlue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight: notification.isRead
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    notification.createDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
