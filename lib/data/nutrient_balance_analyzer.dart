import 'package:flutter/foundation.dart';

enum DietaryPreference { all, vegetarian, vegan }

class NutrientThresholds {
  static const double HIGH_CARBS_GRAMS = 30.0;
  static const double HIGH_SUGAR_GRAMS = 15.0;
  static const double LOW_FIBER_GRAMS = 3.0;
  static const double LOW_PROTEIN_GRAMS = 5.0;
  static const double HIGH_SODIUM_GRAMS = 460.0;
  static const double HIGH_CARBS_PERCENT = 0.25;
  static const double HIGH_SUGAR_PERCENT = 0.15;
}

class ComplementaryFoods {
  static const Map<String, Map<DietaryPreference, List<String>>>
      HIGH_PROTEIN_FOODS = {
    'quick_options': {
      DietaryPreference.all: [
        'Greek yogurt (1/2 cup)',
        'Whey protein shake',
        'Handful of almonds (23 pieces)',
      ],
      DietaryPreference.vegetarian: [
        'Greek yogurt (1/2 cup)',
        'Cottage cheese (1/2 cup)',
        'Mixed nuts (1/4 cup)',
        'Plant-based protein shake',
      ],
    },
    'whole_foods': {
      DietaryPreference.all: [
        'Eggs (2 whole)',
        'Chicken breast (3 oz)',
        'Fish (3 oz)',
        'Lentils (1/2 cup cooked)',
      ],
      DietaryPreference.vegetarian: [
        'Paneer (1/2 cup)',
        'Lentils (1/2 cup cooked)',
        'Quinoa (1/2 cup cooked)',
        'Greek yogurt bowl',
        'Cottage cheese (1/2 cup)',
      ],
    },
  };

  static const Map<String, List<String>> HIGH_FIBER_FOODS = {
    'quick_options': [
      'Chia seeds (2 tbsp)',
      'Flax seeds (1 tbsp)',
      'Psyllium husk (1 tsp)',
      'Mixed berries (1/2 cup)',
      'Apple with skin (1 medium)',
    ],
    'whole_foods': [
      'Oats (1/2 cup)',
      'Green leafy vegetables (1 cup)',
      'Broccoli (1 cup)',
      'Black beans (1/2 cup)',
      'Sweet potato (1/2 cup)',
      'Quinoa (1/2 cup)',
    ],
  };

  static const List<String> HEALTHY_FATS = [
    'Ghee (1 tsp)',
    'Olive oil (1 tbsp)',
    'Avocado (1/4)',
    'Nut butter (1 tbsp)',
    'Mixed seeds (1 tbsp)',
  ];

  static const Map<String, List<String>> HIGH_SODIUM_COUNTERACTIONS = {
    'quick_options': [
      'Water (1-2 glasses)',
      'Banana (1 medium)',
      'Coconut water (1 cup)',
      'Lemon water',
      'Plain yogurt (1/2 cup)',
    ],
    'whole_foods': [
      'Leafy greens (1 cup)',
      'Sweet potato (1/2 cup)',
      'Avocado (1/4)',
      'Unsalted nuts (1/4 cup)',
      'Fresh fruits',
    ],
  };
}

class BalanceRecommendation {
  final String concern;
  final List<String> complementaryFoods;
  final String timingAdvice;
  final String portionAdvice;
  final String scientificReason;

  BalanceRecommendation({
    required this.concern,
    required this.complementaryFoods,
    required this.timingAdvice,
    required this.portionAdvice,
    required this.scientificReason,
  });
}

class NutrientBalanceAnalyzer {
  final DietaryPreference dietaryPreference;

  NutrientBalanceAnalyzer({
    this.dietaryPreference = DietaryPreference.all,
  });

  String _generateConcern(bool isHighCarb, bool isHighSugar, double fiber,
      double protein, bool isHighSodium) {
    List<String> concerns = [];

    if (isHighCarb && isHighSugar) {
      concerns.add("This food is high in both carbohydrates and sugars");
    } else if (isHighCarb) {
      concerns.add("This food is high in carbohydrates");
    } else if (isHighSugar) {
      concerns.add("This food is high in sugars");
    }

    if (fiber < NutrientThresholds.LOW_FIBER_GRAMS) {
      concerns.add("and low in fiber");
    }
    if (protein < NutrientThresholds.LOW_PROTEIN_GRAMS) {
      concerns.add("and low in protein");
    }
    if (isHighSodium) {
      concerns.add(concerns.isEmpty
          ? "This food is high in sodium"
          : "and high in sodium");
    }

    return concerns.join(" ");
  }

  String _generatePortionAdvice(double carbs, double sugar) {
    if (carbs > NutrientThresholds.HIGH_CARBS_GRAMS &&
        sugar > NutrientThresholds.HIGH_SUGAR_GRAMS) {
      return "Consider reducing the portion size or splitting it throughout the day to manage blood sugar levels better.";
    }
    return "Maintain recommended portion size and pair with suggested complementary foods.";
  }

  String _generateScientificExplanation(bool isHighCarb, bool isHighSugar) {
    List<String> explanations = [];

    if (isHighCarb || isHighSugar) {
      explanations.add(
          "Adding fiber slows down carbohydrate absorption, while protein and healthy fats help moderate blood sugar response. "
          "This combination helps prevent rapid blood sugar spikes and subsequent crashes.");
    }

    if (isHighSugar) {
      explanations.add(
          "The protein and fiber combination also helps maintain sustained energy levels and promotes feelings of fullness.");
    }

    return explanations.join(" ");
  }

  String _generateTimingAdvice(
      bool isHighCarb, bool isHighSugar, bool needsFiber, bool isHighSodium) {
    List<String> advice = [];

    if (needsFiber && (isHighCarb || isHighSugar)) {
      advice.add("For optimal blood sugar management:\n"
          "1. Consume fiber-rich foods 15-30 minutes before your meal\n"
          "2. Include protein and healthy fats with your meal\n"
          "3. Consider a short walk within 30 minutes after eating");
    } else {
      advice.add(
          "Include the recommended complementary foods with your meal for balanced nutrition.");
    }

    if (isHighSodium) {
      advice.add("\nFor high sodium content:\n"
          "1. Drink plenty of water throughout the day\n"
          "2. Include potassium-rich foods in your next meal\n"
          "3. Consider reducing portion size");
    }

    return advice.join("\n");
  }

  String _generateCarbAdvice(
      double carbs, double fiber, double sugar, double protein) {
    List<String> advice = [];

    if (carbs == 0) return ""; // No advice needed if no carbs

    if (fiber < NutrientThresholds.LOW_FIBER_GRAMS && carbs > 0) {
      advice.add(
          "Consider adding fiber-rich foods to slow down carbohydrate absorption");
    }

    if (sugar / carbs > 0.2) {
      // If more than 20% of carbs are sugar
      advice.add("This food contains a high proportion of simple sugars");
    }

    if (protein < NutrientThresholds.LOW_PROTEIN_GRAMS && carbs > 15) {
      advice.add("Adding protein can help moderate blood sugar response");
    }

    return advice.join(". ");
  }

  BalanceRecommendation analyzeAndRecommend({
    required double carbs,
    required double sugar,
    required double fiber,
    required double protein,
    required double servingSize,
    double sodium = 0.0,
  }) {
    List<String> recommendations = [];

    bool isHighCarb = carbs > NutrientThresholds.HIGH_CARBS_GRAMS ||
        (carbs / servingSize) > NutrientThresholds.HIGH_CARBS_PERCENT;

    bool isHighSugar = sugar > NutrientThresholds.HIGH_SUGAR_GRAMS ||
        (sugar / servingSize) > NutrientThresholds.HIGH_SUGAR_PERCENT;
    bool isHighSodium = sodium > NutrientThresholds.HIGH_SODIUM_GRAMS;

    bool needsFiber = fiber < NutrientThresholds.LOW_FIBER_GRAMS;
    bool needsProtein = protein < NutrientThresholds.LOW_PROTEIN_GRAMS;
    String concern =
        _generateConcern(isHighCarb, isHighSugar, fiber, protein, isHighSodium);
    String timingAdvice = _generateTimingAdvice(
        isHighCarb, isHighSugar, needsFiber, isHighSodium);

    String carbAdvice = _generateCarbAdvice(carbs, fiber, sugar, protein);
    if (carbAdvice.isNotEmpty) {
      // Add carb-specific advice to your recommendation
      return BalanceRecommendation(
        concern: concern + (concern.isEmpty ? "" : ". ") + carbAdvice,
        complementaryFoods: recommendations,
        timingAdvice: _generateTimingAdvice(
            isHighCarb, isHighSugar, needsFiber, isHighSodium),
        portionAdvice: _generatePortionAdvice(carbs, sugar),
        scientificReason:
            _generateScientificExplanation(isHighCarb, isHighSugar),
      );
    }

    if (isHighCarb || isHighSugar) {
      if (needsFiber) {
        recommendations
            .addAll(ComplementaryFoods.HIGH_FIBER_FOODS['quick_options']!);
      }

      if (needsProtein) {
        recommendations.addAll(ComplementaryFoods
            .HIGH_PROTEIN_FOODS['quick_options']![dietaryPreference]!);
      }

      recommendations.addAll(ComplementaryFoods.HEALTHY_FATS);
    }

    if (isHighSodium) {
      recommendations.addAll(
          ComplementaryFoods.HIGH_SODIUM_COUNTERACTIONS['quick_options']!);

      String sodiumConcern = "This food is high in sodium";
      if (concern.isNotEmpty) {
        concern += " and $sodiumConcern";
      } else {
        concern = sodiumConcern;
      }

      if (timingAdvice.isNotEmpty) {
        timingAdvice += "\n\nFor high sodium content:\n"
            "1. Drink plenty of water throughout the day\n"
            "2. Include potassium-rich foods in your next meal\n"
            "3. Consider reducing portion size";
      }
    }

    return BalanceRecommendation(
      concern: _generateConcern(
          isHighCarb, isHighSugar, fiber, protein, isHighSodium),
      complementaryFoods: recommendations,
      timingAdvice: _generateTimingAdvice(
          isHighCarb, isHighSugar, needsFiber, isHighSodium),
      portionAdvice: _generatePortionAdvice(carbs, sugar),
      scientificReason: _generateScientificExplanation(isHighCarb, isHighSugar),
    );
  }
}
