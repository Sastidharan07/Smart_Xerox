import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _order;
  bool _loading = true;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fetchOrder();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  Future<void> _fetchOrder() async {
    try {
      final data = await ApiService().getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
          _loading = false;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2196F3),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_order == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF2196F3),
        body: Center(
          child: Text("Order not found",
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }

    final status = _order!['status'] ?? '';
    final statusColor = status == "Ready"
        ? Colors.greenAccent
        : status == "Delivered"
            ? Colors.grey
            : Colors.orangeAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
            child: _buildGlassCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 90, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      "Order #${_order!['id']}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _section("📁 File Details", [
                _info("File Name",
                    (_order!['filePath'] as String?)?.split(',').join('\n') ??
                        'N/A'),
              ]),
              const SizedBox(height: 18),
              _section("🖨️ Print Settings", [
                _info("Pages", _order!['pages'].toString()),
                _info("Copies", _order!['copies'].toString()),
                _info("Type", _order!['print_type'] ?? ''),
                _info("Sides", _order!['sides'] ?? ''),
              ]),
              const SizedBox(height: 18),
              _section("📦 Order Info", [
                _info("Assigned Bin", _order!['bin'] ?? '',
                    valueColor: Colors.cyanAccent),
                _info("Status", _order!['status'] ?? '',
                    valueColor: _statusColor(_order!['status'] ?? '')),
                _info("Payment", _order!['payment_method'] ?? ''),
                _info("Collect at", _order!['lunch_time'] ?? ''),
              ]),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF3A7BD5)),
                  label: const Text(
                    "Back to My Orders",
                    style: TextStyle(
                        color: Color(0xFF3A7BD5),
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _info(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "ready":
        return Colors.greenAccent;
      case "delivered":
        return Colors.grey;
      default:
        return Colors.orangeAccent;
    }
  }
}
