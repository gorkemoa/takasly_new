import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/ticket_viewmodel.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/theme/app_theme.dart';
import '../../models/tickets/ticket_model.dart';
import 'chat_view.dart';

import '../widgets/ads/banner_ad_widget.dart';

class TicketsView extends StatefulWidget {
  const TicketsView({super.key});

  @override
  State<TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends State<TicketsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTickets();
    });
  }

  void _fetchTickets({bool isRefresh = false}) {
    final authVM = context.read<AuthViewModel>();
    final ticketVM = context.read<TicketViewModel>();

    // Guard: Don't trigger initial fetch if already loading (started by HomeView)
    if (!isRefresh && ticketVM.isLoading) return;

    if (authVM.user?.token != null) {
      ticketVM.fetchTickets(authVM.user!.token, isRefresh: isRefresh);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.user?.token != null) {
        context.read<TicketViewModel>().fetchTickets(authVM.user!.token);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Mesajlar",
          style: AppTheme.safePoppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.surface,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.surface),
      ),
      body: Consumer<TicketViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: AppTheme.safePoppins(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (viewModel.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),

                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: AppTheme.primary.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    viewModel.emptyMessage ?? "Henüz mesajınız yok.",
                    style: AppTheme.safePoppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _fetchTickets(isRefresh: true);
            },
            color: AppTheme.primary,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              itemCount:
                  viewModel.tickets.length +
                  (viewModel.isLoadMoreRunning ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == viewModel.tickets.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final ticket = viewModel.tickets[index];
                return _TicketCard(
                  ticket: ticket,
                  onTap: () async {
                    if (ticket.ticketID != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatView(ticket: ticket),
                        ),
                      );
                      if (context.mounted) {
                        _fetchTickets(isRefresh: true);
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 90),
        child: BannerAdWidget(),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userPhoto = ticket.otherProfilePhoto ?? ticket.otherPhoto;
    final isUnread = ticket.isUnread == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isUnread
                ? AppTheme.primary.withOpacity(0.3)
                : const Color(0xFFF1F5F9),
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar & Product Image Stack
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: userPhoto != null
                      ? NetworkImage(userPhoto)
                      : null,
                  child: userPhoto == null
                      ? Text(
                          ticket.otherFullname != null &&
                                  ticket.otherFullname!.isNotEmpty
                              ? ticket.otherFullname![0].toUpperCase()
                              : "?",
                          style: AppTheme.safePoppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                ),
                if (ticket.productImage != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(ticket.productImage!),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ticket.otherFullname ?? "Kullanıcı",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.safePoppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (ticket.lastMessageAt != null)
                        Text(
                          ticket.lastMessageAt!,
                          style: AppTheme.safePoppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (ticket.productTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        "İlan: ${ticket.productTitle}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.safePoppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.lastMessage ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.safePoppins(
                            fontSize: 13,
                            color: isUnread
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread && (ticket.unreadCount ?? 0) > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            ticket.unreadCount.toString(),
                            style: AppTheme.safePoppins(
                              color: AppTheme.surface,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
