import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/trade_model.dart';
import '../../models/products/product_models.dart';
import 'trade_detail_view.dart';

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
      if (authVM.user != null) {
        final tradeVM = context.read<TradeViewModel>();
        if (tradeVM.trades.isEmpty && !tradeVM.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            tradeVM.getTrades(authVM.user!.userID);
          });
        }
      }
    }
  }

  bool _isOngoing(Trade trade) {
    final status = (trade.senderStatusTitle ?? '').toLowerCase();
    return !status.contains('tamam') &&
        !status.contains('red') &&
        !status.contains('iptal');
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
          if (viewModel.isLoading) {
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
    );
  }

  Widget _buildTradeList(List<Trade> trades, String emptyMessage) {
    if (trades.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: trades.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final trade = trades[index];
        return _TradeItemCard(trade: trade);
      },
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
                _buildStatusBadge(trade.senderStatusTitle ?? 'Beklemede'),
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
          ],
        ),
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
