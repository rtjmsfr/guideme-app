import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guideme/place/fav_places.dart';
import 'package:guideme/place/place_model.dart';
import 'core/recommend_cubit.dart';
import 'guide/viewGuide.dart';
import 'place/viewPlace_screen.dart';

class PlacesAndGuidesScreen extends StatefulWidget {
  const PlacesAndGuidesScreen({super.key});

  @override
  State<PlacesAndGuidesScreen> createState() => _PlacesAndGuidesScreenState();
}

class _PlacesAndGuidesScreenState extends State<PlacesAndGuidesScreen>
    with SingleTickerProviderStateMixin {
  bool showFavoritesOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<RecommendationCubit>().recommendAndFetchPlaces(user);
      context.read<RecommendationCubit>().recommendAndFetchGuides(user);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        title: Text(
          'Recommendation'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritePlacesScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.white,
          tabs: [Tab(text: 'Places'.tr()), Tab(text: 'Guides'.tr())],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff196D1F),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/home'),
            ),
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/places'),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/guide'),
            ),
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/userHome'),
            ),
            IconButton(
              icon: const Icon(Icons.person_pin, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocBuilder<RecommendationCubit, RecommendationState>(
            builder: (context, state) {
              if (state is RecommendationLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is RecommendationLoaded) {
                final recommendedPlaces = state.places;
                if (recommendedPlaces.isEmpty) {
                  return Center(child: Text("No place recommendations".tr()));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: recommendedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = recommendedPlaces[index];
                    return buildPlaceCard(context, place);
                  },
                );
              } else if (state is RecommendationError) {
                return Center(child: Text("Error: ${state.message}"));
              } else {
                return const Center(child: Text("No recommendations yet"));
              }
            },
          ),

          BlocBuilder<RecommendationCubit, RecommendationState>(
            builder: (context, state) {
              if (state is RecommendationLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is RecommendationLoaded) {
                final recommendedGuides = state.guides;
                if (recommendedGuides.isEmpty) {
                  return Center(child: Text("No guide recommendations".tr()));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: recommendedGuides.length,
                  itemBuilder: (context, index) {
                    final guide = recommendedGuides[index];
                    return buildGuideCard(context, guide);
                  },
                );
              } else if (state is RecommendationError) {
                return Center(child: Text("Error: ${state.message}"));
              } else {
                return const Center(child: Text("No recommendations yet"));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildPlaceCard(BuildContext context, Place place) {
    final imageUrl =
        place.imageUrls.isNotEmpty
            ? place.imageUrls.first
            : 'https://via.placeholder.com/80';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          place.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff196D1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewPlaceScreen(place: place),
                                ),
                              );
                            },
                            child: Text(
                              'Show more'.tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 5,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGuideCard(BuildContext context, Map<String, dynamic> guide) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 30,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide['username'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text('Email: ${guide['email'] ?? 'N/A'}'),
                        const SizedBox(height: 5),
                        if (guide.containsKey('language'))
                          Text(
                            'Language: ${guide['language']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff196D1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewGuideScreen(guide: guide),
                                ),
                              );
                            },
                            child: const Text(
                              'Show more',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 5,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
