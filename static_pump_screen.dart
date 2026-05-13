import 'package:fl_sdp/fl_sdp.dart';
import 'package:flutter/material.dart';

class StaticPumpScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const StaticPumpScreen({super.key, this.onBack});

  static final List<Map<String, String>> _pumps = [
    {
      'name': 'Sharma Petroleum Service',
      'brand': 'Indian Oil (COCO)',
      'address': 'AB Road, Indore, Madhya Pradesh',
      'logoAsset': 'assets/logos/indian_oil.png',
      'isVerified': 'true',
    },
    {
      'name': 'Naresh Trading Company',
      'brand': 'Indian Oil (COCO)',
      'address': 'Vijay Nagar, Indore, Madhya Pradesh',
      'logoAsset': 'assets/logos/indian_oil.png',
      'isVerified': 'false',
    },
    {
      'name': 'Ravi Fuel Station',
      'brand': 'Bharat Petroleum',
      'address': 'Palasia Square, Indore, Madhya Pradesh',
      'logoAsset': 'assets/logos/bharat_petroleum.png',
      'isVerified': 'true',
    },
    {
      'name': 'Singh Petroleum',
      'brand': 'Indian Oil (COCO)',
      'address': 'Rajwada, Indore, Madhya Pradesh',
      'logoAsset': 'assets/logos/indian_oil.png',
      'isVerified': 'false',
    },
    {
      'name': 'Gupta Service Station',
      'brand': 'Bharat Petroleum',
      'address': 'Bhawarkuan, Indore, Madhya Pradesh',
      'logoAsset': 'assets/logos/bharat_petroleum.png',
      'isVerified': 'true',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),

          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),

        centerTitle: true,

        title: Text(
          'Fuel station Near by',

          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: SDP.sdp(18),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.9, -0.9),
            radius: 1.2,

            colors: [Color(0xFF3A0C0C), Color(0xFF070707)],

            stops: [0.0, 0.72],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            child: Padding(
              padding: EdgeInsets.only(
                top: SDP.sdp(18),
                left: SDP.sdp(19),
                right: SDP.sdp(19),
                bottom: SDP.sdp(30),
              ),

              child: Column(
                children: List.generate(_pumps.length, (index) {
                  final pump = _pumps[index];
                  final isVerified = pump['isVerified'] == 'true';

                  return Padding(
                    padding: EdgeInsets.only(bottom: SDP.sdp(9.71)),

                    child: isVerified
                        ? _buildVerifiedCard(pump)
                        : _buildStandardCard(pump),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── LOGO ─────────────────

  Widget _logoCircle(Map<String, String> pump) {
    return Container(
      width: SDP.sdp(42),
      height: SDP.sdp(42),

      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.18),
      ),

      clipBehavior: Clip.antiAlias,

      child: Padding(
        padding: EdgeInsets.all(SDP.sdp(8)),

        child: Image.asset(
          pump['logoAsset']!,
          fit: BoxFit.contain,

          errorBuilder: (_, __, ___) {
            return Center(
              child: Text(
                pump['name']![0],

                style: TextStyle(
                  fontSize: SDP.sdp(14),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Lexend',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────── ARROW BUTTON ─────────────────

  Widget _arrowButton() {
    return Container(
      width: SDP.sdp(28),
      height: SDP.sdp(28),

      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: SDP.sdp(6),
            offset: Offset(0, SDP.sdp(1.5)),
          ),
        ],
      ),

      child: Center(
        child: Icon(
          Icons.arrow_forward_rounded,
          size: SDP.sdp(13),
          color: Colors.black87,
        ),
      ),
    );
  }

  // ───────────────── VERIFIED TICK ─────────────────

  Widget _verifiedTick() {
    return Container(
      width: SDP.sdp(13.24),
      height: SDP.sdp(12.36),

      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),

      child: Center(
        child: Icon(Icons.check, size: SDP.sdp(8), color: Color(0xFFFF0000)),
      ),
    );
  }

  // ───────────────── VERIFIED CARD ─────────────────

  Widget _buildVerifiedCard(Map<String, String> pump) {
    return Container(
      width: SDP.sdp(309.05),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF323247).withOpacity(0.05),
            offset: Offset(0, SDP.sdp(2.65)),
            blurRadius: SDP.sdp(7.06),
            spreadRadius: SDP.sdp(-0.88),
          ),

          BoxShadow(
            color: const Color(0xFF0C1A4B).withOpacity(0.24),
            offset: const Offset(0, 0),
            blurRadius: SDP.sdp(0.88),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),

        child: Column(
          children: [
            // TOP CARD
            Container(
              height: SDP.sdp(70.64),
              color: Colors.white,

              child: Row(
                children: [
                  SizedBox(
                    width: SDP.sdp(70.64),

                    child: Center(child: _logoCircle(pump)),
                  ),

                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: SDP.sdp(16),
                        bottom: SDP.sdp(12),
                        right: SDP.sdp(8),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,

                        children: [
                          Text(
                            pump['name']!,

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w400,
                              fontSize: SDP.sdp(12.36),
                              color: const Color(0xFF1A1A1A),
                              height: 1.0,
                            ),
                          ),

                          SizedBox(height: SDP.sdp(5)),

                          Text(
                            '${pump['brand']} • ${pump['address']}',

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w400,
                              fontSize: SDP.sdp(10.6),
                              color: const Color(0xFF5A5A5A),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(right: SDP.sdp(10)),
                    child: _arrowButton(),
                  ),
                ],
              ),
            ),

            // VERIFIED BANNER
            Container(
              width: double.infinity,
              height: SDP.sdp(52.10),

              padding: EdgeInsets.symmetric(horizontal: SDP.sdp(13.24)),

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  transform: GradientRotation(131.68 * 3.1415926535 / 180),

                  colors: [Color(0xFFFF7655), Color(0xFFFF0000)],

                  stops: [0.1688, 0.9348],
                ),

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.83),
                  bottomRight: Radius.circular(8.83),
                ),
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Milopure Trusted Pump (Verified fuel)',

                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w400,
                                  fontSize: SDP.sdp(12.36),
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),

                            SizedBox(width: SDP.sdp(6)),

                            _verifiedTick(),
                          ],
                        ),

                        SizedBox(height: SDP.sdp(4)),

                        Text(
                          'Consistently safe based on Milopure data',

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w400,
                            fontSize: SDP.sdp(9),
                            color: Colors.white.withOpacity(0.80),
                            height: 1.0,
                          ),
                        ),
                      ],
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

  // ───────────────── STANDARD CARD ─────────────────

  Widget _buildStandardCard(Map<String, String> pump) {
    return Container(
      width: SDP.sdp(309.05),
      height: SDP.sdp(70.64),

      decoration: BoxDecoration(
        color: const Color(0xFFABABAB),

        borderRadius: BorderRadius.circular(SDP.sdp(8.83)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF323247).withOpacity(0.05),
            offset: Offset(0, SDP.sdp(2.65)),
            blurRadius: SDP.sdp(7.06),
            spreadRadius: SDP.sdp(-0.88),
          ),

          BoxShadow(
            color: const Color(0xFF0C1A4B).withOpacity(0.24),
            offset: const Offset(0, 0),
            blurRadius: SDP.sdp(0.88),
          ),
        ],
      ),

      child: Row(
        children: [
          SizedBox(
            width: SDP.sdp(70.64),

            child: Center(child: _logoCircle(pump)),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: SDP.sdp(16),
                bottom: SDP.sdp(12),
                right: SDP.sdp(8),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,

                children: [
                  Text(
                    pump['name']!,

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      fontSize: SDP.sdp(12.36),
                      color: const Color(0xFF1A1A1A),
                      height: 1.0,
                    ),
                  ),

                  SizedBox(height: SDP.sdp(5)),

                  Text(
                    '${pump['brand']} • ${pump['address']}',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      fontSize: SDP.sdp(10.6),
                      color: const Color(0xFF5A5A5A),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(right: SDP.sdp(10)),
            child: _arrowButton(),
          ),
        ],
      ),
    );
  }
}
