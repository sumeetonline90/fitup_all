import 'vital_category.dart';

extension VitalCategoryLabel on VitalCategory {
  String get chipLabel => switch (this) {
        VitalCategory.bloodSugar => 'Blood Sugar',
        VitalCategory.lipids => 'Lipids',
        VitalCategory.thyroid => 'Thyroid',
        VitalCategory.vitaminsAndIron => 'Vitamins & Iron',
        VitalCategory.liver => 'Liver',
        VitalCategory.kidney => 'Kidney',
        VitalCategory.bloodCount => 'Blood Count',
        VitalCategory.electrolytes => 'Electrolytes',
        VitalCategory.vitalsAndWearable => 'Vitals & Wearable',
      };
}
