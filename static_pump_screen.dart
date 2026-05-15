import 'dart:ui';
import 'package:fl_sdp/fl_sdp.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

final List<Map<String, String>> _pumps = [
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
    'isVerified': 'true',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────────────────────────

const List<BoxShadow> _cardShadows = [
  BoxShadow(
    color: Color.fromRGBO(50, 50, 71, 0.05),
    offset: Offset(0, 2.65),
    blurRadius: 7.06,
    spreadRadius: -0.88,
  ),
  BoxShadow(
    color: Color.fromRGBO(12, 26, 75, 0.24),
    offset: Offset(0, 0),
    blurRadius: 0.88,
    spreadRadius: 0,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class StaticPumpScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const StaticPumpScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),

      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(child: Container(color: const Color(0xFF070707))),

          // RED GLOW
          Positioned(
            left: 23,
            top: -30,
            child: IgnorePointer(
              child: Container(
                width: 447,
                height: 440,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(220),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0000).withOpacity(0.25),
                      blurRadius: 180,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SDP.sdp(18),
                    vertical: SDP.sdp(10),
                  ),

                  child: Row(
                    children: [
                      // BACK BUTTON
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

                          decoration: const BoxDecoration(
                            color: Color(0xFF232728),
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

                      Expanded(
                        child: Center(
                          child: Text(
                            'Fuel station Near by',

                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w500,
                              fontSize: SDP.sdp(16.84),
                              height: 1,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      Icon(Icons.tune, color: Colors.white, size: SDP.sdp(22)),
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SDP.sdp(19)),

                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),

                      padding: EdgeInsets.only(
                        top: SDP.sdp(10),
                        bottom: SDP.sdp(30),
                      ),

                      itemCount: _pumps.length,

                      separatorBuilder: (_, __) =>
                          SizedBox(height: SDP.sdp(9.71)),

                      itemBuilder: (context, index) {
                        final pump = _pumps[index];

                        final bool isVerified = pump['isVerified'] == 'true';

                        return isVerified
                            ? _VerifiedCard(pump: pump)
                            : _StandardCard(pump: pump);
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
// ─────────────────────────────────────────────────────────────────────────────

class _StandardCard extends StatelessWidget {
  final Map<String, String> pump;

  const _StandardCard({required this.pump});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SDP.sdp(309.05),
      height: SDP.sdp(70.64),

      padding: EdgeInsets.symmetric(horizontal: SDP.sdp(14)),

      decoration: BoxDecoration(
        color: const Color(0xFFABABAB),

        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),

        boxShadow: _cardShadows,
      ),

      child: _CardRow(pump: pump, blur: false),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFIED CARD
// ─────────────────────────────────────────────────────────────────────────────

class _VerifiedCard extends StatelessWidget {
  final Map<String, String> pump;

  const _VerifiedCard({required this.pump});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFABABAB),

        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),

        boxShadow: _cardShadows,
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            // TOP BLUR SECTION
            Container(
              height: SDP.sdp(47.68),

              color: const Color(0xFFABABAB),

              padding: EdgeInsets.symmetric(horizontal: SDP.sdp(14)),

              child: Row(
                children: [
                  Expanded(
                    child: ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 5.74,
                          sigmaY: 5.74,
                        ),

                        child: _CardRow(pump: pump, blur: true),
                      ),
                    ),
                  ),

                  SizedBox(width: SDP.sdp(8)),

                  // NAVIGATION BUTTON
                  Container(
                    width: SDP.sdp(28.41),
                    height: SDP.sdp(28.25),

                    decoration: BoxDecoration(
                      color: const Color(0xFF232728),
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          offset: const Offset(0, 6.42),
                          blurRadius: 16.7,
                          spreadRadius: 0,
                        ),
                      ],
                    ),

                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: SDP.sdp(11.27),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // VERIFIED BAR
            Container(
              height: SDP.sdp(52.10),

              padding: EdgeInsets.symmetric(horizontal: SDP.sdp(13.24)),

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.7, -0.7),
                  end: Alignment(0.7, 0.7),

                  colors: [Color(0xFFFF7655), Color(0xFFFF0000)],

                  stops: [0.1688, 0.9348],
                ),

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.83),
                  bottomRight: Radius.circular(8.83),
                ),
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Milopure Trusted Pump (Verified fuel)',

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w400,
                            fontSize: SDP.sdp(12.36),
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),

                      SizedBox(width: SDP.sdp(6)),

                      // VERIFIED TICK
                      SizedBox(
                        width: SDP.sdp(13.24),
                        height: SDP.sdp(12.36),

                        child: Stack(
                          alignment: Alignment.center,

                          children: [
                            Icon(
                              Icons.verified,
                              size: SDP.sdp(13.24),
                              color: Colors.white,
                            ),

                            Positioned(
                              top: SDP.sdp(3.1),

                              child: Icon(
                                Icons.check,
                                size: SDP.sdp(6.2),
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SDP.sdp(4)),

                  Text(
                    'Consistently safe based on Milopure data',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w300,
                      fontSize: SDP.sdp(8.83),
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD ROW
// ─────────────────────────────────────────────────────────────────────────────

class _CardRow extends StatelessWidget {
  final Map<String, String> pump;
  final bool blur;

  const _CardRow({required this.pump, required this.blur});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LOGO
        Container(
          width: SDP.sdp(42.38),
          height: SDP.sdp(42.38),

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.95),
          ),

          padding: EdgeInsets.all(SDP.sdp(6)),

          child: ClipOval(
            child: Image.asset(
              'assets/images/indian_oil.png',

              fit: BoxFit.contain,

              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.local_gas_station,
                  color: const Color(0xFF070707),
                  size: SDP.sdp(18),
                );
              },
            ),
          ),
        ),

        SizedBox(width: SDP.sdp(12)),

        // TEXT
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
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w600,
                  fontSize: SDP.sdp(12.36),
                  color: const Color(0xFF121212),
                  height: 1,
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
                        color: const Color(0xFF4A4A4A),
                        height: 1,
                      ),
                    ),
                  ),

                  SizedBox(width: SDP.sdp(4)),

                  Text(
                    '|',

                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: SDP.sdp(10),
                    ),
                  ),

                  SizedBox(width: SDP.sdp(4)),

                  Icon(
                    Icons.near_me,
                    size: SDP.sdp(9.5),
                    color: const Color(0xFF070707),
                  ),

                  SizedBox(width: SDP.sdp(2)),

                  Text(
                    pump['distance']!,

                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: SDP.sdp(10.6),
                      color: const Color(0xFF4A4A4A),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // NORMAL CARD ARROW
        if (!blur) ...[
          SizedBox(width: SDP.sdp(8)),

          Container(
            width: SDP.sdp(28.41),
            height: SDP.sdp(28.25),

            decoration: BoxDecoration(
              color: const Color(0xFF232728),
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  offset: const Offset(0, 6.42),
                  blurRadius: 16.7,
                  spreadRadius: 0,
                ),
              ],
            ),

            child: Center(
              child: Icon(
                Icons.arrow_forward_rounded,
                size: SDP.sdp(11.27),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
