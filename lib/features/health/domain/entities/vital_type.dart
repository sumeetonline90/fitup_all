// ignore_for_file: public_member_api_docs

/// Each [VitalType] maps to exactly one [VitalCategory] via [VitalTypeExtension].
enum VitalType {
  // Blood sugar (3)
  fastingBloodSugar,
  hba1c,
  avgBloodGlucose,

  // Lipids (7)
  totalCholesterol,
  hdlCholesterol,
  ldlCholesterol,
  triglycerides,
  vldlCholesterol,
  nonHdlCholesterol,
  tcHdlRatio,

  // Thyroid (3)
  tsh,
  t3,
  t4,

  // Vitamins & iron (5)
  vitaminD,
  vitaminB12,
  serumIron,
  tibc,
  transferrinSat,

  // Liver (6)
  sgot,
  sgpt,
  ggt,
  alkalinePhosphatase,
  bilirubinTotal,
  serumAlbumin,

  // Kidney (5)
  serumCreatinine,
  uricAcid,
  egfr,
  bun,
  calcium,

  // Blood count (5)
  hemoglobin,
  hematocrit,
  wbcCount,
  plateletCount,
  mcv,

  // Electrolytes (2)
  sodium,
  chloride,

  // Vitals & wearable (9)
  heartRate,
  bloodPressureSystolic,
  bloodPressureDiastolic,
  spO2,
  hrv,
  bodyWeight,
  heightCm,
  bmi,
  bodyTemperature,
}
