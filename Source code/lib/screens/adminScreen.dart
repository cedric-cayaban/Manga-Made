import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manga_made_v2/components/adminMangaInfo.dart';

import 'package:manga_made_v2/screens/splashScreen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  var categoryRef;
  var collection;

  void logout() {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const SplashScreenView(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manga Made",
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 35,
          ),
        ),
        automaticallyImplyLeading: false,
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
        padding: const EdgeInsets.only(top: 10, left: 10, right: 5, bottom: 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              categoriesCatalog("Action"),
              categoriesCatalog("Romance"),
              categoriesCatalog("Mystery"),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoriesCatalog(String category) {
    switch (category) {
      case "Action":
        categoryRef =
            FirebaseFirestore.instance.collection('Action Manga').snapshots();
        collection = 'Action Manga';
        break;
      case "Romance":
        categoryRef =
            FirebaseFirestore.instance.collection('Romance Manga').snapshots();
        collection = 'Romance Manga';
        break;
      case "Mystery":
        categoryRef =
            FirebaseFirestore.instance.collection('Mystery Manga').snapshots();
        collection = 'Mystery Manga';
        break;
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: categoryRef,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return (Center(child: Container()));
        }

        var document = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 6, top: 10),
              child: Text(
                category,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 275,
              child: ListView.builder(
                  itemCount: document.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 15.0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminMangaInfo(
                                mangaSnapshot: document[index],
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          height: 200,
                          width: 115,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  maxLines: 2,
                                  "${document[index]['name']}",
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
                    );
                  }),
            ),
          ],
        );
      },
    );
  }
}
