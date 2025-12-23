import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/notification_viewmodel.dart';

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
      // Hardcoded user ID 4 as per user request/api example for now
      context.read<NotificationViewModel>().fetchNotifications(4);
    });
  }

  Future<void> _handleNotificationTap(String typeId, String url) async {
    if (typeId == "-1" && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Could show a toast or alert if URL can't be launched
        debugPrint('Could not launch $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Bildirimler'),
        backgroundColor: Colors.white,
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
                      onPressed: () => viewModel.fetchNotifications(4),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.notifications.isEmpty) {
              return const Center(child: Text('Bildiriminiz bulunmamaktadır.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                final notification = viewModel.notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
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
                      onPressed: () => _handleNotificationTap(
                        notification.typeId,
                        notification.url,
                      ),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontFamily:
                                          '.SF Pro Text', // System font usually
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
