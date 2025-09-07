// Value Notifier: hold the data 
//ValueListenableBuilder: listen to the data (dont need the setstate)

import 'package:flutter/material.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier isDarkModeNotifier = ValueNotifier(false);
ValueNotifier<String> userRoleNotifier = ValueNotifier('user'); // default role