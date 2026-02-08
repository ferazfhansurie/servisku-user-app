import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/bookings_provider.dart';
import '../../../core/models/models.dart';

class BidsScreen extends ConsumerWidget {
  final String bookingId;
  
  const BidsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(bookingBidsProvider(bookingId));
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Bids'),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Booking Summary
          bookingAsync.when(
            data: (booking) {
              if (booking == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.description ?? 'Service Request',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.bookingNumber,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compare bids and choose the contractor that best fits your needs',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          // Bids List
          Expanded(
            child: bidsAsync.when(
              data: (bids) {
                if (bids.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Waiting for bids...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nearby contractors are reviewing your request',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(bookingBidsProvider(bookingId).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      return _BidCard(
                        bid: bids[index],
                        onAccept: () => _acceptBid(context, ref, bids[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptBid(BuildContext context, WidgetRef ref, BookingBid bid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accept bid from ${bid.contractor?.businessName ?? 'this contractor'}?'),
            const SizedBox(height: 12),
            Text(
              'RM ${bid.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (bid.etaMinutes != null) ...[
              const SizedBox(height: 8),
              Text('Estimated arrival: ${bid.etaMinutes} minutes'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await ref.read(bookingActionsProvider.notifier).acceptBid(
        bookingId,
        bid.id,
      );
      
      if (success && context.mounted) {
        context.go('/bookings/$bookingId');
      }
    }
  }
}

class _BidCard extends StatelessWidget {
  final BookingBid bid;
  final VoidCallback onAccept;
  
  const _BidCard({required this.bid, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final contractor = bid.contractor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contractor Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    (contractor?.businessName ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contractor?.businessName ?? 'Contractor',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (contractor?.verificationStatus == 'verified')
                            const Icon(Icons.verified, size: 18, color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${contractor?.avgRating.toStringAsFixed(1) ?? '0.0'} (${contractor?.totalReviews ?? 0})',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${contractor?.totalJobsCompleted ?? 0} jobs',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Bid Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quoted Price', style: TextStyle(color: Colors.grey)),
                    Text(
                      'RM ${bid.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (bid.etaMinutes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('ETA', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${bid.etaMinutes} min',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            if (bid.message != null && bid.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bid.message!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Accept Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAccept,
                child: const Text('Accept Bid'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
