import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/trade_model.dart';
import '../../models/products/product_models.dart';
import 'trade_detail_view.dart';

import '../widgets/ads/banner_ad_widget.dart';

class MyTradesView extends StatelessWidget {
  final bool showBackButton;

  const MyTradesView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return _MyTradesViewContent(showBackButton: showBackButton);
  }
}

class _MyTradesViewContent extends StatefulWidget {
  final bool showBackButton;

  const _MyTradesViewContent({required this.showBackButton});

  @override
  State<_MyTradesViewContent> createState() => _MyTradesViewContentState();
}

class _MyTradesViewContentState extends State<_MyTradesViewContent>
    with SingleTickerProviderStateMixin {
  bool _isInitDone = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.user != null) {
        context.read<TradeViewModel>().getTrades(authVM.user!.userID);
        context.read<TradeViewModel>().fetchTradeStatuses();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitDone) return;

    final authVM = context.watch<AuthViewModel>();
    if (authVM.isAuthCheckComplete) {
      _isInitDone = true;
      // The logic to fetch trades and statuses is now in initState.
      // This block can remain for other potential future initializations
      // that depend on auth completion, but the trade fetching part is moved.
    }
  }

  bool _isOngoing(Trade trade) {
    final tradeVM = context.read<TradeViewModel>();
    final statuses = tradeVM.tradeStatuses;

    // Dinamik ID bulma helper fonksiyonu
    int? getStatusId(String title) {
      if (statuses.isEmpty) return null;
      try {
        return statuses
            .firstWhere(
              (s) => (s.statusTitle?.toLowerCase() ?? '').contains(title),
            )
            .statusID;
      } catch (_) {
        return null;
      }
    }

    final int completedId = getStatusId('tamam') ?? 4;
    final int cancelledId = getStatusId('iptal') ?? 6;
    final int rejectedId = getStatusId('red') ?? 7;

    final authVM = context.read<AuthViewModel>();
    final userId = authVM.user?.userID;

    final bool isMeSender =
        trade.senderUserID == userId || trade.isSender == true;
    final int? myStatusId = isMeSender
        ? trade.senderStatusID
        : trade.receiverStatusID;

    // 1. Durum kontrolleri
    // Eğer benim tarafım tamamlanmış ise history'e at
    if (myStatusId == completedId) return false;

    // Eğer herhangi bir taraf iptal etmiş veya genel bir red varsa history'e at
    if (trade.senderStatusID == cancelledId ||
        trade.senderStatusID == rejectedId ||
        trade.receiverStatusID == cancelledId ||
        trade.receiverStatusID == rejectedId ||
        trade.isTradeRejected == true) {
      return false;
    }

    // Unused variable fix if needed, but the logic above seems sufficient
    // Since history/ongoing choice is based on myStatusId

    // 2. Takas başlamışsa veya onay bekliyorsa ongoing'dir
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Takaslarım',
          style: AppTheme.safePoppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              padding: const EdgeInsets.all(4),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.white.withOpacity(0.9),
              labelStyle: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
              unselectedLabelStyle: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              tabs: const [
                Tab(text: 'Devam Eden'),
                Tab(text: 'Geçmiş'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.trades.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            );
          }

          if (viewModel.errorMessage != null) {
            return _buildErrorState(viewModel.errorMessage!);
          }

          final ongoingTrades = viewModel.trades
              .where((t) => _isOngoing(t))
              .toList();
          final historyTrades = viewModel.trades
              .where((t) => !_isOngoing(t))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTradeList(ongoingTrades, 'Henüz aktif bir takasınız yok'),
              _buildTradeList(historyTrades, 'Takas geçmişiniz boş görünüyor'),
            ],
          );
        },
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 90),
        child: BannerAdWidget(),
      ),
    );
  }

  Widget _buildTradeList(List<Trade> trades, String emptyMessage) {
    if (trades.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          final authVM = context.read<AuthViewModel>();
          final tradeVM = context.read<TradeViewModel>();
          if (authVM.user != null) {
            await tradeVM.getTrades(authVM.user!.userID);
            await tradeVM.fetchTradeStatuses();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildEmptyState(emptyMessage),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        final authVM = context.read<AuthViewModel>();
        final tradeVM = context.read<TradeViewModel>();
        if (authVM.user != null) {
          await tradeVM.getTrades(authVM.user!.userID);
          await tradeVM.fetchTradeStatuses();
        }
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
        itemCount: trades.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final trade = trades[index];
          return _TradeItemCard(trade: trade);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horizontal_circle_outlined,
              size: 64,
              color: AppTheme.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz bir şey yok',
            style: AppTheme.safePoppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeItemCard extends StatelessWidget {
  final Trade trade;

  const _TradeItemCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (trade.offerID != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TradeDetailView(offerId: trade.offerID!),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(
                  trade.isTradeRejected == true
                      ? 'Reddedildi'
                      : (trade.senderStatusTitle ?? 'Beklemede'),
                ),
                Text(
                  trade.createdAt?.split(' ').first ?? '',
                  style: AppTheme.safePoppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildProductSide(trade.myProduct, 'Sizin')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildProductSide(trade.theirProduct, 'Alacağınız'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  trade.deliveryType?.toLowerCase() == 'kargo'
                      ? Icons.local_shipping_outlined
                      : Icons.location_on_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  trade.deliveryType ?? 'Teslimat Belirtilmemiş',
                  style: AppTheme.safePoppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
            if (trade.isTradeRejected == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Red Sebebi: ${trade.receiverCancelDesc ?? trade.senderCancelDesc ?? 'Belirtilmedi'}",
                        style: AppTheme.safePoppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final tradeVM = context.read<TradeViewModel>();
    final userId = authVM.user?.userID;

    // 1. Status Mesajı ve Helper
    final statuses = tradeVM.tradeStatuses;
    int? getStatusId(String title) {
      if (statuses.isEmpty) return null;
      try {
        return statuses
            .firstWhere(
              (s) => (s.statusTitle?.toLowerCase() ?? '').contains(title),
            )
            .statusID;
      } catch (_) {
        return null;
      }
    }

    Widget? statusMessageWidget;
    if (trade.statusMessage != null && trade.statusMessage!.isNotEmpty) {
      statusMessageWidget = Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trade.statusMessage!,
                  style: AppTheme.safePoppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Backend'den gelen kesin buton gizleme kontrolü
    if (trade.showButtons == false) {
      return statusMessageWidget ?? const SizedBox.shrink();
    }

    // 2. Kullanıcı Rolü Belirleme
    final bool isMeSender =
        trade.senderUserID == userId || trade.isSender == true;
    final bool isMeReceiver =
        trade.receiverUserID == userId || trade.isReceiver == true;
    final int? myStatusId = isMeSender
        ? trade.senderStatusID
        : trade.receiverStatusID;

    final bool isPending =
        !trade.isTradeStart! &&
        !trade.isTradeConfirm! &&
        trade.isReceiverConfirm != true &&
        trade.isTradeRejected != true;

    // Eğer teklif bana gelmişse ve HENÜZ BAŞLAMAMIŞSA -> Onayla/Reddet göster
    if (isMeReceiver && isPending) {
      return Column(
        children: [
          if (statusMessageWidget != null) statusMessageWidget,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: tradeVM.isProcessing(trade.offerID!)
                      ? null
                      : () => _showRejectDialog(
                          context,
                          tradeVM,
                          authVM.user!.token,
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: tradeVM.isProcessing(trade.offerID!)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.error,
                          ),
                        )
                      : Text(
                          'Reddet',
                          style: AppTheme.safePoppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: tradeVM.isProcessing(trade.offerID!)
                      ? null
                      : () => _handleConfirm(
                          context,
                          tradeVM,
                          authVM.user!.token,
                          1,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: tradeVM.isProcessing(trade.offerID!)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Onayla',
                          style: AppTheme.safePoppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Eğer takas onaylanmışsa ve devam ediyorsa -> Takası Tamamla göster
    // Dinamik ID bulma
    final int completedId = getStatusId('tamam') ?? 4;
    final int cancelledId = getStatusId('iptal') ?? 6;
    final int rejectedId = getStatusId('red') ?? 7;
    final int approvedId =
        getStatusId('onay') ?? 2; // Takas Başlatıldı/Onaylandı

    final bool canComplete =
        myStatusId != completedId &&
        trade.senderStatusID != cancelledId &&
        trade.receiverStatusID != cancelledId &&
        trade.senderStatusID != rejectedId &&
        trade.receiverStatusID != rejectedId &&
        trade.isTradeRejected != true &&
        (trade.isTradeConfirm == true ||
            trade.isTradeStart == true ||
            (trade.isSenderConfirm == true &&
                trade.isReceiverConfirm == true) ||
            (trade.senderStatusID == approvedId ||
                trade.receiverStatusID == approvedId));

    if (canComplete && trade.isTradeRejected != true) {
      return Column(
        children: [
          if (statusMessageWidget != null) statusMessageWidget,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tradeVM.isProcessing(trade.offerID!)
                  ? null
                  : () => _handleComplete(context, tradeVM, authVM.user!.token),
              icon: tradeVM.isProcessing(trade.offerID!)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: const Text("Takası Tamamla"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 4. Değerlendirme Butonu (Tamamlanmış Takaslar için)
    final bool needsReview =
        (isMeSender && trade.isSenderReview != true) ||
        (isMeReceiver && trade.isReceiverReview != true);

    if (myStatusId == completedId && needsReview) {
      return Column(
        children: [
          if (statusMessageWidget != null) statusMessageWidget,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showReviewDialog(context, tradeVM, authVM.user!.token),
              icon: const Icon(Icons.star_outline, size: 20),
              label: const Text("Takas Deneyimini Değerlendir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return statusMessageWidget ?? const SizedBox.shrink();
  }

  void _showReviewDialog(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
  ) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Takası Değerlendir"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Takas deneyiminizi 1 ile 5 arasında puanlayın.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () =>
                          setState(() => selectedRating = index + 1),
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Yorumunuz (Opsiyonel)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: tradeVM.isLoading
                  ? null
                  : () async {
                      try {
                        final message = await tradeVM.addTradeReview(
                          userToken: token,
                          offerID: trade.offerID!,
                          rating: selectedRating,
                          comment: commentController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                message ?? "Değerlendirme gönderildi",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          final authVM = context.read<AuthViewModel>();
                          tradeVM.getTrades(authVM.user!.userID, silent: true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Hata: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: tradeVM.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Gönder", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleComplete(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
  ) async {
    tradeVM.clearError();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Takası Tamamla"),
        content: const Text(
          "Ürünlerin karşılıklı teslim alındığını ve takasın başarıyla sonuçlandığını onaylıyor musunuz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Tamamla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final message = await tradeVM.completeTrade(token, trade.offerID!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? "Takas tamamlandı"),
              backgroundColor: Colors.green,
            ),
          );
          final authVM = context.read<AuthViewModel>();
          tradeVM.getTrades(authVM.user!.userID, silent: true);
        }
      } catch (e) {
        if (context.mounted) {
          final errorStr = e.toString();
          // Check for 417 or specific message
          if (errorStr.contains('417') ||
              errorStr.toLowerCase().contains('zaten işlenmiş') ||
              errorStr.toLowerCase().contains('already processed')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Bu işlem zaten gerçekleştirilmiş. Liste güncelleniyor.",
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
            );
          }
          final authVM = context.read<AuthViewModel>();
          tradeVM.getTrades(authVM.user!.userID, silent: true);
          tradeVM.fetchTradeStatuses();
        }
      }
    }
  }

  void _handleConfirm(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
    int isConfirm, {
    String? reason,
  }) async {
    tradeVM.clearError();
    try {
      final request = ConfirmTradeRequestModel(
        userToken: token,
        offerID: trade.offerID!,
        isConfirm: isConfirm,
        cancelDesc: reason,
      );

      final message = await tradeVM.confirmTrade(request);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? "İşlem başarılı"),
            backgroundColor: isConfirm == 1 ? Colors.green : Colors.orange,
          ),
        );
        // Listeyi yenile
        final authVM = context.read<AuthViewModel>();
        tradeVM.getTrades(authVM.user!.userID, silent: true);
      }
    } catch (e) {
      if (context.mounted) {
        final errorStr = e.toString();
        // Check for 417 or specific message
        if (errorStr.contains('417') ||
            errorStr.toLowerCase().contains('zaten işlenmiş') ||
            errorStr.toLowerCase().contains('already processed')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Bu takas teklifi zaten onaylanmış veya işlenmiş. Liste güncelleniyor.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
          );
        }
        final authVM = context.read<AuthViewModel>();
        tradeVM.getTrades(authVM.user!.userID, silent: true);
        tradeVM.fetchTradeStatuses();
      }
    }
  }

  void _showRejectDialog(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Teklifi Reddet"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Reddetme sebebinizi yazın (Zorunlu)",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Lütfen sebep belirtin")),
                );
                return;
              }
              Navigator.pop(ctx);
              _handleConfirm(
                context,
                tradeVM,
                token,
                0,
                reason: controller.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text("Reddet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSide(Product? product, String label) {
    return Column(
      crossAxisAlignment: label == 'Sizin'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTheme.safePoppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: product?.productImage != null
                ? DecorationImage(
                    image: NetworkImage(product!.productImage!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: const Color(0xFFF8FAFC),
          ),
          child: product?.productImage == null
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFFCBD5E1),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          product?.productTitle ?? 'Ürün Yok',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.safePoppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.primary;
    Color bgColor = AppTheme.primary.withOpacity(0.1);

    final lower = status.toLowerCase();
    if (lower.contains('bekle')) {
      color = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.1);
    } else if (lower.contains('red') || lower.contains('iptal')) {
      color = AppTheme.error;
      bgColor = AppTheme.error.withOpacity(0.1);
    } else if (lower.contains('tamam')) {
      color = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: AppTheme.safePoppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
