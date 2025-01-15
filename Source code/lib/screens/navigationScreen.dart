import 'package:flutter/material.dart';
import 'package:manga_made_v2/components/cartView.dart';
import 'package:manga_made_v2/components/favoritesView.dart';
import 'package:manga_made_v2/components/homeView.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentPageIndex = 0;
  // tabs ng baba
  late List<Widget> tabs;

  @override
  void initState() {
    super.initState();
    tabs = [
      Catalog(), 
      FavoritesView(),
      const CartView(),
    ];
  }

  void goToFavorite() {
    setState(() {
      currentPageIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.yellowAccent,
        currentIndex: currentPageIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.book,
            ),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_cart,
            ),
            label: "Cart",
          ),
        ],
        onTap: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
      body: tabs[currentPageIndex],
    );
  }
}
