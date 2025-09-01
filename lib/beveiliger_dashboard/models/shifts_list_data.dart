class ShiftsListData {
  ShiftsListData({
    this.imagePath = '',
    this.titleTxt = '',
    this.startColor = '',
    this.endColor = '',
    this.shifts,
    this.hours = 0,
    this.company = '',
    this.location = '',
    this.date = '',
    this.earnings = '',
    this.type = '',
  });

  String imagePath;
  String titleTxt;
  String startColor;
  String endColor;
  List<String>? shifts;
  int hours;
  String company;
  String location;
  String date;
  String earnings;
  String type;

  static List<ShiftsListData> tabIconsList = <ShiftsListData>[
    ShiftsListData(
      imagePath: 'assets/fitness_app/breakfast.png',
      titleTxt: 'Gisteren',
      company: 'VeiligPlus B.V.',
      location: 'Schiphol Airport',
      date: 'Gisteren',
      hours: 8,
      earnings: '€320',
      type: 'Persoonbeveiliging',
      shifts: <String>['Persoonbeveiliging', 'Schiphol Airport', '8 uur'],
      startColor: '#1E3A8A',
      endColor: '#3B82F6',
    ),
    ShiftsListData(
      imagePath: 'assets/fitness_app/lunch.png',
      titleTxt: '2 dagen geleden',
      company: 'SecureMax B.V.',
      location: 'RAI Amsterdam',
      date: '2 dagen geleden',
      hours: 6,
      earnings: '€240',
      type: 'Evenementbeveiliging',
      shifts: <String>['Evenementbeveiliging', 'RAI Amsterdam', '6 uur'],
      startColor: '#10B981',
      endColor: '#34D399',
    ),
    ShiftsListData(
      imagePath: 'assets/fitness_app/snack.png',
      titleTxt: '3 dagen geleden',
      company: 'GuardForce Nederland',
      location: 'Zaandam Centrum',
      date: '3 dagen geleden',
      hours: 10,
      earnings: '€400',
      type: 'Objectbeveiliging',
      shifts: <String>['Objectbeveiliging', 'Zaandam Centrum', '10 uur'],
      startColor: '#F59E0B',
      endColor: '#FBBF24',
    ),
    ShiftsListData(
      imagePath: 'assets/fitness_app/dinner.png',
      titleTxt: '4 dagen geleden',
      company: 'SecuriCorp B.V.',
      location: 'Utrecht CS',
      date: '4 dagen geleden',
      hours: 8,
      earnings: '€320',
      type: 'Stationsbeveiliging',
      shifts: <String>['Stationsbeveiliging', 'Utrecht CS', '8 uur'],
      startColor: '#8B5CF6',
      endColor: '#A78BFA',
    ),
  ];
}
