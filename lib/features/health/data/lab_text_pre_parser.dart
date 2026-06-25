import '../domain/entities/vital_type.dart';
import 'lab_metric_mapper.dart';

/// A locally-extracted numeric lab reading (no AI needed).
class LocalLabReading {
  const LocalLabReading({
    required this.type,
    required this.value,
    required this.unit,
  });

  final VitalType type;
  final double value;
  final String unit;
}

/// Regex-based pre-parser that extracts common lab values from plain text.
///
/// Works across Indian lab formats (Thyrocare, SRL, Metropolis, Dr Lal PathLabs,
/// Redcliffe, etc.) by matching well-known test name patterns followed by
/// numeric values. The parser is intentionally conservative — it skips
/// ambiguous matches rather than risk wrong mappings.
///
/// This is NOT a replacement for AI extraction. It is used to:
/// 1. Validate AI results (cross-check values).
/// 2. Fill gaps if AI missed something the regex caught.
/// 3. Provide instant local preview while AI processes.
List<LocalLabReading> preParseLabText(String text) {
  final List<LocalLabReading> results = <LocalLabReading>[];
  final Set<VitalType> seen = <VitalType>{};

  for (final _LabPattern p in _patterns) {
    final RegExpMatch? m = p.regex.firstMatch(text);
    if (m == null) continue;

    final String? rawVal = m.group(1);
    if (rawVal == null) continue;

    final double? value = double.tryParse(rawVal.replaceAll(',', '').trim());
    if (value == null || value <= 0) continue;

    if (seen.contains(p.type)) continue;
    if (!isLabReportableVitalType(p.type)) continue;

    seen.add(p.type);
    results.add(LocalLabReading(type: p.type, value: value, unit: p.unit));
  }

  return results;
}

class _LabPattern {
  const _LabPattern({
    required this.regex,
    required this.type,
    required this.unit,
  });

  final RegExp regex;
  final VitalType type;
  final String unit;
}

/// Pattern library — each regex is case-insensitive and captures the numeric
/// value in group [valueGroup]. Patterns are ordered from most specific to
/// least specific to avoid false positives.
final List<_LabPattern> _patterns = <_LabPattern>[
  // --- Blood sugar ---
  _LabPattern(
    regex: RegExp(
      r'FASTING\s+BLOOD\s+SUGAR\b.*?(\d+\.?\d*)\s*mg/dL',
      caseSensitive: false,
    ),
    type: VitalType.fastingBloodSugar,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(r'HbA1c\b.*?(\d+\.?\d*)\s*%', caseSensitive: false),
    type: VitalType.hba1c,
    unit: '%',
  ),

  // --- Lipids (match full name to avoid ratio confusion) ---
  _LabPattern(
    regex: RegExp(
      r'TOTAL\s+CHOLESTEROL\s+(?:PHOTOMETRY\s+)?(?:<\s*\d+\s+)?(?:mg/dL\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.totalCholesterol,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'HDL\s+CHOLESTEROL\s+[-–]?\s*DIRECT\s+(?:PHOTOMETRY\s+)?(?:\d+[-–]\d+\s+)?(?:mg/dL\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.hdlCholesterol,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'LDL\s+CHOLESTEROL\s+[-–]?\s*DIRECT\s+(?:PHOTOMETRY\s+)?(?:<\s*\d+\s+)?(?:mg/dL\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.ldlCholesterol,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'TRIGLYCERIDES\s+(?:PHOTOMETRY\s+)?(?:<\s*\d+\s+)?(?:mg/dL\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.triglycerides,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'VLDL\s+CHOLESTEROL\s+(?:CALCULATED\s+)?(?:\d+\s*[-–]\s*\d+\s+)?(?:mg/dL\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.vldlCholesterol,
    unit: 'mg/dL',
  ),

  // --- Thyroid ---
  _LabPattern(
    regex: RegExp(
      r'TSH\s+[-–]?\s*(?:ULTRASENSITIVE\s+)?(?:C\.?M\.?I\.?A\.?\s+)?(?:μIU/mL\s+)?(?:\d+\.?\d*[-–]\d+\.?\d*\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.tsh,
    unit: 'μIU/mL',
  ),
  _LabPattern(
    regex: RegExp(
      r'TOTAL\s+TRIIODOTHYRONINE\s+\(T3\)\s+(?:C\.?M\.?I\.?A\.?\s+)?(?:ng/dL\s+)?(?:\d+[-–]\d+\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.t3,
    unit: 'ng/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'TOTAL\s+THYROXINE\s+\(T4\)\s+(?:C\.?M\.?I\.?A\.?\s+)?(?:μg/dL\s+)?(?:\d+\.?\d*[-–]\d+\.?\d*\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.t4,
    unit: 'μg/dL',
  ),

  // --- Vitamins & Iron ---
  _LabPattern(
    regex: RegExp(
      r'25-OH\s+VITAMIN\s+D\b.*?(\d+\.?\d*)\s*(?:ng/mL)?',
      caseSensitive: false,
    ),
    type: VitalType.vitaminD,
    unit: 'ng/mL',
  ),
  _LabPattern(
    regex: RegExp(
      r'VITAMIN\s+B[-–]?12\b.*?(\d+\.?\d*)\s*(?:pg/mL)?',
      caseSensitive: false,
    ),
    type: VitalType.vitaminB12,
    unit: 'pg/mL',
  ),
  _LabPattern(
    regex: RegExp(
      r'\bIRON\s+(?:Male\s*:\s*\d+\s*[-–]\s*\d+.*?)?(\d+\.?\d*)\s*(?:PHOTOMETRY\s+)?(?:μg/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.serumIron,
    unit: 'μg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'TOTAL\s+IRON\s+BINDING\s+CAPACITY\b.*?(\d+\.?\d*)\s*(?:μg/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.tibc,
    unit: 'μg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'%?\s*TRANSFERRIN\s+SATURATION\b.*?(\d+\.?\d*)\s*%',
      caseSensitive: false,
    ),
    type: VitalType.transferrinSat,
    unit: '%',
  ),

  // --- Liver ---
  _LabPattern(
    regex: RegExp(
      r'ALKALINE\s+PHOSPHATASE\b.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.alkalinePhosphatase,
    unit: 'U/L',
  ),
  _LabPattern(
    regex: RegExp(
      r'BILIRUBIN\s*[-–]?\s*TOTAL\b.*?(\d+\.?\d*)\s*(?:mg/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.bilirubinTotal,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'GAMMA\s+GLUTAMYL\s+TRANSFERASE\b.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.ggt,
    unit: 'U/L',
  ),
  _LabPattern(
    regex: RegExp(
      r'ASPARTATE\s+AMINOTRANSFERASE\s*\(?\s*SGOT\b.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.sgot,
    unit: 'U/L',
  ),
  _LabPattern(
    regex: RegExp(
      r'ALANINE\s+TRANSAMINASE\s*\(?\s*SGPT\b.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.sgpt,
    unit: 'U/L',
  ),
  _LabPattern(
    regex: RegExp(
      r'ALBUMIN\s*[-–]?\s*SERUM\b.*?(\d+\.?\d*)\s*(?:gm?/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.serumAlbumin,
    unit: 'g/dL',
  ),

  // --- Kidney ---
  _LabPattern(
    regex: RegExp(
      r'CREATININE\s*[-–]?\s*SERUM\b.*?(\d+\.?\d*)\s*(?:mg/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.serumCreatinine,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'URIC\s+ACID\b.*?(\d+\.?\d*)\s*(?:mg/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.uricAcid,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'(?:EST\.?\s+)?GLOMERULAR\s+FILTRATION\s+RATE\b.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.egfr,
    unit: 'mL/min/1.73m²',
  ),
  _LabPattern(
    regex: RegExp(
      r'BLOOD\s+UREA\s+NITROGEN\s*\(?\s*BUN\b.*?(\d+\.?\d*)\s*(?:mg/dL)?',
      caseSensitive: false,
    ),
    type: VitalType.bun,
    unit: 'mg/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'\bCALCIUM\s+(?:PHOTOMETRY\s+)?(?:\d+\.?\d*[-–]\d+\.?\d*\s+)?(?:mg/dL\s+)?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.calcium,
    unit: 'mg/dL',
  ),

  // --- Blood count ---
  _LabPattern(
    regex: RegExp(
      r'\bHEMOGLOBIN\s+(?:SLS.*?\s+)?(?:g/dL\s+)?(\d+\.?\d*)\s+(?:\d+\.?\d*[-–]\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.hemoglobin,
    unit: 'g/dL',
  ),
  _LabPattern(
    regex: RegExp(
      r'Hematocrit\s+\(PCV\)\s+.*?(\d+\.?\d*)\s+\d+',
      caseSensitive: false,
    ),
    type: VitalType.hematocrit,
    unit: '%',
  ),
  _LabPattern(
    regex: RegExp(
      r'TOTAL\s+LEUCOCYTE\s+COUNT\s*\(?\s*WBC\b.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.wbcCount,
    unit: 'x10³/μL',
  ),
  _LabPattern(
    regex: RegExp(r'PLATELET\s+COUNT\b.*?(\d+\.?\d*)', caseSensitive: false),
    type: VitalType.plateletCount,
    unit: 'x10³/μL',
  ),
  _LabPattern(
    regex: RegExp(
      r'Mean\s+Corpuscular\s+Volume\s+\(MCV\)\s+.*?(\d+\.?\d*)',
      caseSensitive: false,
    ),
    type: VitalType.mcv,
    unit: 'fL',
  ),

  // --- Electrolytes ---
  _LabPattern(
    regex: RegExp(
      r'\bSODIUM\b.*?(\d+\.?\d*)\s*(?:mmol/L)?',
      caseSensitive: false,
    ),
    type: VitalType.sodium,
    unit: 'mmol/L',
  ),
  _LabPattern(
    regex: RegExp(
      r'\bCHLORIDE\b.*?(\d+\.?\d*)\s*(?:mmol/L)?',
      caseSensitive: false,
    ),
    type: VitalType.chloride,
    unit: 'mmol/L',
  ),
];
