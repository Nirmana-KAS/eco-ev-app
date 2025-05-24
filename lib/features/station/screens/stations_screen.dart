import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  String _searchText = '';
  int _selectedChip = 0;
  final List<String> chips = ["Nearby", "Availability", "Newest"];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color green = const Color(0xFF61B15A);
    final Color gray = const Color(0xFFECECEC);
    final Color dark = const Color(0xFF23272E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null, // No appbar as per your design
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location + Notification
              Row(
                children: [
                  Icon(Icons.location_on, color: green, size: 22),
                  const SizedBox(width: 5),
                  Text(
                    "Homagama, Sri lanka", // <-- You can use your location code
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dark.withOpacity(0.7),
                    ),
                  ),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: gray, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_none_outlined,
                        color: dark,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: gray,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchText = v),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search e-stations, city, etc",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = i == _selectedChip;
                    return ChoiceChip(
                      label: Text(
                        chips[i],
                        style: TextStyle(
                          color: selected ? green : dark,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      selectedColor: green.withOpacity(0.13),
                      backgroundColor: gray,
                      onSelected: (_) => setState(() => _selectedChip = i),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Stations List/Grid
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('stations')
                          .orderBy('name')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;

                    // Filter by search
                    final filtered =
                        docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              (data['name'] ?? '').toString().toLowerCase();
                          final address =
                              (data['address'] ?? '').toString().toLowerCase();
                          return name.contains(_searchText.toLowerCase()) ||
                              address.contains(_searchText.toLowerCase());
                        }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text("No stations found"));
                    }

                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final doc = filtered[idx];
                        final data = doc.data() as Map<String, dynamic>;
                        return _stationCard(context, data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom nav bar is handled in your main navigation
    );
  }

  Widget _stationCard(BuildContext context, Map<String, dynamic> data) {
    final Color green = const Color(0xFF61B15A);
    final logoUrl = data['logoUrl'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF23272E).withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 14),
          // Station Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child:
                logoUrl != null && logoUrl.isNotEmpty
                    ? Image.network(
                      logoUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    )
                    : Image.asset(
                      'assets/station_icon.png', // fallback image in assets
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
          ),
          const SizedBox(height: 8),
          Text(
            "Rs.${data['pricePerHour']?.toString() ?? '-'} /hour",
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on, color: green, size: 16),
              const SizedBox(width: 2),
              Text(
                "${data['slots2x'] ?? 0}x Speed",
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Icon(Icons.ev_station_rounded, color: green, size: 16),
              const SizedBox(width: 2),
              Text(
                "${data['slots1x'] ?? 0}",
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.grey, size: 15),
              Flexible(
                child: Text(
                  data['address'] ?? '-',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data['name'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "Direction",
            style: TextStyle(
              fontSize: 12,
              color: green,
              decoration: TextDecoration.underline,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Go to booking/Station detail (implement as needed)
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                "Book Now",
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
