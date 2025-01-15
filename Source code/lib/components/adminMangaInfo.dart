import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manga_made_v2/screens/uploadChapters.dart';

class AdminMangaInfo extends StatefulWidget {
  AdminMangaInfo({
    Key? key,
    required this.mangaSnapshot,
  }) : super(key: key);

  QueryDocumentSnapshot<Map<String, dynamic>> mangaSnapshot;

  @override
  State<AdminMangaInfo> createState() => _MangaInfoViewState();
}

class _MangaInfoViewState extends State<AdminMangaInfo> {
  @override
  void initState() {
    super.initState();
    getFave();
    fetchMangaData();
  }

  String genre = '';
  final amountFormat = NumberFormat.currency(
    customPattern: "₱ #,##0.00",
  );
  int quantity = 1;

  var stream;
  var userId = FirebaseAuth.instance.currentUser!.uid;
  late QuerySnapshot<Map<String, dynamic>> data;
  late bool isFave = false;
  var mangaData;
  late double totalItemPrice;
  var formKey = GlobalKey<FormState>();
  var chapController = TextEditingController();
  bool chReversed = false;

  void fetchMangaData() async {
    await getManga();
    setState(() {});
  }

  Future<void> getManga() async {
    switch (widget.mangaSnapshot.data()['genre']) {
      case "Action":
        data = await FirebaseFirestore.instance
            .collection('Action Manga')
            .where('id', isEqualTo: widget.mangaSnapshot.data()['id'])
            .get();
        break;
      case "Romance":
        data = await FirebaseFirestore.instance
            .collection('Romance Manga')
            .where('id', isEqualTo: widget.mangaSnapshot.data()['id'])
            .get();
        break;
      case "Mystery":
        data = await FirebaseFirestore.instance
            .collection('Mystery Manga')
            .where('id', isEqualTo: widget.mangaSnapshot.data()['id'])
            .get();
        break;
    }
    var document = data.docs;
    mangaData = document[0].data();
    totalItemPrice = double.parse(mangaData['price'].toString());
  }

  Future<void> getFave() async {
    var faveItem = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.mangaSnapshot.id)
        .get();
    if (faveItem.exists) {
      isFave = true;
    } else {
      isFave = false;
    }
    setState(() {});
  }

  void addItem() async {
    var docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.mangaSnapshot.id)
        .get();

    if (docSnapshot.exists) {
      return;
    } else {
      getFave();
      Map<String, dynamic> mangaData = {
        'id': widget.mangaSnapshot.data()['id'],
        'name': widget.mangaSnapshot.data()['name'],
        'author': widget.mangaSnapshot.data()['author'],
        'genre': widget.mangaSnapshot.data()['genre'],
        'imageUrl': widget.mangaSnapshot.data()['imageUrl'],
        'coverUrl': widget.mangaSnapshot.data()['coverUrl'],
        'synopsis': widget.mangaSnapshot.data()['synopsis'],
        'chapters': widget.mangaSnapshot.data()['chapters'],
        'price': widget.mangaSnapshot.data()['price'],
        'total-Price': widget.mangaSnapshot.data()['total-Price'],
        'quantity': widget.mangaSnapshot.data()['quantity'],
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(widget.mangaSnapshot.id)
          .set(mangaData);
    }
  }

  void removeItem() {
    getFave();
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.mangaSnapshot.id)
        .delete();
  }

  void addQuantity() {
    setState(() {
      quantity++;
      double converted = double.parse(quantity.toString());
      totalItemPrice = (widget.mangaSnapshot.data()['price'] * converted);
    });
  }

  void reduceQuantity() {
    setState(() {
      if (quantity > 1) {
        quantity--;
        double converted = double.parse(quantity.toString());
        totalItemPrice = (widget.mangaSnapshot.data()['price'] * converted);
      }
    });
  }

  void addCart() async {
    var docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(widget.mangaSnapshot.id)
        .get();

    if (docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Manga is already in your cart. if you want to order again, you can remove your first order",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.grey.shade900,
        ),
      );
      return;
    } else {
      Map<String, dynamic> mangaData = {
        'id': widget.mangaSnapshot.data()['id'],
        'name': widget.mangaSnapshot.data()['name'],
        'author': widget.mangaSnapshot.data()['author'],
        'genre': widget.mangaSnapshot.data()['genre'],
        'imageUrl': widget.mangaSnapshot.data()['imageUrl'],
        'coverUrl': widget.mangaSnapshot.data()['coverUrl'],
        'synopsis': widget.mangaSnapshot.data()['synopsis'],
        'chapters': widget.mangaSnapshot.data()['chapters'],
        'price': widget.mangaSnapshot.data()['price'],
        'total-Price': totalItemPrice,
        'quantity': quantity,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(widget.mangaSnapshot.id)
          .set(mangaData);

      Navigator.pop(context);
    }
  }

  void newChapter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Chapter"),
        content: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: chapController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Chapter Number'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please fill up this field';
                    }

                    try {
                      double checker = double.parse(value);
                    } catch (e) {
                      return 'Input should be number';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UploadChapters(
                        isNewChapter: true,
                        mangaName: widget.mangaSnapshot.data()['name'],
                        genre: widget.mangaSnapshot.data()['genre'],
                        mangaId: widget.mangaSnapshot.id,
                        chapter: chapController.text),
                  ),
                );
              }
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mangaSnapshot.data()['genre']) {
      case "Action":
        stream = FirebaseFirestore.instance
            .collection('Action Manga')
            .where('id', isEqualTo: widget.mangaSnapshot.data()['id'])
            .snapshots();
        break;
      case "Romance":
        stream = FirebaseFirestore.instance
            .collection('Romance Manga')
            .where('id', isEqualTo: widget.mangaSnapshot.data()['id'])
            .snapshots();
        break;
      case "Mystery":
        stream = FirebaseFirestore.instance
            .collection('Mystery Manga')
            .where('id', isEqualTo: widget.mangaSnapshot.data()['id'])
            .snapshots();
        break;
    }
    while (mangaData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 210,
                  child: ClipRRect(
                    child: Image.network(
                      mangaData['coverUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mangaData['name'].toString(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      newChapter();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Upload",
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.yellowAccent),
                      foregroundColor: Colors.yellowAccent,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 5),
              child: Text(
                mangaData['author'].toString(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 10, right: 15),
              child: Text(
                mangaData['synopsis'],
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15, top: 20, bottom: 5, right: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "${mangaData['chapters']} Chapters",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            chReversed = !chReversed;
                            setState(() {});
                          },
                          icon: Icon(chReversed
                              ? Icons.arrow_upward
                              : Icons.arrow_downward))
                    ],
                  ),
                  Text(
                    amountFormat.format(mangaData['price']),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    // left: 15,
                    // right: 15,
                    ),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return (Center(child: Container()));
                      }

                      var chapterData = snapshot.data!.docs[0].data();
                      return ListView.builder(
                        itemCount: chapterData['chapters'],
                        itemBuilder: (context, index) {
                          int chapterNumber = chReversed
                              ? chapterData['chapters'] - index
                              : index + 1;

                          return Column(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: (index >= 3 &&
                                          index <=
                                              (chapterData['chapters'] - 4))
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  UploadChapters(
                                                isNewChapter: false,
                                                mangaName: widget.mangaSnapshot
                                                    .data()['name'],
                                                chapter: '$chapterNumber',
                                                genre: widget.mangaSnapshot
                                                    .data()['genre'],
                                                mangaId:
                                                    widget.mangaSnapshot.id,
                                              ),
                                            ),
                                          ),
                                  child: ListTile(
                                    textColor: Colors.white,
                                    title: Text("Chapter $chapterNumber"),
                                    trailing: (index >= 3 &&
                                            index <=
                                                (chapterData['chapters'] - 4))
                                        ? Icon(
                                            Icons.lock_outline,
                                            color: Colors.red.shade700,
                                          )
                                        : const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: Colors.greenAccent,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
