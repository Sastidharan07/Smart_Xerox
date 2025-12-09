# TODO: Fix Flutter Analyze Warnings

## Overview
Fix 39 "info" level issues (warnings) in the Flutter app to clear all errors from `flutter analyze`. Issues include use_build_context_synchronously, deprecated_member_use (withOpacity), prefer_const_literals_to_create_immutables, and prefer_const_constructors.

## Steps to Complete

- [ ] Fix use_build_context_synchronously in lib/pages/auth_page.dart (lines 40, 46, 51)
- [ ] Fix deprecated_member_use (withOpacity) in lib/pages/auth_page.dart (lines 88, 90, 93, 122, 128, 141, 147)
- [ ] Fix use_build_context_synchronously in lib/pages/home_page.dart (line 41)
- [ ] Fix deprecated_member_use (withOpacity) in lib/pages/order_details_page.dart (lines 99, 102, 105)
- [ ] Fix use_build_context_synchronously in lib/pages/profile_page.dart (line 33)
- [ ] Fix deprecated_member_use (withOpacity) in lib/pages/profile_page.dart (lines 104, 106, 109)
- [ ] Fix use_build_context_synchronously in lib/pages/register_page.dart (lines 68, 74, 79)
- [ ] Fix deprecated_member_use (withOpacity) in lib/pages/register_page.dart (lines 109, 111, 216)
- [ ] Fix prefer_const_literals_to_create_immutables in lib/pages/register_page.dart (line 112)
- [ ] Fix prefer_const_constructors in lib/pages/register_page.dart (line 113)
- [ ] Fix use_build_context_synchronously in lib/pages/upload_order_page.dart (lines 71, 155, 158)
- [ ] Fix deprecated_member_use (withOpacity) in lib/pages/upload_order_page.dart (lines 225, 228, 250, 331, 332, 361, 363, 381, 415)

## Followup Steps
- [ ] Run `flutter analyze` again to confirm all issues are resolved
- [ ] Test the app to ensure functionality remains intact
