import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/ticket_viewmodel.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/theme/app_theme.dart';
import 'chat_view.dart';

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
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          if (viewModel.tickets.isEmpty) {
            return Center(
              child: Text(
                viewModel.emptyMessage ?? "Henüz mesajınız yok.",
                style: AppTheme.safePoppins(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.textSecondary,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _fetchTickets(isRefresh: true);
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  viewModel.tickets.length +
                  (viewModel.isLoadMoreRunning ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == viewModel.tickets.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final ticket = viewModel.tickets[index];
                final userPhoto = ticket.otherProfilePhoto ?? ticket.otherPhoto;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              )
                            : null,
                      ),
                      if (ticket.productImage != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(ticket.productImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
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
                            fontWeight: FontWeight.normal,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.productTitle != null)
                        Text(
                          "İlan: ${ticket.productTitle}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.safePoppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      Text(
                        ticket.lastMessage ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.safePoppins(
                          fontSize: 13,
                          color: (ticket.isUnread == true)
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontWeight: (ticket.isUnread == true)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  trailing:
                      (ticket.isUnread == true && (ticket.unreadCount ?? 0) > 0)
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            ticket.unreadCount.toString(),
                            style: AppTheme.safePoppins(
                              color: AppTheme.surface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.grey),
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
    );
  }
}
