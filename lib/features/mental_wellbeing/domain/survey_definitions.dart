/// PHQ-9 item text (informational; not a substitute for clinical administration).
class SurveyDefinitions {
  SurveyDefinitions._();

  static const List<String> phq9Questions = <String>[
    'Little interest or pleasure in doing things',
    'Feeling down, depressed, or hopeless',
    'Trouble falling or staying asleep, or sleeping too much',
    'Feeling tired or having little energy',
    'Poor appetite or overeating',
    'Feeling bad about yourself — or that you are a failure',
    'Trouble concentrating on things',
    'Moving or speaking slowly, or being fidgety/restless',
    'Thoughts that you would be better off dead or hurting yourself',
  ];

  static const List<String> gad7Questions = <String>[
    'Feeling nervous, anxious, or on edge',
    'Not being able to stop or control worrying',
    'Worrying too much about different things',
    'Trouble relaxing',
    'Being so restless that it is hard to sit still',
    'Becoming easily annoyed or irritable',
    'Feeling afraid as if something awful might happen',
  ];

  static const List<String> pss10Questions = <String>[
    'Upset by something unexpected',
    'Unable to control important things in life',
    'Felt nervous and stressed',
    'Confident in ability to handle personal problems (R)',
    'Things going your way (R)',
    'Could not cope with all the things you had to do',
    'Able to control irritations in life (R)',
    'On top of things (R)',
    'Angered because of things outside your control',
    'Difficulties piling up so high you could not overcome them',
  ];

  /// 0-based indices of PSS-10 items that are reverse-scored (0–4 → 4–raw).
  static const Set<int> pss10ReverseIndices = <int>{3, 4, 6, 7};
}
