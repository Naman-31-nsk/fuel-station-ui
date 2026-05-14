import 'dart:ui';
import 'package:fl_sdp/fl_sdp.dart';
import 'package:flutter/material.dart';

class StaticPumpScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const StaticPumpScreen({super.key, this.onBack});

  static final List<Map<String, String>> _pumps = [
    {
      'name': 'Naresh Trading Company',
      'brand': 'Indian Oil (COCO)',
      'distance': '> 4km',
      'isVerified': 'false',
    },
    {
      'name': 'Sharma Petroleum Service',
      'brand': 'Indian Oil (COCO)',
      'distance': '> 4km',
      'isVerified': 'false',
    },
    {
      'name': 'Ravi Fuel Station',
      'brand': 'Bharat Petroleum',
      'distance': '> 4km',
      'isVerified': 'false',
    },
    {
      'name': 'Singh Petroleum',
      'brand': 'Indian Oil (COCO)',
      'distance': '> 4km',
      'isVerified': 'true',
    },
    {
      'name': 'Gupta Service Station',
      'brand': 'Bharat Petroleum',
      'distance': '> 4km',
      'isVerified': 'false',
    },
    {
      'name': 'Kumar Fuel Point',
      'brand': 'Indian Oil (COCO)',
      'distance': '> 4km',
      'isVerified': 'false',
    },
    {
      'name': 'Verma Petroleum',
      'brand': 'Bharat Petroleum',
      'distance': '> 4km',
      'isVerified': 'true',
    },
    {
      'name': 'Patel Fuel Station',
      'brand': 'Indian Oil (COCO)',
      'distance': '> 4km',
      'isVerified': 'false',
    },
  ];

  // Figma shadows — shared by both card types
  static const List<BoxShadow> _cardShadows = [
    BoxShadow(
      color: Color.fromRGBO(50, 50, 71, 0.05), // #323247 5%
      offset: Offset(0, 2.65),
      blurRadius: 7.06,
      spreadRadius: -0.88,
    ),
    BoxShadow(
      color: Color.fromRGBO(12, 26, 75, 0.24), // #0C1A4B 24%
      offset: Offset(0, 0),
      blurRadius: 0.88,
      spreadRadius: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── Navbar background: #070707 ─────────────────────────────────────────
      backgroundColor: const Color(0xFF070707),
      body: Stack(
        children: [
          // ── Dark base ──────────────────────────────────────────────────────
          Positioned.fill(child: Container(color: const Color(0xFF070707))),

          // ── Background glow ────────────────────────────────────────────────
          Positioned(
            left: 23,
            top: -30,
            child: IgnorePointer(
              child: Container(
                width: 447,
                height: 440,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(220),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A1010).withOpacity(0.7),
                      blurRadius: 180,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER — bg: #070707 ───────────────────────────────────
                Container(
                  color: const Color(0xFF070707),
                  padding: EdgeInsets.symmetric(horizontal: SDP.sdp(16)),
                  child: SizedBox(
                    height: SDP.sdp(60),
                    child: Row(
                      children: [
                        // Back arrow — bg: #232728
                        GestureDetector(
                          onTap: () {
                            if (onBack != null) {
                              onBack!();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                          child: Container(
                            width: SDP.sdp(36),
                            height: SDP.sdp(36),
                            decoration: BoxDecoration(
                              // ── Arrow circle bg: #232728 ──────────────────
                              color: const Color(0xFF232728),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: SDP.sdp(18),
                              ),
                            ),
                          ),
                        ),

                        // Title
                        Expanded(
                          child: Center(
                            child: Text(
                              'Fuel station Near by',
                              style: TextStyle(
                                fontSize: SDP.sdp(18),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Lexend',
                              ),
                            ),
                          ),
                        ),

                        // Filter icon
                        Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: SDP.sdp(22),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cards list ─────────────────────────────────────────────
                // Figma: width 337.29, left 19, gap 9.71
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SDP.sdp(19)),
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        top: SDP.sdp(12),
                        bottom: SDP.sdp(30),
                      ),
                      itemCount: _pumps.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: SDP.sdp(9.71)),
                      itemBuilder: (context, index) {
                        final pump = _pumps[index];
                        final isVerified = pump['isVerified'] == 'true';
                        return isVerified
                            ? _VerifiedCard(pump: pump, shadows: _cardShadows)
                            : _StandardCard(pump: pump, shadows: _cardShadows);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STANDARD CARD
// Figma: width 309.05  height 70.64  bg #ABABAB solid  radius 8.83
// ─────────────────────────────────────────────────────────────────────────────
class _StandardCard extends StatelessWidget {
  final Map<String, String> pump;
  final List<BoxShadow> shadows;

  const _StandardCard({required this.pump, required this.shadows});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SDP.sdp(70.64),
      padding: EdgeInsets.symmetric(horizontal: SDP.sdp(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFABABAB), // Figma: #ABABAB solid
        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),
        boxShadow: shadows,
      ),
      child: _CardRow(pump: pump),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFIED CARD
// Top:    309.05 × 70.64  bg #ABABAB solid
// Banner: 309.05 × 52.10  gradient #FF7655→#FF0000  bottom-radius 8.83
// ─────────────────────────────────────────────────────────────────────────────
class _VerifiedCard extends StatelessWidget {
  final Map<String, String> pump;
  final List<BoxShadow> shadows;

  const _VerifiedCard({required this.pump, required this.shadows});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SDP.sdp(8.83)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SDP.sdp(8.83)),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top card section ───────────────────────────────────────────
            Container(
              height: SDP.sdp(70.64),
              padding: EdgeInsets.symmetric(horizontal: SDP.sdp(14)),
              decoration: const BoxDecoration(
                color: Color(0xFFABABAB), // Figma: #ABABAB solid
              ),
              child: _CardRow(pump: pump),
            ),

            // ── Red gradient banner ────────────────────────────────────────
            // Figma: height 52.10  131.68deg #FF7655→#FF0000  bottom-radius 8.83
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(SDP.sdp(8.83)),
                bottomRight: Radius.circular(SDP.sdp(8.83)),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: SDP.sdp(52.10),
                  padding: EdgeInsets.symmetric(horizontal: SDP.sdp(13.24)),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.63, -0.78),
                      end: Alignment(0.63, 0.78),
                      stops: [0.1688, 0.9348],
                      colors: [Color(0xFFFF7655), Color(0xFFFF0000)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label + tick
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Milopure Trusted Pump (Verified fuel )',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w400,
                                fontSize: SDP.sdp(12.36),
                                height: 1.0,
                                letterSpacing: 0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: SDP.sdp(4)),
                          // Tick badge: white circle 13.24 × 13.24
                          Container(
                            width: SDP.sdp(13.24),
                            height: SDP.sdp(13.24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(SDP.sdp(2.5)),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFFF3B30), // Figma tick color
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/Vector.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: SDP.sdp(4)),

                      // Subtitle
                      Text(
                        'Consistently safe based on Milopure data',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w300,
                          fontSize: SDP.sdp(8.83),
                          height: 1.0,
                          letterSpacing: 0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED ROW — inside every card
// Card is solid #ABABAB so text uses dark colors
// ─────────────────────────────────────────────────────────────────────────────
class _CardRow extends StatelessWidget {
  final Map<String, String> pump;

  const _CardRow({required this.pump});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Logo circle ───────────────────────────────────────────────────
        Container(
          width: SDP.sdp(38),
          height: SDP.sdp(38),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              pump['name']![0].toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF121212),
                fontWeight: FontWeight.w700,
                fontSize: SDP.sdp(14),
                fontFamily: 'Lexend',
              ),
            ),
          ),
        ),

        SizedBox(width: SDP.sdp(12)),

        // ── Name + brand + distance ───────────────────────────────────────
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pump['name']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: SDP.sdp(12.36),
                  color: const Color(0xFF121212),
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: SDP.sdp(4)),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      pump['brand']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w400,
                        fontSize: SDP.sdp(10.6),
                        height: 1.0,
                        letterSpacing: 0,
                        color: const Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                  SizedBox(width: SDP.sdp(4)),
                  Text(
                    '|',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: SDP.sdp(10.6),
                    ),
                  ),
                  SizedBox(width: SDP.sdp(4)),
                  Icon(
                    Icons.near_me,
                    size: SDP.sdp(10),
                    color: const Color(0xFF4A4A4A),
                  ),
                  SizedBox(width: SDP.sdp(2)),
                  Text(
                    pump['distance']!,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      fontSize: SDP.sdp(10.6),
                      height: 1.0,
                      letterSpacing: 0,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(width: SDP.sdp(8)),

        // ── Arrow button — bg: #232728 ────────────────────────────────────
        Container(
          width: SDP.sdp(26),
          height: SDP.sdp(26),
          decoration: const BoxDecoration(
            color: Color(0xFF232728), // Figma: #232728
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.arrow_forward_rounded,
              size: SDP.sdp(12),
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
