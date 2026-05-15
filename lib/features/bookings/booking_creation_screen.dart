import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import 'booking_detail_screen.dart';
import 'providers/booking_provider.dart';

class BookingCreationScreen extends StatefulWidget {
  const BookingCreationScreen({
    super.key,
    required this.request,
    required this.quote,
  });

  final ServiceRequest request;
  final Quote quote;

  @override
  State<BookingCreationScreen> createState() => _BookingCreationScreenState();
}

class _BookingCreationScreenState extends State<BookingCreationScreen> {
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.request.location;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() => _selectedTime = time);
  }

  DateTime? _buildScheduledAt() {
    if (_selectedDate == null || _selectedTime == null) return null;

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;

    if (_selectedDate == null || _selectedTime == null) {
      _showSnack('Please select date and time');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showSnack('Please enter address');
      return;
    }

    setState(() => _isSubmitting = true);

    final booking = await context.read<BookingProvider>().createBooking(
      serviceRequestId: widget.request.id,
      quoteId: widget.quote.id,
      scheduledAt: _buildScheduledAt(),
      address: _addressController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (booking == null) {
      _showSnack(
        context.read<BookingProvider>().errorMessage ??
            'Failed to create booking',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(bookingId: booking.id),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final quote = widget.quote;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          'Schedule Booking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Title('Job Summary'),

                  const SizedBox(height: 12),

                  _InfoRow('Title', request.title),
                  _InfoRow('Location', request.location),
                  _InfoRow('Provider', quote.providerName),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${quote.price.toStringAsFixed(2)} ETB',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Title('Schedule'),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _SelectButton(
                          icon: Icons.calendar_month,
                          label: _selectedDate == null
                              ? 'Pick Date'
                              : _formatDate(_selectedDate!),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SelectButton(
                          icon: Icons.schedule,
                          label: _selectedTime == null
                              ? 'Pick Time'
                              : _selectedTime!.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Title('Address'),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter service location',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

/* ---------------- UI COMPONENTS ---------------- */

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
