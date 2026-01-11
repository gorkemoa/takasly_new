import 'dart:async';
import 'dart:io'; // Import for Platform
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import for FirebaseMessaging
import '../../services/firebase_messaging_service.dart'; // Import for FirebaseMessagingService
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/ticket_viewmodel.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/theme/app_theme.dart';

import '../../services/analytics_service.dart';

import '../../models/tickets/ticket_model.dart';
import '../products/product_detail_view.dart';
import '../profile/user_profile_view.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/home_view.dart';
import '../../models/trade_model.dart';
import '../profile/trade_detail_view.dart';

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
    AnalyticsService().logScreenView('Sohbet');
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages(isRefresh: true);
      _fetchTicketDetail();
    });

    // Set active ticket ID to suppress notifications
    if (widget.ticket.ticketID != null) {
      FirebaseMessagingService.activeTicketId = widget.ticket.ticketID;

      // iOS: Temporarily disable foreground notification alerts
      if (Platform.isIOS) {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: true,
        );
      }
    }

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

    // Reset active ticket ID
    FirebaseMessagingService.activeTicketId = null;

    // iOS: Re-enable foreground notification alerts
    if (Platform.isIOS) {
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToProduct(int? productId) async {
    if (productId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailView(productId: productId),
        ),
      );
      if (mounted) {
        _fetchTicketDetail();
      }
    }
  }

  void _showReportDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: const Text("Kullanıcıyı Raporla"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Raporlama sebebinizi yazın...",
          ),
          textCapitalization: TextCapitalization.sentences,
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
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
        title: Consumer2<TicketViewModel, AuthViewModel>(
          builder: (context, viewModel, authVM, child) {
            final name =
                viewModel.currentTicketDetail?.otherFullname ??
                widget.ticket.otherFullname ??
                "Sohbet";
            final otherIsAdmin =
                viewModel.currentTicketDetail?.isAdmin == true ||
                widget.ticket.isAdmin == true ||
                name.toLowerCase().contains("takasly destek");

            return InkWell(
              onTap: otherIsAdmin
                  ? null
                  : () => _navigateToProfile(
                      viewModel.currentTicketDetail?.otherUserID ??
                          widget.ticket.otherUserID,
                    ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTheme.safePoppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.surface,
                        ),
                      ),
                      if (otherIsAdmin) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  if (otherIsAdmin)
                    Text(
                      "RESMİ YETKİLİ",
                      style: AppTheme.safePoppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor:
            context.watch<TicketViewModel>().currentTicketDetail?.isAdmin ==
                    true ||
                widget.ticket.isAdmin == true ||
                (widget.ticket.otherFullname?.toLowerCase().contains(
                      "takasly destek",
                    ) ??
                    false)
            ? Colors.amber.shade800
            : (context.watch<AuthViewModel>().userProfile?.isAdmin == true
                  ? Colors.black
                  : AppTheme.primary),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.surface),
        actions: [
          Consumer<TicketViewModel>(
            builder: (context, viewModel, child) {
              final name =
                  viewModel.currentTicketDetail?.otherFullname ??
                  widget.ticket.otherFullname ??
                  "";
              final isAdmin =
                  viewModel.currentTicketDetail?.isAdmin == true ||
                  widget.ticket.isAdmin == true ||
                  name.toLowerCase().contains("takasly destek");

              if (isAdmin) return const SizedBox.shrink();

              return PopupMenuButton<String>(
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
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          Text("Kullanıcıyı Raporla"),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            Icons.block_flipped,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text("Kullanıcıyı Engelle"),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<TicketViewModel>(
            builder: (context, viewModel, child) {
              final detail = viewModel.currentTicketDetail;
              final isAdmin =
                  detail?.isAdmin == true ||
                  widget.ticket.isAdmin == true ||
                  (detail?.otherFullname?.toLowerCase().contains(
                        "takasly destek",
                      ) ??
                      widget.ticket.otherFullname?.toLowerCase().contains(
                        "takasly destek",
                      ) ??
                      false);

              // 1. Determine Target Product Info
              final targetId =
                  detail?.targetProduct?.productID ?? widget.ticket.productID;
              final targetTitle =
                  detail?.targetProduct?.productTitle ??
                  widget.ticket.productTitle ??
                  (targetId != null ? "İlan..." : "Bilinmeyen İlan");
              final targetImage =
                  detail?.targetProduct?.productImage ??
                  widget.ticket.productImage;

              // 2. Determine Offered Product Info
              final offeredTitle = detail?.offeredProduct?.productTitle;
              final offeredImage = detail?.offeredProduct?.productImage;
              final offeredId = detail?.offeredProduct?.productID;

              if (targetId == null) {
                return const SizedBox.shrink();
              }

              // --- CASE A: TRADE CONTEXT (Both products exist) ---
              if (offeredTitle != null) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _navigateToProduct(targetId),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  8,
                                  12,
                                ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: AppTheme.primary.withOpacity(0.8),
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _navigateToProduct(offeredId),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  8,
                                  12,
                                  16,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                      if (viewModel.tradeCheckResult?['showButtons'] == false)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                            left: 16,
                            right: 16,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    viewModel.tradeCheckResult?['message'] ??
                                        "İşlem beklemede",
                                    style: AppTheme.safePoppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () => _startTradeFlow(
                              targetId,
                              senderProductId: offeredId,
                            ),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text("Takas Detaylarını Belirle"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              // --- CASE B: SINGLE PRODUCT CONTEXT ---
              return InkWell(
                onTap: isAdmin ? null : () => _navigateToProduct(targetId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                      const SizedBox(width: 8),
                      if (!isAdmin)
                        ElevatedButton(
                          onPressed: () => _startTradeFlow(targetId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: AppTheme.safePoppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text("Takas Başlat"),
                        ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<TicketViewModel>(
            builder: (context, viewModel, child) {
              final name =
                  viewModel.currentTicketDetail?.otherFullname ??
                  widget.ticket.otherFullname ??
                  "";
              final isAdmin =
                  viewModel.currentTicketDetail?.isAdmin == true ||
                  widget.ticket.isAdmin == true ||
                  name.toLowerCase().contains("takasly destek");

              if (isAdmin) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.amber.shade800,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "RESMİ YETKİLİ BİLGİLENDİRMESİ",
                              style: AppTheme.safePoppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Bu hesap bir Takasly yöneticisine aittir. Kurumsal güvenliğiniz için tüm görüşmeleriniz Takasly güvencesi altındadır.",
                              style: AppTheme.safePoppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: Consumer2<TicketViewModel, AuthViewModel>(
              builder: (context, viewModel, authVM, child) {
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
                    final name = message.senderName ?? "";
                    final isAdmin =
                        message.isAdmin == true ||
                        name.toLowerCase().contains("takasly destek");

                    // If isAdmin is true but there's no senderID, it's a system message.
                    // If there's a senderID, it's a message from an admin user.
                    final isSystemMessage =
                        isAdmin && message.senderUserID == null;

                    if (isSystemMessage) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  message.message ?? "",
                                  style: AppTheme.safePoppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
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
                                    ? (authVM.userProfile?.isAdmin == true
                                          ? Colors.black
                                          : AppTheme.primary.withOpacity(0.8))
                                    : (isAdmin ? null : AppTheme.surface),
                                gradient: !isMine && isAdmin
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.amber.shade50,
                                          Colors.amber.shade100,
                                        ],
                                      )
                                    : null,
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
                                border: isAdmin
                                    ? Border.all(
                                        color: Colors.amber.shade600,
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: isAdmin
                                        ? Colors.amber.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: isAdmin ? 8 : 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isAdmin && !isMine)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade700,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.verified_user_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "TAKASLY YETKİLİSİ",
                                              style: AppTheme.safePoppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            message.createdAt
                                                    ?.split(' ')
                                                    .last ??
                                                "",
                                            style: AppTheme.safePoppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.normal,
                                              color: isMine
                                                  ? AppTheme.surface
                                                        .withOpacity(0.9)
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                          if (isMine)
                                            Text(
                                              message.isRead == true
                                                  ? "Okundu"
                                                  : "Okunmadı",
                                              style: AppTheme.safePoppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
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

  void _startTradeFlow(int receiverProductId, {int? senderProductId}) async {
    final authVM = context.read<AuthViewModel>();
    final ticketVM = context.read<TicketViewModel>();
    if (authVM.user == null) return;

    // Fetch delivery types and products
    await Future.wait([
      ticketVM.fetchDeliveryTypes(),
      if (senderProductId == null)
        ticketVM.fetchMyProducts(authVM.user!.userID, authVM.user!.token),
    ]);

    if (!mounted) return;

    if (senderProductId != null) {
      // If we already know which product we are offering, go straight to details
      _showDeliveryDetailsDialog(senderProductId, receiverProductId);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductSelectionSheet(receiverProductId),
    );
  }

  Widget _buildProductSelectionSheet(int receiverProductId) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Takas Edilecek Ürünü Seç",
                style: AppTheme.safePoppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<TicketViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isMyProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.myProducts.isEmpty) {
                  return Center(
                    child: Text(
                      "Henüz bir ürünün yok.",
                      style: AppTheme.safePoppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: viewModel.myProducts.length,
                  itemBuilder: (context, index) {
                    final product = viewModel.myProducts[index];
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _showDeliveryDetailsDialog(
                          product.productID!,
                          receiverProductId,
                        );
                      },
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(product.productImage ?? ""),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        product.productTitle ?? "",
                        style: AppTheme.safePoppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        product.productCondition ?? "",
                        style: AppTheme.safePoppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryDetailsDialog(int senderProductId, int receiverProductId) {
    final TextEditingController locationController = TextEditingController();
    int deliveryTypeID = 1;
    final ticketVM = context.read<TicketViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          return AlertDialog(
            title: const Text("Teslimat Detayları"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: deliveryTypeID,
                    decoration: const InputDecoration(
                      labelText: "Teslimat Türü",
                    ),
                    items: ticketVM.deliveryTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.deliveryID,
                        child: Text(type.deliveryTitle ?? ""),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) ss(() => deliveryTypeID = value);
                    },
                  ),
                  if (deliveryTypeID == 1) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: "Buluşma Yeri",
                        hintText: "Örn: İstanbul / Kadıköy",
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (deliveryTypeID == 1 && locationController.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text("Lütfen buluşma yeri yazın."),
                      ),
                    );
                    return;
                  }

                  final authVM = context.read<AuthViewModel>();
                  final ticketVM = context.read<TicketViewModel>();

                  final request = StartTradeRequestModel(
                    userToken: authVM.user!.token,
                    senderProductID: senderProductId,
                    receiverProductID: receiverProductId,
                    deliveryTypeID: deliveryTypeID,
                    meetingLocation: deliveryTypeID == 1
                        ? locationController.text
                        : null,
                  );

                  Navigator.pop(ctx); // Close dialog

                  try {
                    final response = await ticketVM.startTrade(request);
                    if (mounted) {
                      final message =
                          response['message'] ??
                          response['data']?['message'] ??
                          "Takas teklifi başarıyla gönderildi.";
                      final int? offerId = response['data']?['offerID'];

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.green,
                        ),
                      );

                      if (offerId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TradeDetailView(offerId: offerId),
                          ),
                        );
                      }

                      // Refresh ticket detail to update context banner
                      ticketVM.fetchTicketDetail(
                        widget.ticket.ticketID!,
                        authVM.user!.token,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Hata: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Teklifi Gönder"),
              ),
            ],
          );
        },
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
                textCapitalization: TextCapitalization.sentences,
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
