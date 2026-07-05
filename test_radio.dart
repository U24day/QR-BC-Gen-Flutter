import 'package:flutter/material.dart';

Widget buildRadioGroup(int groupValue, void Function(int?) onChanged) {
  return RadioGroup<int>(
    groupValue: groupValue,
    onChanged: onChanged,
    child: const Column(
      children: [
        RadioListTile<int>(
          value: 1,
          title: Text('One'),
        ),
      ],
    ),
  );
}
