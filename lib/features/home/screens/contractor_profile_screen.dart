import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/services_provider.dart';
import '../../../core/models/models.dart';

class ContractorProfileScreen extends ConsumerWidget {
  final String contractorId;
  
  const ContractorProfileScreen({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractorAsync = ref.watch(contractorProfileProvider(contractorId));
    final reviewsAsync = ref.watch(contractorReviewsProvider(contractorId));

    return contractorAsync.when(
      data: (contractor) {
        if (contractor == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Contractor not found')),
          );
        }
        
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Profile Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              (contractor.businessName ?? 'C')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            contractor.businessName ?? 'Contractor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (contractor.isOnline)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Online',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              if (contractor.verificationStatus == 'verified') ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                const Text(
                                  'Verified',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Stats Row
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        icon: Icons.star,
                        value: contractor.avgRating.toStringAsFixed(1),
                        label: 'Rating',
                        color: Colors.amber,
                      ),
                      _StatItem(
                        icon: Icons.rate_review,
                        value: '${contractor.totalReviews}',
                        label: 'Reviews',
                        color: Colors.blue,
                      ),
                      _StatItem(
                        icon: Icons.check_circle,
                        value: '${contractor.totalJobsCompleted}',
                        label: 'Jobs Done',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Description
              if (contractor.description != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(contractor.description!),
                      ],
                    ),
                  ),
                ),
              
              // Services
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = contractor.services[index];
                    return _ServiceTile(
                      service: service,
                      contractorId: contractorId,
                    );
                  },
                  childCount: contractor.services.length,
                ),
              ),
              
              // Reviews
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              
              reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No reviews yet'),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ReviewTile(review: reviews[index]),
                      childCount: reviews.length > 5 ? 5 : reviews.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Text('Error loading reviews: $e'),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ContractorService service;
  final String contractorId;
  
  const _ServiceTile({required this.service, required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(service.title),
        subtitle: Text(service.description ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM ${service.basePrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              service.priceType == 'hourly' ? '/hour' : 'fixed',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        onTap: () {
          context.go('/booking/new?serviceId=${service.id}&contractorId=$contractorId');
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  (review.user?.fullName ?? 'U')[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user?.fullName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }
}
