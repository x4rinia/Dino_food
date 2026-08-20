import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/food.dart';

class FoodService {
  SupabaseClient get _client => SupabaseConfig.client;

  // Fallback / default catalogue with 170+ common German household foods
  static final List<Food> defaultFoods = [
    // Gemüse
    Food(id: 'f_1', name: 'Tomaten', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_2', name: 'Cherrytomaten', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_3', name: 'Gurke', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_4', name: 'Paprika', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_5', name: 'Zwiebeln', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_6', name: 'Rote Zwiebeln', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_7', name: 'Frühlingszwiebeln', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_8', name: 'Knoblauch', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_9', name: 'Karotten', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_10', name: 'Brokkoli', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_11', name: 'Blumenkohl', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_12', name: 'Zucchini', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_13', name: 'Aubergine', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_14', name: 'Champignons', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_15', name: 'Lauch', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_16', name: 'Sellerie', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_17', name: 'Weißkohl', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_18', name: 'Rotkohl', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_19', name: 'Wirsing', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_20', name: 'Rosenkohl', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_21', name: 'Spinat', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_22', name: 'Feldsalat', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_23', name: 'Kopfsalat', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_24', name: 'Eisbergsalat', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_25', name: 'Rucola', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_26', name: 'Mais', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_27', name: 'Erbsen', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_28', name: 'Grüne Bohnen', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_29', name: 'Kidneybohnen', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_30', name: 'Kichererbsen', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_31', name: 'Linsen', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_32', name: 'Kürbis', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_33', name: 'Süßkartoffeln', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_34', name: 'Radieschen', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_35', name: 'Spargel', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_36', name: 'Rote Bete', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_37', name: 'Avocado', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_38', name: 'Ingwer', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_39', name: 'Peperoni', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_40', name: 'Chinakohl', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_41', name: 'Kohlrabi', category: 'Gemüse', createdAt: DateTime.now()),
    Food(id: 'f_42', name: 'Fenchel', category: 'Gemüse', createdAt: DateTime.now()),

    // Obst
    Food(id: 'f_43', name: 'Äpfel', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_44', name: 'Bananen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_45', name: 'Birnen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_46', name: 'Orangen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_47', name: 'Mandarinen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_48', name: 'Zitronen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_49', name: 'Limetten', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_50', name: 'Erdbeeren', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_51', name: 'Himbeeren', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_52', name: 'Heidelbeeren', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_53', name: 'Brombeeren', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_54', name: 'Weintrauben', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_55', name: 'Kirschen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_56', name: 'Pfirsiche', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_57', name: 'Nektarinen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_58', name: 'Pflaumen', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_59', name: 'Kiwi', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_60', name: 'Ananas', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_61', name: 'Mango', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_62', name: 'Wassermelone', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_63', name: 'Honigmelone', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_64', name: 'Grapefruit', category: 'Obst', createdAt: DateTime.now()),
    Food(id: 'f_65', name: 'Granatapfel', category: 'Obst', createdAt: DateTime.now()),

    // Kartoffeln
    Food(id: 'f_66', name: 'Kartoffeln', category: 'Kartoffeln', createdAt: DateTime.now()),
    Food(id: 'f_67', name: 'Kartoffelpüree', category: 'Kartoffeln', createdAt: DateTime.now()),
    Food(id: 'f_68', name: 'Kartoffelklöße', category: 'Kartoffeln', createdAt: DateTime.now()),
    Food(id: 'f_69', name: 'Schupfnudeln', category: 'Kartoffeln', createdAt: DateTime.now()),
    Food(id: 'f_70', name: 'Gnocchi', category: 'Kartoffeln', createdAt: DateTime.now()),

    // Fleisch
    Food(id: 'f_71', name: 'Hackfleisch', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_72', name: 'Rinderhackfleisch', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_73', name: 'Schweinehackfleisch', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_74', name: 'Hähnchenbrust', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_75', name: 'Hähnchenschenkel', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_76', name: 'Putenbrust', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_77', name: 'Schweineschnitzel', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_78', name: 'Schweinefilet', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_79', name: 'Rindfleisch', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_80', name: 'Rindersteak', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_81', name: 'Gulaschfleisch', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_82', name: 'Frikadellen', category: 'Fleisch', createdAt: DateTime.now()),
    Food(id: 'f_83', name: 'Suppenfleisch', category: 'Fleisch', createdAt: DateTime.now()),

    // Wurst
    Food(id: 'f_84', name: 'Kochschinken', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_85', name: 'Rohschinken', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_86', name: 'Salami', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_87', name: 'Fleischwurst', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_88', name: 'Bratwurst', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_89', name: 'Wiener Würstchen', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_90', name: 'Bacon', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_91', name: 'Aufschnitt', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_92', name: 'Leberkäse', category: 'Wurst', createdAt: DateTime.now()),
    Food(id: 'f_93', name: 'Schinkenwürfel', category: 'Wurst', createdAt: DateTime.now()),

    // Fisch
    Food(id: 'f_94', name: 'Lachs', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_95', name: 'Thunfisch', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_96', name: 'Thunfisch in Dose', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_97', name: 'Fischstäbchen', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_98', name: 'Seelachs', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_99', name: 'Garnelen', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_100', name: 'Forelle', category: 'Fisch', createdAt: DateTime.now()),
    Food(id: 'f_101', name: 'Kabeljau', category: 'Fisch', createdAt: DateTime.now()),

    // Milchprodukte
    Food(id: 'f_102', name: 'Milch', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_103', name: 'Hafermilch', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_104', name: 'Sahne', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_105', name: 'Kochsahne', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_106', name: 'Saure Sahne', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_107', name: 'Schmand', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_108', name: 'Joghurt', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_109', name: 'Naturjoghurt', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_110', name: 'Griechischer Joghurt', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_111', name: 'Quark', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_112', name: 'Butter', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_113', name: 'Margarine', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_114', name: 'Crème fraîche', category: 'Milchprodukte', createdAt: DateTime.now()),
    Food(id: 'f_115', name: 'Buttermilch', category: 'Milchprodukte', createdAt: DateTime.now()),

    // Käse
    Food(id: 'f_116', name: 'Käse', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_117', name: 'Gouda', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_118', name: 'Emmentaler', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_119', name: 'Mozzarella', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_120', name: 'Parmesan', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_121', name: 'Feta', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_122', name: 'Frischkäse', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_123', name: 'Scheibenkäse', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_124', name: 'Reibekäse', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_125', name: 'Camembert', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_126', name: 'Schafskäse', category: 'Käse', createdAt: DateTime.now()),
    Food(id: 'f_127', name: 'Halloumi', category: 'Käse', createdAt: DateTime.now()),

    // Eier
    Food(id: 'f_128', name: 'Eier', category: 'Eier', createdAt: DateTime.now()),

    // Brot & Backwaren
    Food(id: 'f_129', name: 'Brot', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_130', name: 'Toast', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_131', name: 'Brötchen', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_132', name: 'Baguette', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_133', name: 'Vollkornbrot', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_134', name: 'Knäckebrot', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_135', name: 'Wraps', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_136', name: 'Burgerbrötchen', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_137', name: 'Hot-Dog-Brötchen', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_138', name: 'Pizzateig', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_139', name: 'Blätterteig', category: 'Brot & Backwaren', createdAt: DateTime.now()),
    Food(id: 'f_140', name: 'Fladenbrot', category: 'Brot & Backwaren', createdAt: DateTime.now()),

    // Nudeln & Reis
    Food(id: 'f_141', name: 'Nudeln', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_142', name: 'Spaghetti', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_143', name: 'Penne', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_144', name: 'Fusilli', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_145', name: 'Makkaroni', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_146', name: 'Lasagneplatten', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_147', name: 'Tortellini', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_148', name: 'Reis', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_149', name: 'Basmatireis', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_150', name: 'Jasminreis', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_151', name: 'Risottoreis', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_152', name: 'Couscous', category: 'Nudeln & Reis', createdAt: DateTime.now()),
    Food(id: 'f_153', name: 'Bulgur', category: 'Nudeln & Reis', createdAt: DateTime.now()),

    // Konserven & Gläser
    Food(id: 'f_154', name: 'Passierte Tomaten', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_155', name: 'Gehackte Tomaten', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_156', name: 'Tomatenmark', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_157', name: 'Weiße Bohnen', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_158', name: 'Gewürzgurken', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_159', name: 'Apfelmus', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_160', name: 'Kokosmilch', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_161', name: 'Sauerkraut', category: 'Konserven & Gläser', createdAt: DateTime.now()),
    Food(id: 'f_162', name: 'Oliven', category: 'Konserven & Gläser', createdAt: DateTime.now()),

    // Tiefkühl
    Food(id: 'f_163', name: 'Tiefkühlpizza', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_164', name: 'Pommes', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_165', name: 'Kroketten', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_166', name: 'Tiefkühlgemüse', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_167', name: 'Tiefkühlbrokkoli', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_168', name: 'Tiefkühlspinat', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_169', name: 'Tiefkühlerbsen', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_170', name: 'Tiefkühlbeeren', category: 'Tiefkühl', createdAt: DateTime.now()),
    Food(id: 'f_171', name: 'Eis', category: 'Tiefkühl', createdAt: DateTime.now()),

    // Gewürze
    Food(id: 'f_172', name: 'Salz', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_173', name: 'Pfeffer', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_174', name: 'Paprikapulver', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_175', name: 'Curry', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_176', name: 'Knoblauchpulver', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_177', name: 'Zwiebelpulver', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_178', name: 'Oregano', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_179', name: 'Basilikum', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_180', name: 'Petersilie', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_181', name: 'Schnittlauch', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_182', name: 'Muskat', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_183', name: 'Chili', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_184', name: 'Kreuzkümmel', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_185', name: 'Rosmarin', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_186', name: 'Thymian', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_187', name: 'Zimt', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_188', name: 'Gemüsebrühe', category: 'Gewürze', createdAt: DateTime.now()),
    Food(id: 'f_189', name: 'Fleischbrühe', category: 'Gewürze', createdAt: DateTime.now()),

    // Saucen
    Food(id: 'f_190', name: 'Ketchup', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_191', name: 'Mayonnaise', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_192', name: 'Senf', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_193', name: 'BBQ-Sauce', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_194', name: 'Sojasauce', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_195', name: 'Sweet-Chili-Sauce', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_196', name: 'Currysauce', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_197', name: 'Tomatensauce', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_198', name: 'Pesto', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_199', name: 'Pesto Rosso', category: 'Saucen', createdAt: DateTime.now()),
    Food(id: 'f_200', name: 'Remoulade', category: 'Saucen', createdAt: DateTime.now()),

    // Öle & Fette
    Food(id: 'f_201', name: 'Olivenöl', category: 'Öle & Fette', createdAt: DateTime.now()),
    Food(id: 'f_202', name: 'Sonnenblumenöl', category: 'Öle & Fette', createdAt: DateTime.now()),
    Food(id: 'f_203', name: 'Rapsöl', category: 'Öle & Fette', createdAt: DateTime.now()),
    Food(id: 'f_204', name: 'Essig', category: 'Öle & Fette', createdAt: DateTime.now()),
    Food(id: 'f_205', name: 'Balsamico-Essig', category: 'Öle & Fette', createdAt: DateTime.now()),

    // Frühstück
    Food(id: 'f_206', name: 'Haferflocken', category: 'Frühstück', createdAt: DateTime.now()),
    Food(id: 'f_207', name: 'Cornflakes', category: 'Frühstück', createdAt: DateTime.now()),
    Food(id: 'f_208', name: 'Müsli', category: 'Frühstück', createdAt: DateTime.now()),
    Food(id: 'f_209', name: 'Marmelade', category: 'Frühstück', createdAt: DateTime.now()),
    Food(id: 'f_210', name: 'Honig', category: 'Frühstück', createdAt: DateTime.now()),
    Food(id: 'f_211', name: 'Nutella', category: 'Frühstück', createdAt: DateTime.now()),
    Food(id: 'f_212', name: 'Erdnussbutter', category: 'Frühstück', createdAt: DateTime.now()),

    // Backen
    Food(id: 'f_213', name: 'Mehl', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_214', name: 'Zucker', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_215', name: 'Puderzucker', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_216', name: 'Backpulver', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_217', name: 'Vanillezucker', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_218', name: 'Kakao', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_219', name: 'Schokolade', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_220', name: 'Kuvertüre', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_221', name: 'Hefe', category: 'Backen', createdAt: DateTime.now()),
    Food(id: 'f_222', name: 'Speisestärke', category: 'Backen', createdAt: DateTime.now()),

    // Getränke
    Food(id: 'f_223', name: 'Wasser', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_224', name: 'Mineralwasser', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_225', name: 'Cola', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_226', name: 'Limonade', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_227', name: 'Orangensaft', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_228', name: 'Apfelsaft', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_229', name: 'Kaffee', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_230', name: 'Tee', category: 'Getränke', createdAt: DateTime.now()),
    Food(id: 'f_231', name: 'Bier', category: 'Getränke', createdAt: DateTime.now()),

    // Snacks
    Food(id: 'f_232', name: 'Chips', category: 'Snacks', createdAt: DateTime.now()),
    Food(id: 'f_233', name: 'Salzstangen', category: 'Snacks', createdAt: DateTime.now()),
    Food(id: 'f_234', name: 'Nüsse', category: 'Snacks', createdAt: DateTime.now()),
    Food(id: 'f_235', name: 'Kekse', category: 'Snacks', createdAt: DateTime.now()),
    Food(id: 'f_236', name: 'Gummibärchen', category: 'Snacks', createdAt: DateTime.now()),
    Food(id: 'f_237', name: 'Popcorn', category: 'Snacks', createdAt: DateTime.now()),
    Food(id: 'f_238', name: 'Tortilla-Chips', category: 'Snacks', createdAt: DateTime.now()),

    // Sonstiges
    Food(id: 'f_239', name: 'Paniermehl', category: 'Sonstiges', createdAt: DateTime.now()),
    Food(id: 'f_240', name: 'Semmelbrösel', category: 'Sonstiges', createdAt: DateTime.now()),
    Food(id: 'f_241', name: 'Backpapier', category: 'Sonstiges', createdAt: DateTime.now()),
    Food(id: 'f_242', name: 'Alufolie', category: 'Sonstiges', createdAt: DateTime.now()),
    Food(id: 'f_243', name: 'Küchenrolle', category: 'Sonstiges', createdAt: DateTime.now()),
    Food(id: 'f_244', name: 'Mülltüten', category: 'Sonstiges', createdAt: DateTime.now()),
    Food(id: 'f_245', name: 'Spülmittel', category: 'Sonstiges', createdAt: DateTime.now()),
  ];

  // Household-scoped mock storage for offline / testing
  static final Map<String, List<Food>> _householdMockFoods = {};

  static List<Food> _createDefaultFoodsForHousehold(String householdId) {
    return defaultFoods.map((f) {
      return Food(
        id: '${f.id}_$householdId',
        householdId: householdId,
        name: f.name,
        category: f.category,
        defaultUnit: f.defaultUnit,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  /// Seeds the standard food catalogue for a newly created household.
  /// Returns a map of lowercased food name -> newly created food ID.
  Future<Map<String, String>> seedDefaultFoodsForHousehold(String householdId) async {
    final Map<String, String> nameToIdMap = {};

    if (!SupabaseConfig.isConfigured || householdId.isEmpty) {
      final seeded = _createDefaultFoodsForHousehold(householdId);
      _householdMockFoods[householdId] = seeded;
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
          'category': f.category,
          'default_unit': f.defaultUnit,
        };
      }).toList();

      // Insert in chunks of 50 to avoid request size limits
      const chunkSize = 50;
      for (var i = 0; i < foodsToInsert.length; i += chunkSize) {
        final chunk = foodsToInsert.sublist(
          i,
          (i + chunkSize > foodsToInsert.length) ? foodsToInsert.length : i + chunkSize,
        );
        final inserted = await _client.from('foods').insert(chunk).select('id, name');
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
      // Fallback for mock/test
      final seeded = _createDefaultFoodsForHousehold(householdId);
      _householdMockFoods[householdId] = seeded;
      for (final f in seeded) {
        nameToIdMap[f.name.trim().toLowerCase()] = f.id;
      }
      return nameToIdMap;
    }
  }

  Future<List<Food>> fetchFoods([String? householdId]) async {
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null && householdId.isNotEmpty) {
        if (_householdMockFoods.containsKey(householdId)) {
          return List<Food>.from(_householdMockFoods[householdId]!);
        }
        final initial = _createDefaultFoodsForHousehold(householdId);
        _householdMockFoods[householdId] = initial;
        return List<Food>.from(initial);
      }
      return List<Food>.from(defaultFoods);
    }

    try {
      if (householdId != null && householdId.isNotEmpty) {
        // 1. Fetch household-specific foods
        final data = await _client
            .from('foods')
            .select()
            .eq('household_id', householdId)
            .order('name', ascending: true);

        final List<Food> items = (data as List).map((f) => Food.fromJson(f)).toList();

        // 2. Fetch any legacy global foods (household_id IS NULL)
        List<Food> legacyItems = [];
        try {
          final legacyData = await _client
              .from('foods')
              .select()
              .filter('household_id', 'is', 'null')
              .order('name', ascending: true);
          legacyItems = (legacyData as List).map((f) => Food.fromJson(f)).toList();
        } catch (_) {}

        if (items.isNotEmpty || legacyItems.isNotEmpty) {
          // Merge items with legacy items (household-specific foods take precedence by name)
          final Map<String, Food> mergedByName = {};
          for (final f in legacyItems) {
            mergedByName[f.name.trim().toLowerCase()] = f;
          }
          for (final f in items) {
            mergedByName[f.name.trim().toLowerCase()] = f;
          }
          final result = mergedByName.values.toList();
          result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return result;
        }

        // If no foods exist for this household, return empty list (never auto-seed on normal load)
        return [];
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
    String category = 'Sonstiges',
    String defaultUnit = '',
    String? householdId,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      final newFood = Food(
        id: 'f_custom_${DateTime.now().millisecondsSinceEpoch}',
        householdId: householdId,
        name: name,
        category: category,
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
              'category': category,
              'default_unit': defaultUnit,
              'household_id': householdId,
            })
            .select()
            .single();

        return Food.fromJson(data);
      } catch (e) {
        debugPrint('Insert with household_id failed, attempting standard insert: $e');
      }
    }

    // Standard insert without household_id
    try {
      final data = await _client
          .from('foods')
          .insert({
            'name': name,
            'category': category,
            'default_unit': defaultUnit,
          })
          .select()
          .single();

      return Food.fromJson(data);
    } catch (innerError) {
      debugPrint('Food insert error: $innerError');
      final raw = innerError.toString().replaceFirst('Exception: ', '');
      if (raw.contains('duplicate') || raw.contains('23505') || raw.contains('already exists')) {
        throw Exception('Dieses Lebensmittel gibt es bereits.');
      }
      throw Exception('Fehler beim Speichern: $raw');
    }
  }

  Future<Food> updateFood({
    required String id,
    required String name,
    required String category,
    String? householdId,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      if (householdId != null && _householdMockFoods.containsKey(householdId)) {
        final list = _householdMockFoods[householdId]!;
        final index = list.indexWhere((f) => f.id == id);
        final updated = Food(
          id: id,
          householdId: householdId,
          name: name,
          category: category,
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
      final updated = Food(
        id: id,
        name: name,
        category: category,
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

    final data = await _client
        .from('foods')
        .update({
          'name': name,
          'category': category,
        })
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

  Future<void> deleteFood(String foodId, {String? foodName, String? householdId}) async {
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
        await _client
            .from('dish_items')
            .delete()
            .eq('food_id', foodId);
      } catch (_) {}

      // 3. Delete household_stock entries for this food
      try {
        await _client
            .from('household_stock')
            .delete()
            .eq('food_id', foodId);
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
