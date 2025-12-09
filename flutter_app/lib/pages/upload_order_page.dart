import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class UploadOrderPage extends StatefulWidget {
  final String studentName;
  const UploadOrderPage({super.key, required this.studentName});

  @override
  State<UploadOrderPage> createState() => _UploadOrderPageState();
}

class _UploadOrderPageState extends State<UploadOrderPage>
    with TickerProviderStateMixin {
  final TextEditingController _pagesController = TextEditingController();
  final TextEditingController _copiesController = TextEditingController();

  String _printType = "B/W";
  String _sides = "Single";
  String _paymentMethod = "Cash";
  String _lunchTime = "12:00 PM - 12:30 PM";

  List<Map<String, dynamic>> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late AnimationController _fadeController;
  late AnimationController _pulseController;

  final List<String> lunchSlots = [
    "11:30 AM - 12:00 PM",
    "12:00 PM - 12:30 PM",
    "12:30 PM - 1:00 PM",
  ];

  final List<String> bins = ["Bin A", "Bin B", "Bin C"];
  int binIndex = 0;

  @override
  void initState() {
    super.initState();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<Map<String, dynamic>> pickedFiles = [];

      for (var platformFile in result.files) {
        if (platformFile.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("File too large: ${platformFile.name}")),
            );
          }
          return;
        }

        if (kIsWeb) {
          pickedFiles.add({
            'bytes': platformFile.bytes,
            'name': platformFile.name,
            'size': platformFile.size,
          });
        } else {
          pickedFiles.add({
            'file': File(platformFile.path!),
            'name': platformFile.name,
            'size': platformFile.size,
          });
        }
      }

      setState(() {
        _selectedFiles = pickedFiles;
      });
    }
  }

  void _submitOrder() async {
    if (_selectedFiles.isEmpty ||
        _pagesController.text.isEmpty ||
        _copiesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields & select files")),
      );
      return;
    }

    int pages = int.tryParse(_pagesController.text) ?? 0;
    int copies = int.tryParse(_copiesController.text) ?? 0;

    int amount = pages * copies * (_printType == 'Color' ? 2 : 1);
    String assignedBin = bins[binIndex];
    binIndex = (binIndex + 1) % bins.length;

    final newOrder = {
      'studentName': widget.studentName,
      'paymentMethod': _paymentMethod.toLowerCase(),
      'amount': amount.toString(),
      'bin': assignedBin,
      'lunchTime': _lunchTime,
      'pages': pages.toString(),
      'copies': copies.toString(),
      'printType': _printType,
      'sides': _sides,
    };

    // Dummy online payment simulation
    if (_paymentMethod == "Online") {
      bool paymentSuccess = await _showDummyPaymentDialog(amount);
      if (!paymentSuccess) {
        return; // Payment failed, do not proceed
      }
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final response = await ApiService().createOrder(
        newOrder,
        _selectedFiles,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      final order = Order.fromJson(response);

      if (mounted) {
        Navigator.pop(context, order);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<bool> _showDummyPaymentDialog(int amount) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dummy Online Payment"),
          content: Text(
            "Simulate payment of ₹$amount for the order.\n\nChoose an option to proceed:",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Simulate Failure"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Simulate Success"),
            ),
          ],
        );
      },
    ) ?? false;
  }



  // 🌈 UI Section
  @override
  Widget build(BuildContext context) {
    final pulse = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74ABE2), Color(0xFF5563DE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeController,
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      ScaleTransition(
                        scale: pulse,
                        child: const Text(
                          "Upload Your Order",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.white70,
                                blurRadius: 15,
                                offset: Offset(0, 0),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // File Picker Section
                      _glassyContainer(
                        child: Column(
                          children: [
                            _selectedFiles.isEmpty
                                ? GestureDetector(
                                    onTap: _pickFile,
                                    child: ScaleTransition(
                                      scale: pulse,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(45),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.5)),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.cloud_upload,
                                                size: 50, color: Colors.white),
                                            SizedBox(height: 12),
                                            Text("Tap to Select Files",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            Text(
                                                "(PDF, DOCX, TXT up to 10MB each)",
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _selectedFiles.map((file) {
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.25)),
                                          color:
                                              Colors.white.withOpacity(0.15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.white),
                                          title: Text(
                                            file['name'] as String,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            "${((file['size'] as int) / 1024).toStringAsFixed(1)} KB",
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.redAccent),
                                            onPressed: () {
                                              setState(() {
                                                _selectedFiles.remove(file);
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            const SizedBox(height: 16),
                            if (_isUploading)
                              Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _uploadProgress,
                                    backgroundColor: Colors.white24,
                                    color: Colors.greenAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Uploading... ${(100 * _uploadProgress).toStringAsFixed(0)}%",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),

                            // Fields
                            _buildTextField("Pages", _pagesController),
                            _buildTextField("Copies", _copiesController),
                            _buildDropdown("Print Type", ["B/W", "Color"],
                                _printType, (val) => setState(() => _printType = val!)),
                            _buildDropdown("Sides", ["Single", "Double"], _sides,
                                (val) => setState(() => _sides = val!)),
                            _buildDropdown("Lunch Time", lunchSlots, _lunchTime,
                                (val) => setState(() => _lunchTime = val!)),
                            _buildDropdown(
                                "Payment Method", ["Cash", "Online"], _paymentMethod,
                                (val) => setState(() => _paymentMethod = val!)),

                            const SizedBox(height: 30),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Glassy back button
                Positioned(
                  top: 10,
                  left: 10,
                  child: _backButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _glassyContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white70),
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white38)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selected,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: selected,
        dropdownColor: const Color(0xFF1A237E),
        iconEnabledColor: Colors.white,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white))))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              _isUploading ? "Uploading..." : "Submit Order",
              style: const TextStyle(
                  fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
