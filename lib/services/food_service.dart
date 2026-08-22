import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/food.dart';
import '../models/food_icon.dart';

class FoodService {
  SupabaseClient get _client => SupabaseConfig.client;

  // Fallback / default catalogue with 170+ common German household foods
  static final List<Food> defaultFoods = [
    // Gemüse
    Food(id: 'f_1', name: 'Tomaten', createdAt: DateTime.now()),
    Food(id: 'f_2', name: 'Cherrytomaten', createdAt: DateTime.now()),
    Food(id: 'f_3', name: 'Gurke', createdAt: DateTime.now()),
    Food(id: 'f_4', name: 'Paprika', createdAt: DateTime.now()),
    Food(id: 'f_5', name: 'Zwiebeln', createdAt: DateTime.now()),
    Food(id: 'f_6', name: 'Rote Zwiebeln', createdAt: DateTime.now()),
    Food(id: 'f_7', name: 'Frühlingszwiebeln', createdAt: DateTime.now()),
    Food(id: 'f_8', name: 'Knoblauch', createdAt: DateTime.now()),
    Food(id: 'f_9', name: 'Karotten', createdAt: DateTime.now()),
    Food(id: 'f_10', name: 'Brokkoli', createdAt: DateTime.now()),
    Food(id: 'f_11', name: 'Blumenkohl', createdAt: DateTime.now()),
    Food(id: 'f_12', name: 'Zucchini', createdAt: DateTime.now()),
    Food(id: 'f_13', name: 'Aubergine', createdAt: DateTime.now()),
    Food(id: 'f_14', name: 'Champignons', createdAt: DateTime.now()),
    Food(id: 'f_15', name: 'Lauch', createdAt: DateTime.now()),
    Food(id: 'f_16', name: 'Sellerie', createdAt: DateTime.now()),
    Food(id: 'f_17', name: 'Weißkohl', createdAt: DateTime.now()),
    Food(id: 'f_18', name: 'Rotkohl', createdAt: DateTime.now()),
    Food(id: 'f_19', name: 'Wirsing', createdAt: DateTime.now()),
    Food(id: 'f_20', name: 'Rosenkohl', createdAt: DateTime.now()),
    Food(id: 'f_21', name: 'Spinat', createdAt: DateTime.now()),
    Food(id: 'f_22', name: 'Feldsalat', createdAt: DateTime.now()),
    Food(id: 'f_23', name: 'Kopfsalat', createdAt: DateTime.now()),
    Food(id: 'f_24', name: 'Eisbergsalat', createdAt: DateTime.now()),
    Food(id: 'f_25', name: 'Rucola', createdAt: DateTime.now()),
    Food(id: 'f_26', name: 'Mais', createdAt: DateTime.now()),
    Food(id: 'f_27', name: 'Erbsen', createdAt: DateTime.now()),
    Food(id: 'f_28', name: 'Grüne Bohnen', createdAt: DateTime.now()),
    Food(id: 'f_29', name: 'Kidneybohnen', createdAt: DateTime.now()),
    Food(id: 'f_30', name: 'Kichererbsen', createdAt: DateTime.now()),
    Food(id: 'f_31', name: 'Linsen', createdAt: DateTime.now()),
    Food(id: 'f_32', name: 'Kürbis', createdAt: DateTime.now()),
    Food(id: 'f_33', name: 'Süßkartoffeln', createdAt: DateTime.now()),
    Food(id: 'f_34', name: 'Radieschen', createdAt: DateTime.now()),
    Food(id: 'f_35', name: 'Spargel', createdAt: DateTime.now()),
    Food(id: 'f_36', name: 'Rote Bete', createdAt: DateTime.now()),
    Food(id: 'f_37', name: 'Avocado', createdAt: DateTime.now()),
    Food(id: 'f_38', name: 'Ingwer', createdAt: DateTime.now()),
    Food(id: 'f_39', name: 'Peperoni', createdAt: DateTime.now()),
    Food(id: 'f_40', name: 'Chinakohl', createdAt: DateTime.now()),
    Food(id: 'f_41', name: 'Kohlrabi', createdAt: DateTime.now()),
    Food(id: 'f_42', name: 'Fenchel', createdAt: DateTime.now()),

    // Obst
    Food(id: 'f_43', name: 'Äpfel', createdAt: DateTime.now()),
    Food(id: 'f_44', name: 'Bananen', createdAt: DateTime.now()),
    Food(id: 'f_45', name: 'Birnen', createdAt: DateTime.now()),
    Food(id: 'f_46', name: 'Orangen', createdAt: DateTime.now()),
    Food(id: 'f_47', name: 'Mandarinen', createdAt: DateTime.now()),
    Food(id: 'f_48', name: 'Zitronen', createdAt: DateTime.now()),
    Food(id: 'f_49', name: 'Limetten', createdAt: DateTime.now()),
    Food(id: 'f_50', name: 'Erdbeeren', createdAt: DateTime.now()),
    Food(id: 'f_51', name: 'Himbeeren', createdAt: DateTime.now()),
    Food(id: 'f_52', name: 'Heidelbeeren', createdAt: DateTime.now()),
    Food(id: 'f_53', name: 'Brombeeren', createdAt: DateTime.now()),
    Food(id: 'f_54', name: 'Weintrauben', createdAt: DateTime.now()),
    Food(id: 'f_55', name: 'Kirschen', createdAt: DateTime.now()),
    Food(id: 'f_56', name: 'Pfirsiche', createdAt: DateTime.now()),
    Food(id: 'f_57', name: 'Nektarinen', createdAt: DateTime.now()),
    Food(id: 'f_58', name: 'Pflaumen', createdAt: DateTime.now()),
    Food(id: 'f_59', name: 'Kiwi', createdAt: DateTime.now()),
    Food(id: 'f_60', name: 'Ananas', createdAt: DateTime.now()),
    Food(id: 'f_61', name: 'Mango', createdAt: DateTime.now()),
    Food(id: 'f_62', name: 'Wassermelone', createdAt: DateTime.now()),
    Food(id: 'f_63', name: 'Honigmelone', createdAt: DateTime.now()),
    Food(id: 'f_64', name: 'Grapefruit', createdAt: DateTime.now()),
    Food(id: 'f_65', name: 'Granatapfel', createdAt: DateTime.now()),

    // Kartoffeln
    Food(id: 'f_66', name: 'Kartoffeln', createdAt: DateTime.now()),
    Food(id: 'f_67', name: 'Kartoffelpüree', createdAt: DateTime.now()),
    Food(id: 'f_68', name: 'Kartoffelklöße', createdAt: DateTime.now()),
    Food(id: 'f_69', name: 'Schupfnudeln', createdAt: DateTime.now()),
    Food(id: 'f_70', name: 'Gnocchi', createdAt: DateTime.now()),

    // Fleisch
    Food(id: 'f_71', name: 'Hackfleisch', createdAt: DateTime.now()),
    Food(id: 'f_72', name: 'Rinderhackfleisch', createdAt: DateTime.now()),
    Food(id: 'f_73', name: 'Schweinehackfleisch', createdAt: DateTime.now()),
    Food(id: 'f_74', name: 'Hähnchenbrust', createdAt: DateTime.now()),
    Food(id: 'f_75', name: 'Hähnchenschenkel', createdAt: DateTime.now()),
    Food(id: 'f_76', name: 'Putenbrust', createdAt: DateTime.now()),
    Food(id: 'f_77', name: 'Schweineschnitzel', createdAt: DateTime.now()),
    Food(id: 'f_78', name: 'Schweinefilet', createdAt: DateTime.now()),
    Food(id: 'f_79', name: 'Rindfleisch', createdAt: DateTime.now()),
    Food(id: 'f_80', name: 'Rindersteak', createdAt: DateTime.now()),
    Food(id: 'f_81', name: 'Gulaschfleisch', createdAt: DateTime.now()),
    Food(id: 'f_82', name: 'Frikadellen', createdAt: DateTime.now()),
    Food(id: 'f_83', name: 'Suppenfleisch', createdAt: DateTime.now()),

    // Wurst
    Food(id: 'f_84', name: 'Kochschinken', createdAt: DateTime.now()),
    Food(id: 'f_85', name: 'Rohschinken', createdAt: DateTime.now()),
    Food(id: 'f_86', name: 'Salami', createdAt: DateTime.now()),
    Food(id: 'f_87', name: 'Fleischwurst', createdAt: DateTime.now()),
    Food(id: 'f_88', name: 'Bratwurst', createdAt: DateTime.now()),
    Food(id: 'f_89', name: 'Wiener Würstchen', createdAt: DateTime.now()),
    Food(id: 'f_90', name: 'Bacon', createdAt: DateTime.now()),
    Food(id: 'f_91', name: 'Aufschnitt', createdAt: DateTime.now()),
    Food(id: 'f_92', name: 'Leberkäse', createdAt: DateTime.now()),
    Food(id: 'f_93', name: 'Schinkenwürfel', createdAt: DateTime.now()),

    // Fisch
    Food(id: 'f_94', name: 'Lachs', createdAt: DateTime.now()),
    Food(id: 'f_95', name: 'Thunfisch', createdAt: DateTime.now()),
    Food(id: 'f_96', name: 'Thunfisch in Dose', createdAt: DateTime.now()),
    Food(id: 'f_97', name: 'Fischstäbchen', createdAt: DateTime.now()),
    Food(id: 'f_98', name: 'Seelachs', createdAt: DateTime.now()),
    Food(id: 'f_99', name: 'Garnelen', createdAt: DateTime.now()),
    Food(id: 'f_100', name: 'Forelle', createdAt: DateTime.now()),
    Food(id: 'f_101', name: 'Kabeljau', createdAt: DateTime.now()),

    // Milchprodukte
    Food(id: 'f_102', name: 'Milch', createdAt: DateTime.now()),
    Food(id: 'f_103', name: 'Hafermilch', createdAt: DateTime.now()),
    Food(id: 'f_104', name: 'Sahne', createdAt: DateTime.now()),
    Food(id: 'f_105', name: 'Kochsahne', createdAt: DateTime.now()),
    Food(id: 'f_106', name: 'Saure Sahne', createdAt: DateTime.now()),
    Food(id: 'f_107', name: 'Schmand', createdAt: DateTime.now()),
    Food(id: 'f_108', name: 'Joghurt', createdAt: DateTime.now()),
    Food(id: 'f_109', name: 'Naturjoghurt', createdAt: DateTime.now()),
    Food(id: 'f_110', name: 'Griechischer Joghurt', createdAt: DateTime.now()),
    Food(id: 'f_111', name: 'Quark', createdAt: DateTime.now()),
    Food(id: 'f_112', name: 'Butter', createdAt: DateTime.now()),
    Food(id: 'f_113', name: 'Margarine', createdAt: DateTime.now()),
    Food(id: 'f_114', name: 'Crème fraîche', createdAt: DateTime.now()),
    Food(id: 'f_115', name: 'Buttermilch', createdAt: DateTime.now()),

    // Käse
    Food(id: 'f_116', name: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_117', name: 'Gouda', createdAt: DateTime.now()),
    Food(id: 'f_118', name: 'Emmentaler', createdAt: DateTime.now()),
    Food(id: 'f_119', name: 'Mozzarella', createdAt: DateTime.now()),
    Food(id: 'f_120', name: 'Parmesan', createdAt: DateTime.now()),
    Food(id: 'f_121', name: 'Feta', createdAt: DateTime.now()),
    Food(id: 'f_122', name: 'Frischkäse', createdAt: DateTime.now()),
    Food(id: 'f_123', name: 'Scheibenkäse', createdAt: DateTime.now()),
    Food(id: 'f_124', name: 'Reibekäse', createdAt: DateTime.now()),
    Food(id: 'f_125', name: 'Camembert', createdAt: DateTime.now()),
    Food(id: 'f_126', name: 'Schafskäse', createdAt: DateTime.now()),
    Food(id: 'f_127', name: 'Halloumi', createdAt: DateTime.now()),

    // Eier
    Food(id: 'f_128', name: 'Eier', createdAt: DateTime.now()),

    // Brot & Backwaren
    Food(id: 'f_129', name: 'Brot', createdAt: DateTime.now()),
    Food(id: 'f_130', name: 'Toast', createdAt: DateTime.now()),
    Food(id: 'f_131', name: 'Brötchen', createdAt: DateTime.now()),
    Food(id: 'f_132', name: 'Baguette', createdAt: DateTime.now()),
    Food(id: 'f_133', name: 'Vollkornbrot', createdAt: DateTime.now()),
    Food(id: 'f_134', name: 'Knäckebrot', createdAt: DateTime.now()),
    Food(id: 'f_135', name: 'Wraps', createdAt: DateTime.now()),
    Food(id: 'f_136', name: 'Burgerbrötchen', createdAt: DateTime.now()),
    Food(id: 'f_137', name: 'Hot-Dog-Brötchen', createdAt: DateTime.now()),
    Food(id: 'f_138', name: 'Pizzateig', createdAt: DateTime.now()),
    Food(id: 'f_139', name: 'Blätterteig', createdAt: DateTime.now()),
    Food(id: 'f_140', name: 'Fladenbrot', createdAt: DateTime.now()),

    // Nudeln & Reis
    Food(id: 'f_141', name: 'Nudeln', createdAt: DateTime.now()),
    Food(id: 'f_142', name: 'Spaghetti', createdAt: DateTime.now()),
    Food(id: 'f_143', name: 'Penne', createdAt: DateTime.now()),
    Food(id: 'f_144', name: 'Fusilli', createdAt: DateTime.now()),
    Food(id: 'f_145', name: 'Makkaroni', createdAt: DateTime.now()),
    Food(id: 'f_146', name: 'Lasagneplatten', createdAt: DateTime.now()),
    Food(id: 'f_147', name: 'Tortellini', createdAt: DateTime.now()),
    Food(id: 'f_148', name: 'Reis', createdAt: DateTime.now()),
    Food(id: 'f_149', name: 'Basmatireis', createdAt: DateTime.now()),
    Food(id: 'f_150', name: 'Jasminreis', createdAt: DateTime.now()),
    Food(id: 'f_151', name: 'Risottoreis', createdAt: DateTime.now()),
    Food(id: 'f_152', name: 'Couscous', createdAt: DateTime.now()),
    Food(id: 'f_153', name: 'Bulgur', createdAt: DateTime.now()),

    // Konserven & Gläser
    Food(id: 'f_154', name: 'Passierte Tomaten', createdAt: DateTime.now()),
    Food(id: 'f_155', name: 'Gehackte Tomaten', createdAt: DateTime.now()),
    Food(id: 'f_156', name: 'Tomatenmark', createdAt: DateTime.now()),
    Food(id: 'f_157', name: 'Weiße Bohnen', createdAt: DateTime.now()),
    Food(id: 'f_158', name: 'Gewürzgurken', createdAt: DateTime.now()),
    Food(id: 'f_159', name: 'Apfelmus', createdAt: DateTime.now()),
    Food(id: 'f_160', name: 'Kokosmilch', createdAt: DateTime.now()),
    Food(id: 'f_161', name: 'Sauerkraut', createdAt: DateTime.now()),
    Food(id: 'f_162', name: 'Oliven', createdAt: DateTime.now()),

    // Tiefkühl
    Food(id: 'f_163', name: 'Tiefkühlpizza', createdAt: DateTime.now()),
    Food(id: 'f_164', name: 'Pommes', createdAt: DateTime.now()),
    Food(id: 'f_165', name: 'Kroketten', createdAt: DateTime.now()),
    Food(id: 'f_166', name: 'Tiefkühlgemüse', createdAt: DateTime.now()),
    Food(id: 'f_167', name: 'Tiefkühlbrokkoli', createdAt: DateTime.now()),
    Food(id: 'f_168', name: 'Tiefkühlspinat', createdAt: DateTime.now()),
    Food(id: 'f_169', name: 'Tiefkühlerbsen', createdAt: DateTime.now()),
    Food(id: 'f_170', name: 'Tiefkühlbeeren', createdAt: DateTime.now()),
    Food(id: 'f_171', name: 'Eis', createdAt: DateTime.now()),

    // Gewürze
    Food(id: 'f_172', name: 'Salz', createdAt: DateTime.now()),
    Food(id: 'f_173', name: 'Pfeffer', createdAt: DateTime.now()),
    Food(id: 'f_174', name: 'Paprikapulver', createdAt: DateTime.now()),
    Food(id: 'f_175', name: 'Curry', createdAt: DateTime.now()),
    Food(id: 'f_176', name: 'Knoblauchpulver', createdAt: DateTime.now()),
    Food(id: 'f_177', name: 'Zwiebelpulver', createdAt: DateTime.now()),
    Food(id: 'f_178', name: 'Oregano', createdAt: DateTime.now()),
    Food(id: 'f_179', name: 'Basilikum', createdAt: DateTime.now()),
    Food(id: 'f_180', name: 'Petersilie', createdAt: DateTime.now()),
    Food(id: 'f_181', name: 'Schnittlauch', createdAt: DateTime.now()),
    Food(id: 'f_182', name: 'Muskat', createdAt: DateTime.now()),
    Food(id: 'f_183', name: 'Chili', createdAt: DateTime.now()),
    Food(id: 'f_184', name: 'Kreuzkümmel', createdAt: DateTime.now()),
    Food(id: 'f_185', name: 'Rosmarin', createdAt: DateTime.now()),
    Food(id: 'f_186', name: 'Thymian', createdAt: DateTime.now()),
    Food(id: 'f_187', name: 'Zimt', createdAt: DateTime.now()),
    Food(id: 'f_188', name: 'Gemüsebrühe', createdAt: DateTime.now()),
    Food(id: 'f_189', name: 'Fleischbrühe', createdAt: DateTime.now()),

    // Saucen
    Food(id: 'f_190', name: 'Ketchup', createdAt: DateTime.now()),
    Food(id: 'f_191', name: 'Mayonnaise', createdAt: DateTime.now()),
    Food(id: 'f_192', name: 'Senf', createdAt: DateTime.now()),
    Food(id: 'f_193', name: 'BBQ-Sauce', createdAt: DateTime.now()),
    Food(id: 'f_194', name: 'Sojasauce', createdAt: DateTime.now()),
    Food(id: 'f_195', name: 'Sweet-Chili-Sauce', createdAt: DateTime.now()),
    Food(id: 'f_196', name: 'Currysauce', createdAt: DateTime.now()),
    Food(id: 'f_197', name: 'Tomatensauce', createdAt: DateTime.now()),
    Food(id: 'f_198', name: 'Pesto', createdAt: DateTime.now()),
    Food(id: 'f_199', name: 'Pesto Rosso', createdAt: DateTime.now()),
    Food(id: 'f_200', name: 'Remoulade', createdAt: DateTime.now()),

    // Öle & Fette
    Food(id: 'f_201', name: 'Olivenöl', createdAt: DateTime.now()),
    Food(id: 'f_202', name: 'Sonnenblumenöl', createdAt: DateTime.now()),
    Food(id: 'f_203', name: 'Rapsöl', createdAt: DateTime.now()),
    Food(id: 'f_204', name: 'Essig', createdAt: DateTime.now()),
    Food(id: 'f_205', name: 'Balsamico-Essig', createdAt: DateTime.now()),

    // Frühstück
    Food(id: 'f_206', name: 'Haferflocken', createdAt: DateTime.now()),
    Food(id: 'f_207', name: 'Cornflakes', createdAt: DateTime.now()),
    Food(id: 'f_208', name: 'Müsli', createdAt: DateTime.now()),
    Food(id: 'f_209', name: 'Marmelade', createdAt: DateTime.now()),
    Food(id: 'f_210', name: 'Honig', createdAt: DateTime.now()),
    Food(id: 'f_211', name: 'Nutella', createdAt: DateTime.now()),
    Food(id: 'f_212', name: 'Erdnussbutter', createdAt: DateTime.now()),

    // Backen
    Food(id: 'f_213', name: 'Mehl', createdAt: DateTime.now()),
    Food(id: 'f_214', name: 'Zucker', createdAt: DateTime.now()),
    Food(id: 'f_215', name: 'Puderzucker', createdAt: DateTime.now()),
    Food(id: 'f_216', name: 'Backpulver', createdAt: DateTime.now()),
    Food(id: 'f_217', name: 'Vanillezucker', createdAt: DateTime.now()),
    Food(id: 'f_218', name: 'Kakao', createdAt: DateTime.now()),
    Food(id: 'f_219', name: 'Schokolade', createdAt: DateTime.now()),
    Food(id: 'f_220', name: 'Kuvertüre', createdAt: DateTime.now()),
    Food(id: 'f_221', name: 'Hefe', createdAt: DateTime.now()),
    Food(id: 'f_222', name: 'Speisestärke', createdAt: DateTime.now()),

    // Getränke
    Food(id: 'f_223', name: 'Wasser', createdAt: DateTime.now()),
    Food(id: 'f_224', name: 'Mineralwasser', createdAt: DateTime.now()),
    Food(id: 'f_225', name: 'Cola', createdAt: DateTime.now()),
    Food(id: 'f_226', name: 'Limonade', createdAt: DateTime.now()),
    Food(id: 'f_227', name: 'Orangensaft', createdAt: DateTime.now()),
    Food(id: 'f_228', name: 'Apfelsaft', createdAt: DateTime.now()),
    Food(id: 'f_229', name: 'Kaffee', createdAt: DateTime.now()),
    Food(id: 'f_230', name: 'Tee', createdAt: DateTime.now()),
    Food(id: 'f_231', name: 'Bier', createdAt: DateTime.now()),

    // Snacks
    Food(id: 'f_232', name: 'Chips', createdAt: DateTime.now()),
    Food(id: 'f_233', name: 'Salzstangen', createdAt: DateTime.now()),
    Food(id: 'f_234', name: 'Nüsse', createdAt: DateTime.now()),
    Food(id: 'f_235', name: 'Kekse', createdAt: DateTime.now()),
    Food(id: 'f_236', name: 'Gummibärchen', createdAt: DateTime.now()),
    Food(id: 'f_237', name: 'Popcorn', createdAt: DateTime.now()),
    Food(id: 'f_238', name: 'Tortilla-Chips', createdAt: DateTime.now()),

    // Sonstiges
    Food(id: 'f_239', name: 'Paniermehl', createdAt: DateTime.now()),
    Food(id: 'f_240', name: 'Semmelbrösel', createdAt: DateTime.now()),
    Food(id: 'f_241', name: 'Backpapier', createdAt: DateTime.now()),
    Food(id: 'f_242', name: 'Alufolie', createdAt: DateTime.now()),
    Food(id: 'f_243', name: 'Küchenrolle', createdAt: DateTime.now()),
    Food(id: 'f_244', name: 'Mülltüten', createdAt: DateTime.now()),
    Food(id: 'f_245', name: 'Spülmittel', createdAt: DateTime.now()),
  ];

  // Household-scoped mock storage for offline / testing
  static final Map<String, List<Food>> _householdMockFoods = {};

  static List<Food> _createDefaultFoodsForHousehold(String householdId) {
    return defaultFoods.map((f) {
      return Food(
        id: '${f.id}_$householdId',
        householdId: householdId,
        name: f.name,
        note: f.note,
        defaultUnit: f.defaultUnit,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  /// Seeds the standard food catalogue for a newly created household.
  /// Returns a map of lowercased food name -> newly created food ID.
  Future<Map<String, String>> seedDefaultFoodsForHousehold(
    String householdId,
  ) async {
    final Map<String, String> nameToIdMap = {};

    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      final seeded = _householdMockFoods.putIfAbsent(
        householdId,
        () => _createDefaultFoodsForHousehold(householdId),
      );
      for (final f in seeded) {
        nameToIdMap[f.name.trim().toLowerCase()] = f.id;
      }
      return nameToIdMap;
    }

    try {
      final foodsToInsert = defaultFoods.map((f) {
        return {
          'household_id': householdId,
          'name': f.name,
          'note': f.note,
          'icon_key': f.iconKey,
          'default_unit': f.defaultUnit,
        };
      }).toList();

      // Insert in chunks of 50 to avoid request size limits
      const chunkSize = 50;
      for (var i = 0; i < foodsToInsert.length; i += chunkSize) {
        final chunk = foodsToInsert.sublist(
          i,
          (i + chunkSize > foodsToInsert.length)
              ? foodsToInsert.length
              : i + chunkSize,
        );
        final inserted = await _client
            .from('foods')
            .insert(chunk)
            .select('id, name');
        for (final row in inserted as List) {
          final id = row['id'] as String?;
          final name = row['name'] as String?;
          if (id != null && name != null) {
            nameToIdMap[name.trim().toLowerCase()] = id;
          }
        }
      }
      return nameToIdMap;
    } catch (e) {
      debugPrint('Error seeding default foods for household $householdId: $e');
      rethrow;
    }
  }

  Future<List<Food>> fetchFoods([String? householdId]) async {
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null && householdId.isNotEmpty) {
        return List<Food>.from(_householdMockFoods[householdId] ?? const []);
      }
      return List<Food>.from(defaultFoods);
    }

    try {
      if (householdId != null && householdId.isNotEmpty) {
        // Only household-owned foods belong in this catalogue. Legacy global
        // rows must not fill gaps after a user deletes or renames a seed item.
        final data = await _client
            .from('foods')
            .select()
            .eq('household_id', householdId)
            .order('name', ascending: true);

        return (data as List).map((f) => Food.fromJson(f)).toList();
      }

      // Fallback query if no householdId specified
      final data = await _client
          .from('foods')
          .select()
          .order('name', ascending: true);

      return (data as List).map((f) => Food.fromJson(f)).toList();
    } catch (e) {
      debugPrint('Error fetching foods: $e');
      return [];
    }
  }

  Future<Food> addCustomFood({
    required String name,
    String? note,
    String? iconKey,
    String defaultUnit = '',
    String? householdId,
  }) async {
    final resolvedIconKey = FoodIconCatalog.normalizeKey(iconKey);
    if (!SupabaseConfig.isConfigured) {
      final newFood = Food(
        id: 'f_custom_${DateTime.now().millisecondsSinceEpoch}',
        householdId: householdId,
        name: name,
        note: note,
        iconKey: resolvedIconKey,
        defaultUnit: defaultUnit,
        createdAt: DateTime.now(),
      );
      if (householdId != null && householdId.isNotEmpty) {
        final list = _householdMockFoods.putIfAbsent(
          householdId,
          () => _createDefaultFoodsForHousehold(householdId),
        );
        list.insert(0, newFood);
      } else {
        defaultFoods.insert(0, newFood);
      }
      return newFood;
    }

    if (householdId != null && householdId.isNotEmpty) {
      try {
        final data = await _client
            .from('foods')
            .insert({
              'name': name,
              'note': note,
              'icon_key': resolvedIconKey,
              'default_unit': defaultUnit,
              'household_id': householdId,
            })
            .select()
            .single();

        return Food.fromJson(data);
      } catch (e) {
        debugPrint('Food insert error: $e');
        final raw = e.toString().replaceFirst('Exception: ', '');
        if (raw.contains('duplicate') ||
            raw.contains('23505') ||
            raw.contains('already exists')) {
          throw Exception(
            'Dieses Lebensmittel mit dieser Notiz gibt es bereits.',
          );
        }
        throw Exception('Fehler beim Speichern: $raw');
      }
    }

    // Standard insert without household_id
    try {
      final data = await _client
          .from('foods')
          .insert({
            'name': name,
            'note': note,
            'icon_key': resolvedIconKey,
            'default_unit': defaultUnit,
          })
          .select()
          .single();

      return Food.fromJson(data);
    } catch (innerError) {
      debugPrint('Food insert error: $innerError');
      final raw = innerError.toString().replaceFirst('Exception: ', '');
      if (raw.contains('duplicate') ||
          raw.contains('23505') ||
          raw.contains('already exists')) {
        throw Exception('Dieses Lebensmittel gibt es bereits.');
      }
      throw Exception('Fehler beim Speichern: $raw');
    }
  }

  Future<Food> updateFood({
    required String id,
    required String name,
    String? note,
    String? iconKey,
    String? householdId,
  }) async {
    final resolvedIconKey = iconKey == null
        ? null
        : FoodIconCatalog.normalizeKey(iconKey);
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null && _householdMockFoods.containsKey(householdId)) {
        final list = _householdMockFoods[householdId]!;
        final index = list.indexWhere((f) => f.id == id);
        final previous = index == -1 ? null : list[index];
        final updated = Food(
          id: id,
          householdId: householdId,
          name: name,
          note: note,
          iconKey: resolvedIconKey ?? previous?.iconKey,
          defaultUnit: '',
          createdAt: index != -1 ? list[index].createdAt : DateTime.now(),
        );
        if (index != -1) {
          list[index] = updated;
        } else {
          list.insert(0, updated);
        }
        return updated;
      }
      final index = defaultFoods.indexWhere((f) => f.id == id);
      final previous = index == -1 ? null : defaultFoods[index];
      final updated = Food(
        id: id,
        name: name,
        note: note,
        iconKey: resolvedIconKey ?? previous?.iconKey,
        defaultUnit: '',
        createdAt: index != -1 ? defaultFoods[index].createdAt : DateTime.now(),
      );
      if (index != -1) {
        defaultFoods[index] = updated;
      } else {
        defaultFoods.insert(0, updated);
      }
      return updated;
    }

    final values = <String, dynamic>{'name': name, 'note': note};
    if (resolvedIconKey != null) values['icon_key'] = resolvedIconKey;
    final data = await _client
        .from('foods')
        .update(values)
        .eq('id', id)
        .select()
        .single();

    return Food.fromJson(data);
  }

  Future<bool> isFoodInUse(String foodId) async {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }

    try {
      // 1. Check shopping_items
      final shoppingData = await _client
          .from('shopping_items')
          .select('id')
          .eq('food_id', foodId)
          .limit(1);
      if ((shoppingData as List).isNotEmpty) return true;

      // 2. Check dish_items
      final dishData = await _client
          .from('dish_items')
          .select('id')
          .eq('food_id', foodId)
          .limit(1);
      if ((dishData as List).isNotEmpty) return true;

      // 3. Check household_stock
      final stockData = await _client
          .from('household_stock')
          .select('food_id')
          .eq('food_id', foodId)
          .limit(1);
      if ((stockData as List).isNotEmpty) return true;

      return false;
    } catch (e) {
      debugPrint('Error checking food usage: $e');
      return true; // Fail safe
    }
  }

  Future<void> deleteFood(
    String foodId, {
    String? foodName,
    String? householdId,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null && _householdMockFoods.containsKey(householdId)) {
        _householdMockFoods[householdId]!.removeWhere((f) => f.id == foodId);
      }
      defaultFoods.removeWhere((f) => f.id == foodId);
      return;
    }

    try {
      // 1. Preserve shopping items: copy food name to custom_name if empty/null
      if (foodName != null && foodName.trim().isNotEmpty) {
        try {
          await _client
              .from('shopping_items')
              .update({'custom_name': foodName.trim()})
              .eq('food_id', foodId)
              .or('custom_name.is.null,custom_name.eq.');
        } catch (_) {}
      }

      // Set shopping_items.food_id to null
      try {
        await _client
            .from('shopping_items')
            .update({'food_id': null})
            .eq('food_id', foodId);
      } catch (_) {}

      // 2. Delete dish_items for this food (keeps the rest of the dish intact)
      try {
        await _client.from('dish_items').delete().eq('food_id', foodId);
      } catch (_) {}

      // 3. Delete household_stock entries for this food
      try {
        await _client.from('household_stock').delete().eq('food_id', foodId);
      } catch (_) {}

      // 4. Delete the food record completely from foods table
      await _client.from('foods').delete().eq('id', foodId);
    } catch (e) {
      debugPrint('Error deleting food: $e');
      // Direct fallback
      await _client.from('foods').delete().eq('id', foodId);
    }
  }
}
