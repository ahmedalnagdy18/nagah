import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTexts {
  AppTexts._();

  // Heading

  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      );

  static TextStyle heading(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      );

  static TextStyle subHeading(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      );

  // body

  static TextStyle regular(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 14.sp,
      );

  static TextStyle paragraph(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 12.sp,
      );
}
