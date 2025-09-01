import 'package:flutter/material.dart';
import '../../beveiliger_agenda/screens/planning_main_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key, this.animationController});

  final AnimationController? animationController;
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return PlanningMainScreen(
      animationController: widget.animationController,
    );
  }
}
