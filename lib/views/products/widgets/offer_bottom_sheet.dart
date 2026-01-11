import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product_detail_model.dart';
import '../../../models/profile/profile_detail_model.dart';
import '../../../viewmodels/profile_viewmodel.dart';
import '../../../viewmodels/ticket_viewmodel.dart';
import '../../messages/chat_view.dart';
import '../../widgets/product_card.dart';
import '../../../models/products/product_models.dart' as prod_models;
import '../../../models/tickets/ticket_model.dart';
import '../../../services/in_app_review_service.dart';

class OfferBottomSheet extends StatefulWidget {
  final ProductDetail targetProduct;
  final String userToken;
  final int myUserId;

  const OfferBottomSheet({
    super.key,
    required this.targetProduct,
    required this.userToken,
    required this.myUserId,
  });

  @override
  State<OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<OfferBottomSheet> {
  int? _selectedProductId;
  final TextEditingController _messageController = TextEditingController();

  final List<String> _quickMessages = [
    "Merhaba, ürününüzle ilgileniyorum.",
    "Takas düşünür müsünüz?",
    "Teklifim uygun mu?",
    "Detaylı bilgi alabilir miyim?",
    "Hangi konumdasınız?",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Product Card (Trade Summary)
                    _buildSectionTitle("İlgilendiğiniz Ürün"),
                    const SizedBox(height: 12),
                    _buildTargetProductCard(),

                    const SizedBox(height: 32),

                    // My Products Section
                    _buildSectionTitle("Takas İçin Ürününüzü Seçin"),
                    const SizedBox(height: 16),
                    _buildMyProductsList(),

                    const SizedBox(height: 32),

                    // Message Section
                    _buildSectionTitle("Mesajınız"),
                    const SizedBox(height: 16),
                    _buildQuickReplies(),
                    const SizedBox(height: 12),
                    _buildMessageInputField(),

                    const SizedBox(height: 40),

                    // Send Button
                    _buildSendButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Teklif Gönder',
                  textAlign: TextAlign.center,
                  style: AppTheme.safePoppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.safePoppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  prod_models.Product _mapToProduct(dynamic item) {
    if (item is ProfileProduct) {
      return prod_models.Product(
        productID: item.productID,
        productTitle: item.productTitle,
        productImage: item.productImage,
        productCondition: item.productCondition,
        cityTitle: item.cityTitle,
        districtTitle: item.districtTitle,
        categoryList: item.categoryList
            ?.map(
              (e) => prod_models.Category(catID: e.catID, catName: e.catName),
            )
            .toList(),
        isFavorite: item.isFavorite,
      );
    } else if (item is ProductDetail) {
      return prod_models.Product(
        productID: item.productID,
        productTitle: item.productTitle,
        productImage: item.productImage,
        productCondition: item.productCondition,
        cityTitle: item.cityTitle,
        districtTitle: item.districtTitle,
        categoryList: item.categoryList
            ?.map(
              (e) => prod_models.Category(catID: e.catID, catName: e.catName),
            )
            .toList(),
        isFavorite: item.isFavorite,
        userID: item.userID,
        userFullname: item.userFullname,
      );
    }
    return prod_models.Product();
  }

  Widget _buildTargetProductCard() {
    final product = _mapToProduct(widget.targetProduct);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.productImage != null
                ? Image.network(
                    product.productImage!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.categoryTitle ?? 'Kategori',
                  style: AppTheme.safePoppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.productTitle ?? '',
                  style: AppTheme.safePoppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}',
                      style: AppTheme.safePoppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProductsList() {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.state == ProfileState.busy) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (viewModel.state == ProfileState.error) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Ürünler yüklenemedi: ${viewModel.errorMessage}',
              style: TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          );
        }

        final products = viewModel.profileDetail?.products ?? [];
        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Takas teklif edecek aktif bir ürününüz bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final profileProduct = products[index];
              final product = _mapToProduct(profileProduct);
              final isSelected = _selectedProductId == product.productID;

              return Stack(
                children: [
                  SizedBox(
                    width: 150,
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        setState(() {
                          _selectedProductId = product.productID;
                        });
                      },
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.borderRadius,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                            color: AppTheme.primary.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  if (isSelected)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickMessages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => _messageController.text = _quickMessages[index],
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Text(
                _quickMessages[index],
                style: AppTheme.safePoppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInputField() {
    return TextField(
      controller: _messageController,
      maxLines: 4,
      style: AppTheme.safePoppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Satıcıya bir mesaj yazın...',
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Consumer<TicketViewModel>(
      builder: (context, ticketViewModel, child) {
        final bool canSend =
            _selectedProductId != null && !ticketViewModel.isSendingMessage;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canSend
                ? () async {
                    if (widget.targetProduct.productID == null) return;

                    final result = await ticketViewModel.createTicket(
                      widget.userToken,
                      widget.targetProduct.productID!,
                      _selectedProductId!,
                      _messageController.text.trim().isEmpty
                          ? "Merhaba, bu ilan için bir takas teklifim var."
                          : _messageController.text,
                    );

                    if (!context.mounted) return;

                    if (result != null) {
                      Navigator.pop(context);

                      final ticket = Ticket(
                        ticketID: result,
                        productID: widget.targetProduct.productID,
                        productTitle: widget.targetProduct.productTitle,
                        productImage: widget.targetProduct.productImage,
                        otherUserID: widget.targetProduct.userID,
                        otherFullname: widget.targetProduct.userFullname,
                        otherProfilePhoto: widget.targetProduct.profilePhoto,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatView(ticket: ticket),
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teklif başarıyla gönderildi'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      InAppReviewService().incrementActionAndCheck();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ticketViewModel.errorMessage ?? 'Hata oluştu',
                          ),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: ticketViewModel.isSendingMessage
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Teklifi Gönder',
                    style: AppTheme.safePoppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
