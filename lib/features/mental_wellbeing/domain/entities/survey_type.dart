enum SurveyType { phq9, gad7, pss10 }

/// Parses route segment e.g. `phq9` → [SurveyType.phq9].
SurveyType? surveyTypeFromParam(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  for (final SurveyType t in SurveyType.values) {
    if (t.name == raw) {
      return t;
    }
  }
  return null;
}

int surveyMaxScore(SurveyType type) => switch (type) {
  SurveyType.phq9 => 27,
  SurveyType.gad7 => 21,
  SurveyType.pss10 => 40,
};
