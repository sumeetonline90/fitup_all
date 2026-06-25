import 'vital_type.dart';

/// Population reference ranges only (informational, not medical targets).
class VitalRangeInfo {
  const VitalRangeInfo({
    required this.type,
    required this.tiers,
    this.note,
  });

  final VitalType type;
  final List<VitalRangeTier> tiers;
  final String? note;
}

class VitalRangeTier {
  const VitalRangeTier({
    required this.label,
    required this.min,
    required this.max,
    required this.status,
  });

  final String label;
  final double? min;
  final double? max;
  final RangeStatus status;
}

enum RangeStatus {
  normal,
  borderline,
  elevated,
  low,
  critical,
}

/// Reference ranges from common lab panels + ADA / NCEP ATP III / AHA (informational).
class VitalReferenceRanges {
  VitalReferenceRanges._();

  static const Map<VitalType, VitalRangeInfo> _ranges =
      <VitalType, VitalRangeInfo>{
    VitalType.fastingBloodSugar: VitalRangeInfo(
      type: VitalType.fastingBloodSugar,
      note: 'Fasting (8–10 hrs) required. ADA Guidelines.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 70,
          max: 99,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Prediabetes',
          min: 100,
          max: 125,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Diabetes',
          min: 126,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.avgBloodGlucose: VitalRangeInfo(
      type: VitalType.avgBloodGlucose,
      note: 'Estimated from HbA1c (ADAG); informational only.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 70,
          max: 99,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Prediabetes',
          min: 100,
          max: 125,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Diabetes',
          min: 126,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.hba1c: VitalRangeInfo(
      type: VitalType.hba1c,
      note: 'ADA Guidelines.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 5.6,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Prediabetes',
          min: 5.7,
          max: 6.4,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Diabetes',
          min: 6.5,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.totalCholesterol: VitalRangeInfo(
      type: VitalType.totalCholesterol,
      note: '10–12 hrs fasting recommended.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Desirable',
          min: null,
          max: 199,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Borderline High',
          min: 200,
          max: 239,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 240,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.hdlCholesterol: VitalRangeInfo(
      type: VitalType.hdlCholesterol,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low (risk)',
          min: null,
          max: 39,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 40,
          max: 60,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Optimal',
          min: 61,
          max: null,
          status: RangeStatus.normal,
        ),
      ],
    ),
    VitalType.ldlCholesterol: VitalRangeInfo(
      type: VitalType.ldlCholesterol,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Optimal',
          min: null,
          max: 99,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Near Optimal',
          min: 100,
          max: 129,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Borderline High',
          min: 130,
          max: 159,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 160,
          max: 189,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Very High',
          min: 190,
          max: null,
          status: RangeStatus.critical,
        ),
      ],
    ),
    VitalType.triglycerides: VitalRangeInfo(
      type: VitalType.triglycerides,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 149,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Borderline High',
          min: 150,
          max: 199,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 200,
          max: 499,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Very High',
          min: 500,
          max: null,
          status: RangeStatus.critical,
        ),
      ],
    ),
    VitalType.vldlCholesterol: VitalRangeInfo(
      type: VitalType.vldlCholesterol,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 5,
          max: 40,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 41,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.nonHdlCholesterol: VitalRangeInfo(
      type: VitalType.nonHdlCholesterol,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Optimal',
          min: null,
          max: 159,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 160,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.tcHdlRatio: VitalRangeInfo(
      type: VitalType.tcHdlRatio,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Optimal',
          min: 3.0,
          max: 5.0,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Borderline High',
          min: 5.1,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.tsh: VitalRangeInfo(
      type: VitalType.tsh,
      note: 'Ultrasensitive TSH. C.M.I.A method.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 0.35,
          max: 4.94,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Low (Hyper)',
          min: null,
          max: 0.34,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'High (Hypo)',
          min: 4.95,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.t3: VitalRangeInfo(
      type: VitalType.t3,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 58,
          max: 159,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 57,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 160,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.t4: VitalRangeInfo(
      type: VitalType.t4,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 4.87,
          max: 11.72,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 4.86,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 11.73,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.vitaminD: VitalRangeInfo(
      type: VitalType.vitaminD,
      note: '25-OH Vitamin D Total. C.L.I.A method.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Deficient',
          min: null,
          max: 19.9,
          status: RangeStatus.critical,
        ),
        const VitalRangeTier(
          label: 'Insufficient',
          min: 20,
          max: 29.9,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Sufficient',
          min: 30,
          max: 100,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Toxic',
          min: 100.1,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.vitaminB12: VitalRangeInfo(
      type: VitalType.vitaminB12,
      note: 'Competitive Chemi Luminescent Immuno Assay.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Deficient',
          min: null,
          max: 210,
          status: RangeStatus.critical,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 211,
          max: 911,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 912,
          max: null,
          status: RangeStatus.borderline,
        ),
      ],
    ),
    VitalType.serumIron: VitalRangeInfo(
      type: VitalType.serumIron,
      note: 'Male range: 65–175. Female range: 50–170.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 64,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 65,
          max: 175,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 176,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.tibc: VitalRangeInfo(
      type: VitalType.tibc,
      note: 'Male: 225–535. Female: 215–535.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 225,
          max: 535,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 224,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 536,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.transferrinSat: VitalRangeInfo(
      type: VitalType.transferrinSat,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 13,
          max: 45,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 12,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 46,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.sgot: VitalRangeInfo(
      type: VitalType.sgot,
      note: 'AST. IFCC method without Pyridoxal Phosphate Activation.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 35,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 36,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.sgpt: VitalRangeInfo(
      type: VitalType.sgpt,
      note: 'ALT. IFCC method.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 45,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 46,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.ggt: VitalRangeInfo(
      type: VitalType.ggt,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 55,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 56,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.alkalinePhosphatase: VitalRangeInfo(
      type: VitalType.alkalinePhosphatase,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 44,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 45,
          max: 129,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 130,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.bilirubinTotal: VitalRangeInfo(
      type: VitalType.bilirubinTotal,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 0.3,
          max: 1.2,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 1.21,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.serumAlbumin: VitalRangeInfo(
      type: VitalType.serumAlbumin,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 3.19,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 3.2,
          max: 4.8,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 4.81,
          max: null,
          status: RangeStatus.borderline,
        ),
      ],
    ),
    VitalType.serumCreatinine: VitalRangeInfo(
      type: VitalType.serumCreatinine,
      note: 'Male: 0.72–1.18. Female: 0.55–1.02.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 0.72,
          max: 1.18,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 1.19,
          max: null,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 0.71,
          status: RangeStatus.low,
        ),
      ],
    ),
    VitalType.uricAcid: VitalRangeInfo(
      type: VitalType.uricAcid,
      note: 'Male: 4.2–7.3. Female: 2.6–6.0.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 4.2,
          max: 7.3,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 4.19,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 7.31,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.egfr: VitalRangeInfo(
      type: VitalType.egfr,
      note: 'CKD-EPI equation. Higher = better kidney function.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 90,
          max: null,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Mild Decrease',
          min: 60,
          max: 89,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Moderate Decrease',
          min: 30,
          max: 59,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Severe Decrease',
          min: null,
          max: 29,
          status: RangeStatus.critical,
        ),
      ],
    ),
    VitalType.bun: VitalRangeInfo(
      type: VitalType.bun,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: 7.94,
          max: 20.07,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 20.08,
          max: null,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 7.93,
          status: RangeStatus.low,
        ),
      ],
    ),
    VitalType.calcium: VitalRangeInfo(
      type: VitalType.calcium,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 8.79,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 8.8,
          max: 10.6,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 10.61,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.hemoglobin: VitalRangeInfo(
      type: VitalType.hemoglobin,
      note: 'Male: 13.0–17.0. Female: 12.0–15.0.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 12.9,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 13.0,
          max: 17.0,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 17.1,
          max: null,
          status: RangeStatus.borderline,
        ),
      ],
    ),
    VitalType.hematocrit: VitalRangeInfo(
      type: VitalType.hematocrit,
      note: 'Male: 40–50. Female: 36–46.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 39.9,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 40.0,
          max: 50.0,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 50.1,
          max: null,
          status: RangeStatus.borderline,
        ),
      ],
    ),
    VitalType.wbcCount: VitalRangeInfo(
      type: VitalType.wbcCount,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 3.99,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 4.0,
          max: 10.0,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 10.01,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.plateletCount: VitalRangeInfo(
      type: VitalType.plateletCount,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 149,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 150,
          max: 410,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 411,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.mcv: VitalRangeInfo(
      type: VitalType.mcv,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 82.9,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 83.0,
          max: 101.0,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 101.1,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.sodium: VitalRangeInfo(
      type: VitalType.sodium,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low (Hyponatremia)',
          min: null,
          max: 135,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 136,
          max: 145,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High (Hypernatremia)',
          min: 146,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.chloride: VitalRangeInfo(
      type: VitalType.chloride,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 97,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 98,
          max: 107,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High',
          min: 108,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.heartRate: VitalRangeInfo(
      type: VitalType.heartRate,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low (Bradycardia)',
          min: null,
          max: 59,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 60,
          max: 100,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'High (Tachycardia)',
          min: 101,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.bloodPressureSystolic: VitalRangeInfo(
      type: VitalType.bloodPressureSystolic,
      note: 'AHA Guidelines 2017.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 119,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Elevated',
          min: 120,
          max: 129,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Stage 1 High',
          min: 130,
          max: 139,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Stage 2 High',
          min: 140,
          max: null,
          status: RangeStatus.critical,
        ),
      ],
    ),
    VitalType.bloodPressureDiastolic: VitalRangeInfo(
      type: VitalType.bloodPressureDiastolic,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Normal',
          min: null,
          max: 79,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Stage 1 High',
          min: 80,
          max: 89,
          status: RangeStatus.elevated,
        ),
        const VitalRangeTier(
          label: 'Stage 2 High',
          min: 90,
          max: null,
          status: RangeStatus.critical,
        ),
      ],
    ),
    VitalType.spO2: VitalRangeInfo(
      type: VitalType.spO2,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Critical',
          min: null,
          max: 89,
          status: RangeStatus.critical,
        ),
        const VitalRangeTier(
          label: 'Low',
          min: 90,
          max: 94,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 95,
          max: 100,
          status: RangeStatus.normal,
        ),
      ],
    ),
    VitalType.hrv: VitalRangeInfo(
      type: VitalType.hrv,
      note: 'Typical resting HRV. Varies by age and fitness.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 19,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Average',
          min: 20,
          max: 65,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Good',
          min: 66,
          max: null,
          status: RangeStatus.normal,
        ),
      ],
    ),
    VitalType.bodyWeight: VitalRangeInfo(
      type: VitalType.bodyWeight,
      note: 'Track trends. Normal depends on height.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Tracked',
          min: 0,
          max: null,
          status: RangeStatus.normal,
        ),
      ],
    ),
    VitalType.heightCm: VitalRangeInfo(
      type: VitalType.heightCm,
      note: 'Standing height. Typical adult range varies widely.',
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Tracked',
          min: 0,
          max: null,
          status: RangeStatus.normal,
        ),
      ],
    ),
    VitalType.bmi: VitalRangeInfo(
      type: VitalType.bmi,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Underweight',
          min: null,
          max: 18.4,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 18.5,
          max: 24.9,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Overweight',
          min: 25.0,
          max: 29.9,
          status: RangeStatus.borderline,
        ),
        const VitalRangeTier(
          label: 'Obese',
          min: 30.0,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
    VitalType.bodyTemperature: VitalRangeInfo(
      type: VitalType.bodyTemperature,
      tiers: <VitalRangeTier>[
        const VitalRangeTier(
          label: 'Low',
          min: null,
          max: 36.0,
          status: RangeStatus.low,
        ),
        const VitalRangeTier(
          label: 'Normal',
          min: 36.1,
          max: 37.2,
          status: RangeStatus.normal,
        ),
        const VitalRangeTier(
          label: 'Fever',
          min: 37.3,
          max: null,
          status: RangeStatus.elevated,
        ),
      ],
    ),
  };

  static VitalRangeInfo? forType(VitalType type) => _ranges[type];

  static RangeStatus statusFor(VitalType type, double value) {
    final VitalRangeInfo? info = _ranges[type];
    if (info == null) {
      return RangeStatus.normal;
    }
    for (final VitalRangeTier tier in info.tiers) {
      final bool aboveMin = tier.min == null || value >= tier.min!;
      final bool belowMax = tier.max == null || value <= tier.max!;
      if (aboveMin && belowMax) {
        return tier.status;
      }
    }
    return RangeStatus.normal;
  }
}
