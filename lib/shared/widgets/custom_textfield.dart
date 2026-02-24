import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
	final TextEditingController controller;
	final String label;
	final TextInputType keyboardType;
	final int maxLines;

	const CustomTextField({
		super.key,
		required this.controller,
		required this.label,
		this.keyboardType = TextInputType.text,
		this.maxLines = 1,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			keyboardType: keyboardType,
			maxLines: maxLines,
			decoration: InputDecoration(
				labelText: label,
				border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
			),
		);
	}
}

