import '../../../../services/models/extracted_vital.dart';

import '../domain/entities/vital_entry.dart';
import '../domain/entities/vital_source.dart';
import '../domain/entities/vital_type.dart';
import '../domain/entities/vital_type_extension.dart';

/// Returns true if [t] may appear on a typical lab report (excludes derived +
/// wearable-only vitals the model should not invent from labs).
bool isLabReportableVitalType(VitalType t) {
  if (t.isDerived) {
    return false;
  }
  return switch (t) {
    VitalType.heartRate ||
    VitalType.spO2 ||
    VitalType.hrv ||
    VitalType.bodyWeight ||
    VitalType.heightCm ||
    VitalType.bmi ||
    VitalType.bodyTemperature => false,
    _ => true,
  };
}

/// [VitalType.name] strings allowed in strict lab JSON (`type` key).
List<String> labReportableVitalTypeNames() => VitalType.values
    .where(isLabReportableVitalType)
    .map((VitalType v) => v.name)
    .toList();

/// Comma-separated enum names for prompts (keeps token size reasonable).
String labReportAllowedVitalTypeNamesCsv() =>
    labReportableVitalTypeNames().join(', ');

/// Maps strict JSON `type` field (must match [VitalType.name]) to [VitalType].
VitalType? mapTypeEnumToVitalType(String raw) {
  final String n = raw.trim();
  for (final VitalType v in VitalType.values) {
    if (v.name == n) {
      return isLabReportableVitalType(v) ? v : null;
    }
  }
  return null;
}

/// Resolves [VitalType] from AI extraction (strict `type` first, then fuzzy name).
VitalType? mappedTypeFromExtracted(ExtractedVital extracted) {
  final String? key = extracted.typeKey;
  if (key != null && key.isNotEmpty) {
    final VitalType? t = mapTypeEnumToVitalType(key);
    if (t != null) {
      return t;
    }
  }
  return mapLabMetricToVitalType(extracted.metricName);
}

/// Maps OCR / model metric names to [VitalType].
VitalType? mapLabMetricToVitalType(String rawName) {
  final String n = rawName.toLowerCase().trim();
  final Map<String, VitalType> m = <String, VitalType>{
    'fasting blood sugar': VitalType.fastingBloodSugar,
    'fasting plasma glucose': VitalType.fastingBloodSugar,
    'fbs': VitalType.fastingBloodSugar,
    'fpg': VitalType.fastingBloodSugar,
    'hba1c': VitalType.hba1c,
    'glycated haemoglobin': VitalType.hba1c,
    'total cholesterol': VitalType.totalCholesterol,
    'serum cholesterol': VitalType.totalCholesterol,
    'hdl': VitalType.hdlCholesterol,
    'hdl cholesterol': VitalType.hdlCholesterol,
    'hdl-c': VitalType.hdlCholesterol,
    'ldl': VitalType.ldlCholesterol,
    'ldl cholesterol': VitalType.ldlCholesterol,
    'ldl-c': VitalType.ldlCholesterol,
    'triglycerides': VitalType.triglycerides,
    'tg': VitalType.triglycerides,
    'trig': VitalType.triglycerides,
    'vldl': VitalType.vldlCholesterol,
    'non-hdl': VitalType.nonHdlCholesterol,
    'tsh': VitalType.tsh,
    't3': VitalType.t3,
    't4': VitalType.t4,
    'vitamin d': VitalType.vitaminD,
    '25-oh vitamin d': VitalType.vitaminD,
    'vitamin b12': VitalType.vitaminB12,
    'b12': VitalType.vitaminB12,
    'serum iron': VitalType.serumIron,
    'iron': VitalType.serumIron,
    'tibc': VitalType.tibc,
    'transferrin saturation': VitalType.transferrinSat,
    'sgot': VitalType.sgot,
    'ast': VitalType.sgot,
    'sgpt': VitalType.sgpt,
    'alt': VitalType.sgpt,
    'ggt': VitalType.ggt,
    'alkaline phosphatase': VitalType.alkalinePhosphatase,
    'alp': VitalType.alkalinePhosphatase,
    'bilirubin total': VitalType.bilirubinTotal,
    'albumin': VitalType.serumAlbumin,
    'creatinine': VitalType.serumCreatinine,
    'uric acid': VitalType.uricAcid,
    'egfr': VitalType.egfr,
    'gfr': VitalType.egfr,
    'bun': VitalType.bun,
    'calcium': VitalType.calcium,
    'hemoglobin': VitalType.hemoglobin,
    'hb': VitalType.hemoglobin,
    'hematocrit': VitalType.hematocrit,
    'pcv': VitalType.hematocrit,
    'wbc': VitalType.wbcCount,
    'platelet': VitalType.plateletCount,
    'mcv': VitalType.mcv,
    'sodium': VitalType.sodium,
    'chloride': VitalType.chloride,
  };
  if (m.containsKey(n)) {
    return m[n];
  }
  for (final MapEntry<String, VitalType> e in m.entries) {
    if (n.contains(e.key)) {
      return e.value;
    }
  }
  return null;
}

VitalEntry? extractedToVitalEntry({
  required ExtractedVital extracted,
  required VitalType type,
  required String userId,
  required String entryId,
}) {
  if (type.isDerived) {
    return null;
  }
  return VitalEntry(
    id: entryId,
    userId: userId,
    type: type,
    value: extracted.value,
    unit: type.unit,
    recordedAt: DateTime.now(),
    source: VitalSource.labUpload,
    notes: extracted.referenceRangeMentioned,
  );
}
