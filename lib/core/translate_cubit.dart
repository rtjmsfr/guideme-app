import 'package:flutter_bloc/flutter_bloc.dart';

import 'TranslationService.dart';


class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit() : super(TranslationInitial());

  Map<String, String> currentTranslations = {};

  Future<void> translateTexts({
    required List<String> texts,
    required String from,
    required String to,
  }) async {
    emit(TranslationLoading());

    try {
      final translations = await TranslationService.translate(
        texts: texts,
        from: from,
        to: to,
      );

      currentTranslations = translations; // 🟢 خزّناها
      emit(TranslationSuccessMultiple(translations));
    } catch (e) {
      emit(TranslationError("فشل الترجمة: $e"));
    }
  }

  String getTranslated(String original) {
    return currentTranslations[original] ?? original;
  }
}

abstract class TranslationState {}

class TranslationInitial extends TranslationState {}

class TranslationLoading extends TranslationState {}

class TranslationSuccess extends TranslationState {
  final String translatedText;
  TranslationSuccess(this.translatedText);
}
class TranslationSuccessMultiple extends TranslationState {
  final Map<String, String> translations;
  TranslationSuccessMultiple(this.translations);
}
class TranslationError extends TranslationState {
  final String message;
  TranslationError(this.message);
}
