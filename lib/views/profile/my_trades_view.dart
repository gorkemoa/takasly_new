import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/trade_model.dart';
import '../../models/products/product_models.dart';

class MyTradesView extends StatelessWidget {
  final bool showBackButton;

  const MyTradesView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradeViewModel(),
      child: _MyTradesViewContent(showBackButton: showBackButton),
    );
  }
}

class _MyTradesViewContent extends StatefulWidget {
  final bool showBackButton;

  const _MyTradesViewContent({required this.showBackButton});

  @override
  State<_MyTradesViewContent> createState() => _MyTradesViewContentState();
}

class _MyTradesViewContentState extends State<_MyTradesViewContent> {
  bool _isInitDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitDone) return;

    final authVM = context.watch<AuthViewModel>();
    if (authVM.isAuthCheckComplete) {
      _isInitDone = true;
      if (authVM.user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TradeViewModel>().getTrades(authVM.user!.userID);
        });
      }
    }
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.background,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.background,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: AppTheme.safePoppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.error,
                ),
              ),
            );
          }

          if (viewModel.trades.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Takas Bulunamadı',
                    style: AppTheme.safePoppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Henüz herhangi bir takas işleminiz bulunmamaktadır.',
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

          return ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 150,
            ),
            itemCount: viewModel.trades.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final trade = viewModel.trades[index];
              return _TradeItem(trade: trade);
            },
          );
        },
      ),
    );
  }
}

class _TradeItem extends StatelessWidget {
  final Trade trade;

  const _TradeItem({required this.trade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          // Header: Status and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trade.createdAt?.split(' ').first ?? '',
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              _buildSimpleStatus(trade.senderStatusTitle ?? ''),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Row: My Product -> Arrow -> Their Product
          Row(
            children: [
              Expanded(child: _buildMiniProduct(trade.myProduct, true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppTheme.primary.withOpacity(0.5),
                ),
              ),
              Expanded(child: _buildMiniProduct(trade.theirProduct, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatus(String status) {
    Color color = AppTheme.primary;
    if (status.toLowerCase().contains('bekle')) color = Colors.orange;
    if (status.toLowerCase().contains('red') ||
        status.toLowerCase().contains('iptal'))
      color = Colors.red;
    if (status.toLowerCase().contains('tamam')) color = Colors.green;

    return Text(
      status,
      style: AppTheme.safePoppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildMiniProduct(Product? product, bool isMe) {
    if (product == null) return const SizedBox();
    return Row(
      children: [
        if (!isMe) ...[
          _buildImage(product.productImage),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? 'Siz' : 'Karşı Taraf',
                style: AppTheme.safePoppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                product.productTitle ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isMe ? TextAlign.end : TextAlign.start,
                style: AppTheme.safePoppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          _buildImage(product.productImage),
        ],
      ],
    );
  }

  Widget _buildImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url ?? '',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: 40,
          height: 40,
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.image_not_supported,
            size: 16,
            color: Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}
