import 'package:flutter/material.dart';

class CustomTextFaild extends StatefulWidget {
  final TextEditingController? textEditingController;
  final String? hintText;
  final IconData? iconData;
  final bool? isObscure;
  final bool? isEnabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextFaild({
    super.key,
    this.textEditingController,
    this.hintText,
    this.iconData,
    this.isObscure = true,
    this.isEnabled = true,
    this.keyboardType,
    this.validator,
  });

  @override
  State<CustomTextFaild> createState() => _CustomTextFaildState();
}

class _CustomTextFaildState extends State<CustomTextFaild> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: widget.textEditingController,
        enabled: widget.isEnabled,
        obscureText: widget.isObscure ?? false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(widget.iconData, color: Colors.orangeAccent),
          focusColor: Theme.of(context).primaryColor,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
