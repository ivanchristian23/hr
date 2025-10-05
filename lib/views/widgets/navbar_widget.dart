import 'package:flutter/material.dart';
import 'package:test_project/data/notifiers.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder(
//       valueListenable:  selectedPageNotifier,
//       builder: (context, selectedpage, child) {
//         return  NavigationBar(
//           destinations: [
//             NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
//             NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
//           ],
//           onDestinationSelected: (int value) {
//             selectedPageNotifier.value = value;
//           },
//           selectedIndex: selectedpage,
//         );
//       },
//     );
//   }
// }
 @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userRoleNotifier,
      builder: (context, role, _) {
        final destinations = role == 'admin'
            ? [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.check), label: 'Approve'),
                NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
              ]
            : [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.add), label: 'Leave'),
                NavigationDestination(icon: Icon(Icons.receipt), label: 'Request Page'),
              ];

        return ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, _) {
            return NavigationBar(
              destinations: destinations,
              onDestinationSelected: (int index) {
                selectedPageNotifier.value = index;
              },
              selectedIndex: selectedPage,
            );
          },
        );
      },
    );
  }
}