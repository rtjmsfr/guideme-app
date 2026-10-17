import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../place/place_model.dart';

class RecommendationCubit extends Cubit<RecommendationState> {
  RecommendationCubit() : super(RecommendationInitial());

  List<Place> _places = [];
  List<Map<String, dynamic>> _guides = [];

  Future<void> recommendAndFetchPlaces(User user) async {
    emit(RecommendationLoading());

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data();

      if (userData == null) {
        emit(RecommendationError('User data not found'));
        return;
      }

      final name = userData['name'] ?? 'user';
      final age = userData['age']?.toString() ?? '25';
      final language = userData['language'] ?? 'Arabic';
      final location = userData['location'] ?? 'الدمام';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/recommend/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "age": age,
          "language": language,
          "location": location,
          "model_type": "place",
          "top_n": 10,
        }),
      );

      if (response.statusCode == 200) {
        final List<String> recommendedNames = List<String>.from(
          jsonDecode(response.body),
        );

        final allPlaces = await loadPlacesFromCsv();

        final recommendedPlaces =
            allPlaces
                .where(
                  (place) => recommendedNames.any(
                    (recName) =>
                        place.name.toLowerCase().trim() ==
                        recName.toLowerCase().trim(),
                  ),
                )
                .toList();

        _places = recommendedPlaces;
        emit(RecommendationLoaded(places: _places, guides: _guides));
      } else {
        emit(
          RecommendationError(
            'Recommendation API error with status: ${response.statusCode}',
          ),
        );
      }
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> recommendAndFetchGuides(User user) async {
    emit(RecommendationLoading());

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data();

      if (userData == null) {
        emit(RecommendationError('User data not found'));
        return;
      }

      final name = userData['name'] ?? 'user';
      final age = userData['age']?.toString() ?? '25';
      final language = userData['language'] ?? 'Arabic';
      final location = userData['location'] ?? 'الدمام';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/recommend/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "age": age,
          "language": language,
          "location": location,
          "model_type": "guide",
          "top_n": 10,
        }),
      );

      if (response.statusCode == 200) {
        final List<String> recommendedNames = List<String>.from(
          jsonDecode(response.body),
        );

        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('username', whereIn: recommendedNames)
                .get();

        final guides =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

        _guides = guides;
        emit(RecommendationLoaded(places: _places, guides: _guides));
      } else {
        emit(RecommendationError('Recommendation API error'));
      }
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }
}

@immutable
abstract class RecommendationState {}

class RecommendationInitial extends RecommendationState {}

class RecommendationLoading extends RecommendationState {}

class RecommendationLoaded extends RecommendationState {
  final List<Place> places;
  final List<Map<String, dynamic>> guides;

  RecommendationLoaded({required this.places, required this.guides});
}

class RecommendationError extends RecommendationState {
  final String message;

  RecommendationError(this.message);
}
