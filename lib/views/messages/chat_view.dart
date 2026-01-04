import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/ticket_viewmodel.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/theme/app_theme.dart';

import '../../models/tickets/ticket_model.dart';
import '../products/product_detail_view.dart';
import '../profile/user_profile_view.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/home_view.dart';

class ChatView extends StatefulWidget {
  final Ticket ticket;

  const ChatView({super.key, required this.ticket});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages(isRefresh: true);
      _fetchTicketDetail();
    });
    _startPolling();
  }

  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.user?.token != null && widget.ticket.ticketID != null) {
        // Silent refresh to avoid loading spinner
        context.read<TicketViewModel>().fetchMessages(
          widget.ticket.ticketID!,
          authVM.user!.token,
          isRefresh: true,
          isSilent: true,
        );
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _fetchMessages({bool isRefresh = false}) {
    final authVM = context.read<AuthViewModel>();
    if (authVM.user?.token != null) {
      context.read<TicketViewModel>().fetchMessages(
        widget.ticket.ticketID!,
        authVM.user!.token,
        isRefresh: isRefresh,
      );
    }
  }

  void _onScroll() {
    // In a reverse list, maxScrollExtent is the visual TOP of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.user?.token != null) {
        context.read<TicketViewModel>().fetchMessages(
          widget.ticket.ticketID!,
          authVM.user!.token,
        );
      }
    }
  }

  void _fetchTicketDetail() {
    final authVM = context.read<AuthViewModel>();
    if (authVM.user?.token != null && widget.ticket.ticketID != null) {
      context.read<TicketViewModel>().fetchTicketDetail(
        widget.ticket.ticketID!,
        authVM.user!.token,
      );
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _navigateToProduct(int? productId) {
    if (productId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailView(productId: productId),
        ),
      );
    }
  }

  void _showReportDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcıyı Raporla"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Raporlama sebebinizi yazın...",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final authVM = context.read<AuthViewModel>();
              final ticketVM = context.read<TicketViewModel>();

              if (authVM.user?.token != null &&
                  widget.ticket.otherUserID != null) {
                final success = await ticketVM.reportUser(
                  userToken: authVM.user!.token,
                  reportedUserID: widget.ticket.otherUserID!,
                  reason: reason,
                  step: "user", // As per requirement
                  productID: widget.ticket.productID,
                  offerID: widget.ticket.offerID,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Kullanıcı raporlandı."
                            : "Raporlanırken hata oluştu.",
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcıyı Engelle"),
        content: const Text(
          "Bu kullanıcıyı engellemek istediğinize emin misiniz? Bu işlemden sonra birbirinize mesaj gönderemeyeceksiniz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final authVM = context.read<AuthViewModel>();
              final ticketVM = context.read<TicketViewModel>();

              if (authVM.user?.token != null &&
                  widget.ticket.otherUserID != null) {
                final success = await ticketVM.blockUser(
                  userToken: authVM.user!.token,
                  blockedUserID: widget.ticket.otherUserID!,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    // Trigger refresh on all data
                    context.read<ProductViewModel>().fetchProducts(
                      isRefresh: true,
                    );
                    context.read<HomeViewModel>().init();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                      (route) => false,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Kullanıcı engellendi."
                            : "Engellenirken hata oluştu.",
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Engelle", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(int? userId) {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => ProfileViewModel(),
            child: UserProfileView(userId: userId),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Consumer<TicketViewModel>(
          builder: (context, viewModel, child) {
            final name =
                viewModel.currentTicketDetail?.otherFullname ??
                widget.ticket.otherFullname ??
                "Sohbet";
            return InkWell(
              onTap: () => _navigateToProfile(
                viewModel.currentTicketDetail?.otherUserID ??
                    widget.ticket.otherUserID,
              ),
              child: Text(
                name,
                style: AppTheme.safePoppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.surface,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.surface),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.surface),
            onSelected: (value) {
              if (value == 'profile') {
                _navigateToProfile(widget.ticket.otherUserID);
              } else if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockConfirmDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 8),
                      Text("Kullanıcının profiline git"),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        size: 18,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text("Kullanıcıyı Raporla"),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block_flipped, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Kullanıcıyı Engelle"),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<TicketViewModel>(
            builder: (context, viewModel, child) {
              final detail = viewModel.currentTicketDetail;

              // 1. Determine Target Product Info
              final targetTitle =
                  detail?.targetProduct?.productTitle ??
                  widget.ticket.productTitle;
              final targetImage =
                  detail?.targetProduct?.productImage ??
                  widget.ticket.productImage;
              final targetId =
                  detail?.targetProduct?.productID ?? widget.ticket.productID;

              // 2. Determine Offered Product Info
              final offeredTitle = detail?.offeredProduct?.productTitle;
              final offeredImage = detail?.offeredProduct?.productImage;
              final offeredId = detail?.offeredProduct?.productID;

              if (targetTitle == null) return const SizedBox.shrink();

              // --- CASE A: TRADE CONTEXT (Both products exist) ---
              if (offeredTitle != null) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Target Product Section
                      Expanded(
                        child: InkWell(
                          onTap: () => _navigateToProduct(targetId),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            child: Row(
                              children: [
                                _buildProductThumb(targetImage),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        targetTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.safePoppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        "İstenen Ürün",
                                        style: AppTheme.safePoppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Swap Icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: AppTheme.primary.withOpacity(0.8),
                          size: 20,
                        ),
                      ),

                      // Offered Product Section
                      Expanded(
                        child: InkWell(
                          onTap: () => _navigateToProduct(offeredId),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        offeredTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.safePoppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        "Teklif Edilen",
                                        style: AppTheme.safePoppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildProductThumb(offeredImage),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // --- CASE B: SINGLE PRODUCT CONTEXT ---
              return InkWell(
                onTap: () => _navigateToProduct(targetId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildProductThumb(targetImage),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.safePoppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              "İlan hakkında konuşuyorsunuz",
                              style: AppTheme.safePoppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<TicketViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isMessageLoading && viewModel.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.messageErrorMessage != null &&
                    viewModel.messages.isEmpty) {
                  return Center(child: Text(viewModel.messageErrorMessage!));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Latest messages at bottom
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount:
                      viewModel.messages.length +
                      (viewModel.isMessageLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == viewModel.messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final message = viewModel.messages[index];
                    final isMine = message.isMine == true;
                    final isAdmin = message.isAdmin == true;

                    if (isAdmin) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.message ?? "",
                            textAlign: TextAlign.center,
                            style: AppTheme.safePoppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMine) ...[
                            InkWell(
                              onTap: () =>
                                  _navigateToProfile(message.senderUserID),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primary.withOpacity(
                                  0.1,
                                ),
                                backgroundImage: message.senderPhoto != null
                                    ? NetworkImage(message.senderPhoto!)
                                    : null,
                                child: message.senderPhoto == null
                                    ? Text(
                                        message.senderName != null &&
                                                message.senderName!.isNotEmpty
                                            ? message.senderName![0]
                                                  .toUpperCase()
                                            : "?",
                                        style: AppTheme.safePoppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? AppTheme.primary.withOpacity(0.8)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMine
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomRight: isMine
                                      ? Radius.zero
                                      : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.message ?? "",
                                    style: AppTheme.safePoppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: isMine
                                          ? AppTheme.surface
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        message.createdAt?.split(' ').last ??
                                            "",
                                        style: AppTheme.safePoppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.normal,
                                          color: isMine
                                              ? AppTheme.surface.withOpacity(
                                                  0.9,
                                                )
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (isMine) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.done_all_rounded,
                                          size: 15,
                                          color: message.isRead == true
                                              ? Colors.greenAccent
                                              : Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMine) const SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Mesaj yaz...",
                  hintStyle: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 12),
            Consumer<TicketViewModel>(
              builder: (context, viewModel, child) {
                return GestureDetector(
                  onTap: viewModel.isSendingMessage
                      ? null
                      : () async {
                          final message = _messageController.text.trim();
                          if (message.isEmpty) return;

                          final authVM = context.read<AuthViewModel>();
                          if (authVM.user?.token == null) return;

                          final success = await viewModel.sendMessage(
                            widget.ticket.ticketID!,
                            authVM.user!.token,
                            message,
                          );

                          if (success) {
                            _messageController.clear();
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.messageErrorMessage ??
                                      "Mesaj gönderilemedi.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: viewModel.isSendingMessage
                          ? Colors.grey
                          : AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: viewModel.isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppTheme.surface,
                            size: 20,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductThumb(String? imageUrl) {
    if (imageUrl != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: Colors.grey.shade400,
        ),
      );
    }
  }
}
