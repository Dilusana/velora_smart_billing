import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../core/theme/app_theme.dart';

class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final Map<String, List<Map<String, String>>> _faqs = {
    'Getting Started': [
      {'q': 'How do I add a new product?', 'a': 'Go to the Products page and click "Add Product".'},
      {'q': 'How to reset my password?', 'a': 'Click "Forgot Password" on the login screen.'},
      {'q': 'How to change theme?', 'a': 'Toggle the theme switch in the app bar.'},
    ],
    'Orders & Payments': [
      {'q': 'How to process a refund?', 'a': 'Go to Orders, select the order, and click "Refund".'},
      {'q': 'What payment methods are supported?', 'a': 'Cash, Card, and UPI.'},
      {'q': 'How to apply discount?', 'a': 'Enter discount code during checkout.'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: DefaultTabController(
                      length: _faqs.keys.length,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            labelColor: AppColors.primary,
                            tabs: _faqs.keys.map((k) => Tab(text: k)).toList(),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              children: _faqs.values.map((list) {
                                return ListView.builder(
                                  itemCount: list.length,
                                  itemBuilder: (context, i) {
                                    return ExpansionTile(
                                      leading: const Icon(Icons.help_outline),
                                      title: Text(list[i]['q']!),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(list[i]['a']!),
                                        )
                                      ],
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Contact Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'subject',
                            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'message',
                            maxLines: 4,
                            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(50)),
                            onPressed: () {
                              toastification.show(
                                context: context,
                                title: const Text('Success'),
                                description: const Text('Ticket submitted successfully.'),
                                type: ToastificationType.success,
                              );
                            },
                            child: const Text('Submit Ticket', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
