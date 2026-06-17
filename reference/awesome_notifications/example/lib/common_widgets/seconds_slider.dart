
import 'package:flutter/material.dart';

class SecondsSlider extends StatefulWidget {

  final double initialValue;
  final double minValue;
  final double maxValue;
  final int steps;

  final ValueChanged<double> onChanged;

  const SecondsSlider({
    Key? key,
    required this.onChanged,
    this.initialValue = 5,
    this.minValue = 5,
    this.maxValue = 60,
    this.steps = 5,
  }) : super(key: key);

  @override
  State<SecondsSlider> createState() => _SecondsSliderState();
}

class _SecondsSliderState extends State<SecondsSlider> {

  late double _currentValue;

  @override
  void initState() {
    _currentValue = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Slider.adaptive(
          thumbColor: Colors.deepPurple,
          inactiveColor: Colors.grey.withOpacity(0.2),
          activeColor: Colors.deepPurple,
          value: _currentValue,
          min: widget.minValue,
          max: widget.maxValue,
          divisions: widget.steps,
          label: 'Seconds to wait: $_currentValue s',
          onChanged: (newValue){
            _currentValue = newValue;
            widget.onChanged(_currentValue);
          })
    );
  }
}