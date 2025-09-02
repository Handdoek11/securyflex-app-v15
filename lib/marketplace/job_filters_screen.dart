import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'range_slider_view.dart';
import 'slider_view.dart';
import 'model/popular_filter_list.dart';
import 'state/job_state_manager.dart';

class JobFiltersScreen extends StatefulWidget {
  const JobFiltersScreen({super.key});

  @override
  State<JobFiltersScreen> createState() => _JobFiltersScreenState();
}

class _JobFiltersScreenState extends State<JobFiltersScreen> {
  // Following template pattern: use existing filter data structure
  List<PopularFilterListData> popularFilterListData =
      PopularFilterListData.popularFList;
  List<PopularFilterListData> jobTypeListData =
      PopularFilterListData.accomodationList;

  // Following template pattern: initialize from state manager
  RangeValues _values = JobStateManager.hourlyRateRange;
  double distValue = JobStateManager.maxDistance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: <Widget>[
              getAppBarUI(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    priceBarFilter(),
                    const Divider(
                      height: 1,
                    ),
                    popularFilter(),
                    const Divider(
                      height: 1,
                    ),
                    distanceViewUI(),
                    const Divider(
                      height: 1,
                    ),
                    allJobTypesUI()
                  ],
                ),
              ),
            ),
            const Divider(
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 16, top: 8),
              child: UnifiedButton.primary(
                text: 'Toepassen',
                onPressed: () {
                  // Following template pattern: update state manager before closing
                  JobStateManager.updateHourlyRateRange(_values);
                  JobStateManager.updateMaxDistance(distValue);
                  context.pop();
                },
                width: double.infinity,
                borderRadius: 24.0,
                backgroundColor: colorScheme.primary,
              ),
            )
            ],
          ),
        ),
      ),
    );
  }

  Widget allJobTypesUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            'Type opdracht',
            textAlign: TextAlign.left,
            style: TextStyle(
                color: DesignTokens.colorGray600,
                fontSize: MediaQuery.of(context).size.width > 360 ? DesignTokens.fontSizeTitle : DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightRegular,
                fontFamily: DesignTokens.fontFamily),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Column(
            children: getJobTypeListUI(),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }

  List<Widget> getJobTypeListUI() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final List<Widget> noList = <Widget>[];
    for (int i = 0; i < jobTypeListData.length; i++) {
      final PopularFilterListData date = jobTypeListData[i];
      noList.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
            onTap: () {
              setState(() {
                checkAppPosition(i);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      date.titleTxt,
                      style: TextStyle(color: DesignTokens.colorBlack),
                    ),
                  ),
                  CupertinoSwitch(
                    activeTrackColor: date.isSelected
                        ? colorScheme.primary
                        : DesignTokens.colorGray600,
                    onChanged: (bool value) {
                      setState(() {
                        checkAppPosition(i);
                      });
                    },
                    value: date.isSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (i == 0) {
        noList.add(const Divider(
          height: 1,
        ));
      }
    }
    return noList;
  }

  void checkAppPosition(int index) {
    if (index == 0) {
      if (jobTypeListData[0].isSelected) {
        for (var d in jobTypeListData) {
          d.isSelected = false;
        }
      } else {
        for (var d in jobTypeListData) {
          d.isSelected = true;
        }
      }
    } else {
      jobTypeListData[index].isSelected =
          !jobTypeListData[index].isSelected;

      int count = 0;
      for (int i = 0; i < jobTypeListData.length; i++) {
        if (i != 0) {
          final PopularFilterListData data = jobTypeListData[i];
          if (data.isSelected) {
            count += 1;
          }
        }
      }

      if (count == jobTypeListData.length - 1) {
        jobTypeListData[0].isSelected = true;
      } else {
        jobTypeListData[0].isSelected = false;
      }
    }
  }

  Widget distanceViewUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            'Afstand van locatie',
            textAlign: TextAlign.left,
            style: TextStyle(
                color: DesignTokens.colorGray600,
                fontSize: MediaQuery.of(context).size.width > 360 ? DesignTokens.fontSizeTitle : DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightRegular,
                fontFamily: DesignTokens.fontFamily),
          ),
        ),
        SliderView(
          distValue: distValue,
          onChangedistValue: (double value) {
            distValue = value;
          },
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }

  Widget popularFilter() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
          child: Text(
            'Vereiste certificaten',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: DesignTokens.fontSizeBodyLarge,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Column(
            children: getPList(),
          ),
        ),
        const SizedBox(
          height: 8,
        )
      ],
    );
  }

  List<Widget> getPList() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final List<Widget> noList = <Widget>[];
    int count = 0;
    const int columnCount = 2;
    for (int i = 0; i < popularFilterListData.length / columnCount; i++) {
      final List<Widget> listUI = <Widget>[];
      for (int i = 0; i < columnCount; i++) {
        try {
          final PopularFilterListData date = popularFilterListData[count];
          listUI.add(Expanded(
            child: Row(
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    onTap: () {
                      setState(() {
                        date.isSelected = !date.isSelected;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingS),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            date.isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: date.isSelected
                                ? colorScheme.primary
                                : DesignTokens.colorGray600,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            date.titleTxt,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ));
          if (count < popularFilterListData.length - 1) {
            count += 1;
          } else {
            break;
          }
        } catch (e) {
          // TODO: Replace with proper logging if needed
        }
      }
      noList.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: listUI,
      ));
    }
    return noList;
  }

  Widget priceBarFilter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Uurloon (€)',
            textAlign: TextAlign.left,
            style: TextStyle(
                color: DesignTokens.colorGray600,
                fontSize: MediaQuery.of(context).size.width > 360 ? DesignTokens.fontSizeTitle : DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightRegular,
                fontFamily: DesignTokens.fontFamily),
          ),
        ),
        RangeSliderView(
          values: _values,
          onChangeRangeValues: (RangeValues values) {
            _values = values;
          },
        ),
        const SizedBox(
          height: 8,
        )
      ],
    );
  }

  Widget getAppBarUI() {
    return UnifiedHeader.simple(
      title: 'Filters',
      titleAlignment: TextAlign.center,
      userRole: UserRole.guard,
      leading: HeaderElements.actionButton(
        icon: Icons.close,
        onPressed: () {
          context.pop();
        },
        userRole: UserRole.guard,
      ),
    );
  }
}
