import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ratting_test/views/favorite_view.dart';
import 'package:ratting_test/views/home_view.dart';
import 'package:ratting_test/views/search_view.dart';
import 'profile_view.dart';

class MainWrapper extends StatefulWidget {
  final String userName;
  const MainWrapper({Key? key, required this.userName}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  late String firstName;

  @override
  void initState() {
    super.initState();
    firstName = widget.userName;
  }

  // Saat profil diupdate, reload dari Firebase dan update state
  void updateProfileData(
    String newFirst,
    String newLast,
    String newEmail,
    String newPass,
  ) async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      firstName = user?.displayName ?? newFirst;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(userName: firstName),
      const SearchScreen(),
      const FavoriteScreen(),
      ProfileScreen(
        firstName: firstName,
        lastName: "",
        email: FirebaseAuth.instance.currentUser?.email ?? "",
        password: "",
        onProfileChanged: updateProfileData,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F005C).withOpacity(0.9),
          border: const Border(
            top: BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: "Favorite"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}