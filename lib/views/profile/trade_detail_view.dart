import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../models/trade_detail_model.dart';
import '../widgets/product_card.dart';

class TradeDetailView extends StatelessWidget {
  final int offerId;

  const TradeDetailView({Key? key, required this.offerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradeViewModel(),
      child: _TradeDetailViewContent(offerId: offerId),
    );
  }
}

class _TradeDetailViewContent extends StatefulWidget {
  final int offerId;

  const _TradeDetailViewContent({Key? key, required this.offerId})
    : super(key: key);

  @override
  _TradeDetailViewContentState createState() => _TradeDetailViewContentState();
}

class _TradeDetailViewContentState extends State<_TradeDetailViewContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final tradeViewModel = Provider.of<TradeViewModel>(
        context,
        listen: false,
      );
      if (authViewModel.user?.token != null) {
        tradeViewModel.getTradeDetail(
          widget.offerId,
          authViewModel.user!.token,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Takas Detayı"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTheme.safePoppins(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (model.errorMessage != null) {
            return Center(
              child: Text(
                model.errorMessage!,
                style: AppTheme.safePoppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            );
          }
          if (model.currentTradeDetail == null) {
            return const Center(child: Text("Detay bulunamadı"));
          }
          final detail = model.currentTradeDetail!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(detail),
                const SizedBox(height: 24),
                _buildUserSection("Gönderen", detail.sender),
                const SizedBox(height: 24),
                _buildUserSection("Alıcı", detail.receiver),
                const SizedBox(height: 24),
                _buildDetailRow("Teslimat Türü", detail.deliveryTypeTitle),
                _buildDetailRow("Buluşma Yeri", detail.meetingLocation),
                _buildDetailRow("Oluşturulma Tarihi", detail.createdAt),
                if (detail.completedAt != null &&
                    detail.completedAt!.isNotEmpty)
                  _buildDetailRow("Tamamlanma Tarihi", detail.completedAt),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(TradeDetailData detail) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Teklif Durumu",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  detail.senderStatusTitle ?? "",
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (detail.receiverStatusTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Karşı Taraf",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      detail.receiverStatusTitle!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(String title, TradeUser? user) {
    if (user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.safePoppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        (user.profilePhoto != null &&
                            user.profilePhoto!.isNotEmpty)
                        ? NetworkImage(user.profilePhoto!)
                        : null,
                    child:
                        (user.profilePhoto == null ||
                            user.profilePhoto!.isEmpty)
                        ? Text(
                            user.userName?.substring(0, 1).toUpperCase() ?? "?",
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    user.userName ?? "Bilinmeyen Kullanıcı",
                    style: AppTheme.safePoppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (user.product != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SizedBox(
                    height: 280,
                    width: 180,
                    child: ProductCard(product: user.product!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
