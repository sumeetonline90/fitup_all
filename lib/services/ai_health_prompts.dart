import '../features/mental_wellbeing/domain/entities/survey_severity.dart';
import '../features/mental_wellbeing/domain/entities/survey_type.dart';

import '../features/health/data/lab_metric_mapper.dart';

/// Shared core instruction block for all lab report parsing prompts.
/// Kept as a single function so vision and text paths stay in sync.
String _labCoreInstruction() {
  final String allowed = labReportAllowedVitalTypeNamesCsv();
  return '''
You are a medical lab report parser for a fitness app.
Extract ALL numeric lab measurements from the report.
Output a STRICT JSON array only — no markdown, no commentary.

Each element: {"type":"<enum>","value":<number>,"unit":"<string>","reference_range_mentioned":"<string or null>"}

RULES:
1. "type" MUST be one of: $allowed
2. Use each type AT MOST once. Pick the primary measurement, not derived ratios.
3. SKIP all ratio rows (TC/HDL, LDL/HDL, SGOT/SGPT, A/G, BUN/Creatinine, Trig/HDL, etc.).
4. SKIP Average Blood Glucose (ABG) — it is derived from HbA1c.
5. For lipids, use mg/dL. For thyroid, use the standard unit on the report.
6. No patient names, IDs, or dates. No diagnosis.

MAPPING (lab report name → type):
FBS/Fasting Blood Sugar/Fasting Plasma Glucose → fastingBloodSugar
HbA1c/Glycated Haemoglobin → hba1c
Total Cholesterol → totalCholesterol
HDL Cholesterol/HDL-Direct → hdlCholesterol
LDL Cholesterol/LDL-Direct → ldlCholesterol
Triglycerides → triglycerides
VLDL Cholesterol → vldlCholesterol
TSH/TSH-Ultrasensitive → tsh
T3/Total Triiodothyronine → t3
T4/Total Thyroxine → t4
25-OH Vitamin D/Vitamin D Total → vitaminD
Vitamin B-12/Vitamin B12 → vitaminB12
Iron/Serum Iron → serumIron
TIBC/Total Iron Binding Capacity → tibc
% Transferrin Saturation → transferrinSat
SGOT/AST/Aspartate Aminotransferase → sgot
SGPT/ALT/Alanine Transaminase → sgpt
GGT/Gamma Glutamyl Transferase → ggt
Alkaline Phosphatase/ALP → alkalinePhosphatase
Bilirubin Total → bilirubinTotal
Albumin-Serum/Serum Albumin → serumAlbumin
Creatinine-Serum/Serum Creatinine → serumCreatinine
Uric Acid → uricAcid
eGFR/Est. Glomerular Filtration Rate → egfr
BUN/Blood Urea Nitrogen → bun
Calcium → calcium
Hemoglobin/Hb → hemoglobin
Hematocrit/PCV → hematocrit
Total Leucocyte Count/WBC → wbcCount
Platelet Count → plateletCount
MCV/Mean Corpuscular Volume → mcv
Sodium → sodium
Chloride → chloride''';
}

/// Vision / multimodal prompt for lab reports (image or PDF).
String labReportVisionPrompt() {
  return '${_labCoreInstruction()}\n\n'
      'Read the attached file and extract ALL matching vitals.';
}

/// Text-only lab parse (after local PDF text extraction).
String labReportTextPrompt(String reportText) {
  final String body = reportText.trim();
  return '${_labCoreInstruction()}\n\n'
      'REPORT_TEXT:\n'
      '$body';
}

/// Supportive reflection — no raw survey answers or user ids.
String surveyInsightPrompt(SurveyType type, SurveySeverity severity) {
  final String t = type.name;
  final String s = severity.name;
  return 'A user completed a validated screening questionnaire ($t). '
      'Severity band (non-diagnostic label): $s. '
      'Write 2-3 short supportive sentences using hedging language only '
      '(e.g. "your responses may suggest", "you might consider"). '
      'Do not diagnose any condition. '
      'Always end with exactly: '
      '"Consider speaking with a mental health professional for personalized support."';
}

/// Structured context for holistic health coach (no userId).
String healthContextInsightPrompt({
  required String ageGroup,
  required String fitnessLevel,
  required String vitalsLines,
  required String medicationsLines,
  String bodyMetricsLines = '',
}) {
  final String bodyBlock = bodyMetricsLines.trim().isEmpty
      ? ''
      : '\nBody metrics (for context): $bodyMetricsLines\n';
  return 'You are a holistic health coach. Use hedging only — include suggestions '
      'phrased like "you may want to" and "consider" where appropriate. '
      'Never diagnose. This is not medical advice.\n'
      'User profile (anonymized): age group $ageGroup, fitness $fitnessLevel.'
      '$bodyBlock'
      'Recent vitals summary:\n$vitalsLines\n'
      'Active medications (names/doses sanitized):\n$medicationsLines\n'
      'Write 2-4 short paragraphs on patterns the user could discuss with a clinician.';
}

/// Snapshot text for mental wellbeing cross-module insight.
String mentalWellbeingCrossPrompt({
  required String moodLine,
  required String sleepLine,
  required String activityLine,
  required String surveyLine,
}) {
  return 'You are a wellbeing coach. Mood: $moodLine. Sleep: $sleepLine. '
      'Activity: $activityLine. Surveys: $surveyLine. '
      'Offer gentle habits (breathing, sleep hygiene, movement) using hedging only. '
      'Max 150 words. No diagnosis. No user identifiers.';
}
