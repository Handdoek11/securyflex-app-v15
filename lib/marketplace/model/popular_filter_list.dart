class PopularFilterListData {
  PopularFilterListData({
    this.titleTxt = '',
    this.isSelected = false,
  });

  String titleTxt;
  bool isSelected;

  static List<PopularFilterListData> popularFList = <PopularFilterListData>[
    PopularFilterListData(
      titleTxt: 'BHV',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'VCA',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Beveiligingsdiploma A',
      isSelected: true,
    ),
    PopularFilterListData(
      titleTxt: 'Beveiligingsdiploma B',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Portier',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'PBSA',
      isSelected: false,
    ),
  ];

  static List<PopularFilterListData> accomodationList = [
    PopularFilterListData(
      titleTxt: 'Alle',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Objectbeveiliging',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Evenementbeveiliging',
      isSelected: true,
    ),
    PopularFilterListData(
      titleTxt: 'Persoonbeveiliging',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Winkelbeveiliging',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Horecabeveiliging',
      isSelected: false,
    ),
  ];
}
