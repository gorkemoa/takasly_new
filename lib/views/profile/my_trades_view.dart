import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/trade_model.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trade.theirProduct?.productTitle ?? 'Ürün',
                  style: AppTheme.safePoppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trade.senderStatusTitle ?? 'Durum',
                  style: AppTheme.safePoppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (trade.myProduct?.productImage != null)
                _buildProductImage(trade.myProduct!.productImage!),
              if (trade.myProduct?.productImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz, color: AppTheme.textSecondary),
                ),
              if (trade.theirProduct?.productImage != null)
                _buildProductImage(trade.theirProduct!.productImage!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trade.deliveryType ?? '',
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                trade.createdAt ?? '',
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String url) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}
