import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  final int studentId;
  const ProfilePage({super.key, required this.studentId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fetchProfile();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiService().getStudentProfile(widget.studentId);
      if (mounted) {
        setState(() {
          _profile = data;
          _loading = false;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error fetching profile: $e")));
      }
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
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
        backgroundColor: Color(0xFF3A7BD5),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final name = _profile?['name']?.toString() ?? 'N/A';
    final department = _profile?['department']?.toString() ?? 'N/A';
    final year = _profile?['year']?.toString() ?? 'N/A';
    final rollno = _profile?['rollno']?.toString() ?? 'N/A';
    final email = _profile?['email']?.toString() ?? 'N/A';

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative wave
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: screenHeight * 0.18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Main profile content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.07,
                  vertical: screenHeight * 0.03,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.7,
                    maxWidth: 600, // limit width on big tablets
                  ),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Avatar glow
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.person,
                                        size: 65, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "$department • $year",
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Roll No: $rollno",
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.white70),
                                ),
                                const SizedBox(height: 25),
                                const Divider(
                                    color: Colors.white54, thickness: 1),
                                const SizedBox(height: 15),
                                _infoRow("👤 Name", name),
                                _infoRow("🏫 Department", department),
                                _infoRow("📅 Year", year),
                                _infoRow("🆔 Roll No", rollno),
                                _infoRow("✉️ Email", email),
                                const SizedBox(height: 30),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGradientButton(
                                        label: "Back",
                                        icon: Icons.arrow_back_ios_new,
                                        gradientColors: const [
                                          Color(0xFFFFFFFF),
                                          Color(0xFFE6E6E6)
                                        ],
                                        textColor: const Color(0xFF3A7BD5),
                                        onPressed: () =>
                                            Navigator.pop(context),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildGradientButton(
                                        label: "Logout",
                                        icon: Icons.logout,
                                        gradientColors: const [
                                          Color(0xFFFF416C),
                                          Color(0xFFFF4B2B),
                                        ],
                                        textColor: Colors.white,
                                        onPressed: _logout,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.03),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height * 0.7);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
