import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../models/trade_detail_model.dart';
import '../../models/trade_model.dart';
import 'user_profile_view.dart';

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

class _TradeDetailViewContentState extends State<_TradeDetailViewContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _topSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.8, curve: Curves.easeOutBack),
          ),
        );

    _bottomSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.8, curve: Curves.easeOutBack),
          ),
        );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutExpo),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Takas Detayı"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            );
          }
          if (model.errorMessage != null) {
            return _buildErrorState(model.errorMessage!);
          }
          if (model.currentTradeDetail == null) {
            return const Center(child: Text("Detay bulunamadı"));
          }
          final detail = model.currentTradeDetail!;

          if (!_hasAnimated) {
            _hasAnimated = true;
            _animationController.forward();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStatusBanner(detail),
                ),
                const SizedBox(height: 16),
                _buildSwapCard(detail),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInformationCard(detail),
                ),
                _buildActionButtons(context, detail),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(TradeDetailData detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sizin Durumunuz",
                style: AppTheme.safePoppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              _buildStatusBadge(detail.senderStatusTitle ?? "Beklemede"),
            ],
          ),
          if (detail.receiverStatusTitle != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Karşı Taraf",
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                _buildStatusBadge(detail.receiverStatusTitle!, isMe: false),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwapCard(TradeDetailData detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SlideTransition(
            position: _topSlideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUserProductRow(
                detail.sender,
                label: "Karşı Tarafın Ürünü",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFF1F5F9))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RotationTransition(
                    turns: _rotationAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFF1F5F9))),
              ],
            ),
          ),
          SlideTransition(
            position: _bottomSlideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUserProductRow(
                detail.receiver,
                label: "Sizin Ürününüz",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProductRow(TradeUser? user, {required String label}) {
    if (user == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: user.product?.productImage != null
                ? Image.network(
                    user.product!.productImage!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF8FAFC),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.safePoppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.product?.productTitle ?? "Ürün Belirtilmemiş",
                style: AppTheme.safePoppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (user.userID != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfileView(userId: user.userID!),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage:
                          (user.profilePhoto != null &&
                              user.profilePhoto!.isNotEmpty)
                          ? NetworkImage(user.profilePhoto!)
                          : null,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child:
                          (user.profilePhoto == null ||
                              user.profilePhoto!.isEmpty)
                          ? Text(
                              user.userName?.substring(0, 1).toUpperCase() ??
                                  "?",
                              style: const TextStyle(fontSize: 8),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.userName ?? "Bilinmeyen Kullanıcı",
                        style: AppTheme.safePoppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard(TradeDetailData detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Takas Bilgileri",
            style: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.local_shipping_outlined,
            "Teslimat Türü",
            detail.deliveryTypeTitle,
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            "Buluşma Yeri",
            detail.meetingLocation,
          ),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            "Oluşturulma",
            detail.createdAt?.split(' ').first,
          ),
          if (detail.completedAt != null && detail.completedAt!.isNotEmpty)
            _buildInfoRow(
              Icons.check_circle_outline_rounded,
              "Tamamlanma",
              detail.completedAt?.split(' ').first,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.safePoppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTheme.safePoppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool isMe = true}) {
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

  Widget _buildActionButtons(BuildContext context, TradeDetailData detail) {
    final authVM = context.read<AuthViewModel>();
    final tradeVM = context.read<TradeViewModel>();
    final userId = authVM.user?.userID;

    // 1. Backend'den gelen kesin buton gösterme kontrolü
    if (tradeVM.tradeCheckResult?['showButtons'] == false) {
      final String? statusMsg = tradeVM.tradeCheckResult?['message'];
      if (statusMsg != null && statusMsg.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusMsg,
                    style: AppTheme.safePoppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final bool isReceiver = detail.receiverUserID == userId;
    final bool isPending =
        detail.isReceiverConfirm != true && detail.isTradeRejected != true;

    // Eğer teklif bana gelmişse ve henüz onaylamamışsam -> Onayla/Reddet
    if (isReceiver && isPending) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: tradeVM.isLoading
                      ? null
                      : () => _showRejectDialog(
                          context,
                          tradeVM,
                          authVM.user!.token,
                          detail,
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: tradeVM.isLoading
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: tradeVM.isLoading
                      ? null
                      : () => _handleConfirm(
                          context,
                          tradeVM,
                          authVM.user!.token,
                          detail,
                          1,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                      : Text(
                          'Onayla',
                          style: AppTheme.safePoppins(
                            fontSize: 14,
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
    final bool canComplete =
        detail.isTradeConfirm == true ||
        detail.isTradeStart == true ||
        (detail.isSenderConfirm == true && detail.isReceiverConfirm == true) ||
        (detail.senderStatusID == 2 || detail.receiverStatusID == 2);

    if (canComplete && detail.isTradeRejected != true) {
      return Column(
        children: [
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tradeVM.isLoading
                  ? null
                  : () => _handleComplete(
                      context,
                      tradeVM,
                      authVM.user!.token,
                      detail,
                    ),
              icon: tradeVM.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 22),
              label: const Text("Takası Tamamla"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _handleComplete(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
    TradeDetailData detail,
  ) async {
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
        final message = await tradeVM.completeTrade(token, detail.offerID!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? "Takas tamamlandı"),
              backgroundColor: Colors.green,
            ),
          );
          tradeVM.getTradeDetail(detail.offerID!, token);
        }
      } catch (e) {
        if (context.mounted) {
          final errorStr = e.toString();
          if (errorStr.contains('zaten işlenmiş')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Bu işlem zaten gerçekleştirilmiş. Sayfa güncelleniyor.",
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
            );
          }
          tradeVM.getTradeDetail(detail.offerID!, token);
        }
      }
    }
  }

  void _handleConfirm(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
    TradeDetailData detail,
    int isConfirm, {
    String? reason,
  }) async {
    try {
      final request = ConfirmTradeRequestModel(
        userToken: token,
        offerID: detail.offerID!,
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
        // Yenile
        tradeVM.getTradeDetail(detail.offerID!, token);
      }
    } catch (e) {
      if (context.mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('zaten işlenmiş')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Bu takas teklifi zaten onaylanmış veya işlenmiş. Sayfa güncelleniyor.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
          );
        }
        tradeVM.getTradeDetail(detail.offerID!, token);
      }
    }
  }

  void _showRejectDialog(
    BuildContext context,
    TradeViewModel tradeVM,
    String token,
    TradeDetailData detail,
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
                detail,
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
