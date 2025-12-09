import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order.dart';
import 'order_details_page.dart';
import 'upload_order_page.dart';
import 'profile_page.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  final int studentId;
  final String studentName;

  const HomePage({super.key, required this.studentId, required this.studentName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _loading = true;
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final ordersData = await ApiService().getStudentOrders(widget.studentName);
      final orders = (ordersData as List<dynamic>)
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching orders: $e")),
        );
      }
    }
  }

  void _goToUpload() async {
    final newOrder = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadOrderPage(studentName: widget.studentName),
      ),
    );

    if (newOrder != null && newOrder is Order) {
      setState(() {
        _orders.insert(0, newOrder);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF74ABE2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74ABE2), Color(0xFF5563DE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back 👋",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(studentId: widget.studentId),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _orders.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: const Icon(Icons.cloud_upload,
                                    size: 100, color: Colors.white),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No orders yet!",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Upload your first file to get started.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) =>
                                _buildOrderCard(_orders[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          icon: const Icon(Icons.add, color: Color(0xFF5563DE)),
          label: const Text(
            "New Order",
            style: TextStyle(
              color: Color(0xFF5563DE),
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _goToUpload,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                ),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 30),
            ),
            title: Text(
              order.fileNames.join(', '),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                _infoText("Order ID", order.orderId.toString()),
                _infoText("Status", order.status),
                _infoText("Copies", order.copies.toString()),
                _infoText("Payment", order.paymentMethod),
                _infoText("Collect at", order.lunchTime),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsPage(orderId: order.orderId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}
