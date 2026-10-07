import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mobile_shop_management_system/features/products/data/imei_provider.dart';
import 'package:mobile_shop_management_system/features/products/data/product_imei.dart';

/// Admin tool: look up a single IMEI to see which product it belongs to
/// and, if sold, when and to which sale — useful for warranty/support
/// questions ("is this phone one of ours, and when did we sell it?").
class ImeiLookupSection extends ConsumerStatefulWidget {
  const ImeiLookupSection({super.key});

  @override
  ConsumerState<ImeiLookupSection> createState() => _ImeiLookupSectionState();
}

class _ImeiLookupSectionState extends ConsumerState<ImeiLookupSection> {
  final _controller = TextEditingController();
  ImeiLookupResult? _result;
  bool _searched = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = false;
    });

    final repo = ref.read(imeiRepositoryProvider);
    final result = await repo.lookup(value);

    if (!mounted) return;
    setState(() {
      _result = result;
      _searched = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('IMEI Lookup', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Scan or enter an IMEI to see which product it is and its sale history.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.qr_code_scanner),
                      hintText: 'Scan or type IMEI',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: const Text('Look Up'),
                ),
              ],
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ] else if (_searched) ...[
              const SizedBox(height: 16),
              if (_result == null)
                const Text('No product found with that IMEI.', style: TextStyle(color: Colors.red))
              else
                _buildResult(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ImeiLookupResult result) {
    final isSold = !result.imei.isInStock;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isSold ? Colors.orange : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSold ? Colors.orange : Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('IMEI: ${result.imei.imei}'),
          const SizedBox(height: 4),
          if (isSold) ...[
            Text('Status: Sold (Sale #${result.imei.saleId})'),
            if (result.soldAt != null)
              Text('Sold on: ${DateFormat.yMd().add_jm().format(result.soldAt!)}'),
            if (result.soldByUsername != null) Text('Sold by: ${result.soldByUsername}'),
          ] else
            const Text('Status: In stock (not yet sold)'),
        ],
      ),
    );
  }
}
