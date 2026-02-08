import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

// Helper function to safely parse doubles
double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

final addressesProvider = FutureProvider<List<UserAddress>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/users/addresses');
  return (response.data['data'] as List)
      .map((e) => UserAddress.fromJson(e))
      .toList();
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved addresses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add addresses for faster booking',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              return _AddressCard(
                address: addresses[index],
                onEdit: () => _showAddressSheet(context, ref, addresses[index]),
                onDelete: () => _deleteAddress(context, ref, addresses[index]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddressSheet(BuildContext context, WidgetRef ref, UserAddress? address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddressForm(
        address: address,
        onSave: (data) async {
          final api = ref.read(apiClientProvider);
          if (address != null) {
            await api.put('/users/addresses/${address.id}', data: data);
          } else {
            await api.post('/users/addresses', data: data);
          }
          ref.invalidate(addressesProvider);
        },
      ),
    );
  }

  Future<void> _deleteAddress(BuildContext context, WidgetRef ref, UserAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Delete "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      await api.delete('/users/addresses/${address.id}');
      ref.invalidate(addressesProvider);
    }
  }
}

class _AddressCard extends StatelessWidget {
  final UserAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(address.label),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullAddress,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home') || lower.contains('rumah')) return Icons.home;
    if (lower.contains('office') || lower.contains('pejabat')) return Icons.business;
    return Icons.location_on;
  }
}

class _AddressForm extends StatefulWidget {
  final UserAddress? address;
  final Future<void> Function(Map<String, dynamic>) onSave;
  
  const _AddressForm({this.address, required this.onSave});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _unitController;
  late TextEditingController _postalController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _addressController = TextEditingController(text: widget.address?.addressLine1 ?? '');
    _unitController = TextEditingController(text: widget.address?.addressLine2 ?? '');
    _postalController = TextEditingController(text: widget.address?.postalCode ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _unitController.dispose();
    _postalController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.address != null ? 'Edit Address' : 'Add Address',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Quick Labels
              Wrap(
                spacing: 8,
                children: ['Home', 'Office', 'Other'].map((label) {
                  final isSelected = _labelController.text == label;
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _labelController.text = selected ? label : '');
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g., Home, Office',
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Street name and number',
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit/Floor (Optional)',
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalController,
                      decoration: const InputDecoration(labelText: 'Postal Code'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Set as default'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSave({
        'label': _labelController.text.trim(),
        'address_line_1': _addressController.text.trim(),
        'address_line_2': _unitController.text.trim(),
        'postal_code': _postalController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': 'Malaysia',
        'is_default': _isDefault,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class UserAddress {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String? postalCode;
  final String city;
  final String state;
  final String country;
  final double? lat;
  final double? lng;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    this.postalCode,
    required this.city,
    required this.state,
    required this.country,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'],
      label: json['label'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      postalCode: json['postal_code'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? 'Malaysia',
      lat: _parseDoubleNullable(json['lat']),
      lng: _parseDoubleNullable(json['lng']),
      isDefault: json['is_default'] ?? false,
    );
  }

  String get fullAddress {
    final parts = <String>[];
    parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    parts.add('$postalCode $city');
    parts.add('$state, $country');
    return parts.join(', ');
  }
}
