import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:manga_made_v2/components/mangaInfo.dart';

import 'package:manga_made_v2/screens/splashScreen.dart';

class FavoritesView extends StatefulWidget {
  FavoritesView({
    super.key,
  });

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  @override
  void initState() {
    super.initState();
    //checkFavorites();
  }

  var userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isFaveEmpty = true;

  void logout() {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const SplashScreenView(),
    ));
  }

  void checkFavorites() async {
    var favoritesCollection = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    if (favoritesCollection.size > 0) {
      isFaveEmpty = false;
      setState(() {});
    } else {
      print('Favorites collection is empty');
      isFaveEmpty = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Favorites",
          style: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 25,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 15,
          top: 20,
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('favorites')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_library_rounded,
                        size: 40,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Your Favorited Mangas Will Be Here.",
                        style: TextStyle(fontSize: 17),
                      )
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_library_rounded,
                        size: 40,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Your Favorited Mangas Will Be Here.",
                        style: TextStyle(fontSize: 17),
                      )
                    ],
                  ),
                );
              }

              var document = snapshot.data!.docs;
              return Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        "${document.length} Manga(s)",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Expanded(
                    child: GridView.builder(
                      itemCount: document.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 1 / 2.1,
                        crossAxisCount: 3,
                      ),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(
                          right: 15.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MangaInfoView(
                                  shouldOrder: true,

                                  mangaSnapshot: document[index],
                                  //BABALIKAN MOTO
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  document[index]['imageUrl'],
                                  fit: BoxFit.cover,
                                  height: 190,
                                  width: 120,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 6.0,
                                  top: 6,
                                ),
                                child: Text(
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  document[index]['name'].toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: Text(
                                  "${document[index]['chapters']} Chapters",
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }
}
