import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../models/shop_model.dart';
import '../../../models/product_model.dart';

void showWhatsAppInquirySheet(
  BuildContext context, {
  required ShopModel shop,
  ProductModel? product,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _WhatsAppInquiryBottomSheet(
      shop: shop,
      product: product,
    ),
  );
}

class _WhatsAppInquiryBottomSheet extends StatelessWidget {
  final ShopModel shop;
  final ProductModel? product;

  const _WhatsAppInquiryBottomSheet({
    required this.shop,
    this.product,
  });

  final List<String> _quickQueries = const [
    'Is this product available?',
    'What is the best price?',
    'Do you offer bulk discounts?',
    'Is home delivery available?',
    'Is stock available?',
    'Can you share more product details?',
    'Other query',
  ];

  Future<void> _launchWhatsApp(BuildContext context, String query) async {
    Navigator.pop(context); // Close sheet

    if (shop.whatsapp.isEmpty || !shop.isWhatsappEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop contact is currently unavailable.')),
      );
      return;
    }

    final price = product != null 
      ? (product!.discountPrice != null
          ? product!.discountPrice!.toStringAsFixed(0)
          : product!.price.toStringAsFixed(0))
      : '';

    String message = '''Hi,

I found this on Locaro.

Shop: ${shop.shopName}''';

    if (product != null) {
      message += '''\nProduct: ${product!.name}\nPrice: ₹$price''';
    }

    if (query != 'Other query') {
      message += '''

I would like to know:
• $query

Please let me know.
Thank you.''';
    } else {
      message += '''

I would like to know: 
''';
    }

    final text = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/${shop.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}?text=$text';

    if (await canLaunchUrlString(whatsappUrl)) {
      await launchUrlString(whatsappUrl);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed on this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick WhatsApp Inquiry',
                            style: AppTypography.heading.copyWith(fontSize: 18),
                          ),
                          Text(
                            'Select a question to ask ${shop.shopName}',
                            style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickQueries.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final query = _quickQueries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        query,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                      onTap: () => _launchWhatsApp(context, query),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
