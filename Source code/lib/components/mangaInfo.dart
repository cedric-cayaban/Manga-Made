import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:manga_made_v2/components/chapterView.dart';

import 'package:manga_made_v2/screens/commentScreen.dart';

class MangaInfoView extends StatefulWidget {
  MangaInfoView({
    Key? key,
    required this.mangaSnapshot,
    required this.shouldOrder,
  }) : super(key: key);

  QueryDocumentSnapshot<Map<String, dynamic>> mangaSnapshot;

  bool shouldOrder;

  @override
  State<MangaInfoView> createState() => _MangaInfoViewState();
}

class _MangaInfoViewState extends State<MangaInfoView> {
  @override
  void initState() {
    super.initState();
    fetchMangaData();
    getFave();
    getRating();
  }

  String genre = '';
  final amountFormat = NumberFormat.currency(
    customPattern: "₱ #,##0.00",
  );
  int quantity = 1;
  int userRating = 0;
  var stream;
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var mangaData;
  late double totalItemPrice;
  late QuerySnapshot<Map<String, dynamic>> data;
  late bool isFave = false;
  late bool ratingExists;
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

  void getFave() async {
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

  //BABALIKAN
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

  void setRating(int rating) async {
    try {
      var mangaName = widget.mangaSnapshot.data()['name'];

      //CHECHECK KUNG EXISTING YUNG STORED NA RATING NG USER
      var userRating = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .doc(widget.mangaSnapshot.id);

      var userRatingSnapshot = await userRating.get();

      if (userRatingSnapshot.exists) {
        await userRating.update({'rating': rating});
      } else {
        await userRating.set({'rating': rating});
      }

      getRating();

      //CHINECHECK KUNG MAY NARETRIEVE NA SAME USER AND MANGA RATING
      var ratingCollection = FirebaseFirestore.instance.collection('ratings');
      var mangaRating = await ratingCollection
          .where('userId', isEqualTo: userId)
          .where('manga', isEqualTo: mangaName)
          .get();

      //PAG MERON UUPDATE
      if (mangaRating.docs.isNotEmpty) {
        var ratingDoc = mangaRating.docs.first.reference;
        await ratingDoc.update({'rating': rating});
      }
      //PAG WALA AADD BAGO
      else {
        await ratingCollection.add({
          'manga': mangaName,
          'rating': rating,
          'userId': userId,
        });
      }
    } catch (e) {}
  }

  void getRating() async {
    var mangaItem = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .doc(widget.mangaSnapshot.id)
        .get();

    if (mangaItem.exists) {
      var rating = mangaItem.data();
      if (rating != null) {
        ratingExists = true;
        userRating = rating['rating'];
      } else {
        ratingExists = false;
        userRating = 0;
      }
    } else {
      ratingExists = false;
      userRating = 0;
    }

    setState(() {});
  }

  
  @override
  Widget build(BuildContext context) {
    
    while (mangaData == null) {
      return Scaffold(
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.comment,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              CommentScreen(mangaName: mangaData['name']),
                        ));
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                  top: 15,
                ),
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
                    
                    Container(
                      height: 50,
                      width: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            5,
                            (index) => GestureDetector(
                                  onTap: () {
                                    setRating(index + 1);
                                    if (!ratingExists) {
                                      getRating();
                                    }
                                  },
                                  child: Icon(
                                    size: 22,
                                    index < userRating
                                        ? Icons.star
                                        : Icons.star_outline,
                                    color: Colors.yellowAccent,
                                  ),
                                )),
                      ),
                    ),
                  ],
                )),
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mangaData['author'].toString(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
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
                child: ListView.builder(
                  itemCount: mangaData['chapters'],
                  itemBuilder: (context, index) {
                    int chapterNumber =
                        chReversed ? mangaData['chapters'] - index : index + 1;

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
                                    index <= (mangaData['chapters'] - 4))
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChapterView(
                                          snapshotId: widget.mangaSnapshot.id,
                                          mangaIdentifier: mangaData['id'],
                                          genre: mangaData['genre'],
                                          chIdentifier:
                                              chapterNumber.toString(),
                                        ),
                                      ),
                                    ),
                            child: ListTile(
                              textColor: Colors.white,
                              title: Text("Chapter $chapterNumber"),
                              trailing: (index >= 3 &&
                                      index <= (mangaData['chapters'] - 4))
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
                ),
              ),
            ),
            Visibility(
              visible: widget.shouldOrder,
              child: Container(
                height: 80,
                width: double.infinity,
                color: const Color.fromARGB(48, 128, 127, 125),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          if (isFave) {
                            removeItem();
                          } else {
                            addItem();
                          }
                        },
                        icon: isFave
                            ? Icon(Icons.favorite)
                            : Icon(Icons.favorite_border),
                        label: const Text(
                          "Favorite",
                          style: TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.yellowAccent,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (BuildContext context, setState) {
                                    return SizedBox(
                                      height: 250,
                                      child: Scaffold(
                                        body: Padding(
                                          padding: const EdgeInsets.all(15),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black12,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border(),
                                                  ),
                                                  height: 160,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 12),
                                                    child: Row(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child: Image.network(
                                                            mangaData[
                                                                'imageUrl'],
                                                            fit: BoxFit.cover,
                                                            height: 130,
                                                            width: 100,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 20,
                                                                  left: 10),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 2,
                                                                mangaData[
                                                                        'name']
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    fontSize:
                                                                        17),
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              Text(
                                                                "${mangaData['chapters']} Chapters",
                                                              ),
                                                              const SizedBox(
                                                                height: 20,
                                                              ),
                                                              Text(
                                                                amountFormat.format(
                                                                    totalItemPrice),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        15.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, right: 8),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          onPressed: () {
                                                            reduceQuantity();
                                                            setState(() {});
                                                          },
                                                          icon: const Icon(
                                                            Icons
                                                                .remove_circle_outline,
                                                            color: Colors
                                                                .yellowAccent,
                                                          ),
                                                        ),
                                                        Text(
                                                          "$quantity",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 15),
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            addQuantity();
                                                            setState(() {});
                                                          },
                                                          icon: const Icon(
                                                            Icons
                                                                .add_circle_outline,
                                                            color: Colors
                                                                .yellowAccent,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          addCart();
                                                        });
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0)),
                                                          minimumSize:
                                                              const Size(
                                                                  125.0, 40.0),
                                                          backgroundColor: Colors
                                                              .yellowAccent),
                                                      child: const Text(
                                                        "Add to cart",
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              });
                        },
                        icon: const Icon(
                          Icons.shopping_bag,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          "Add to Cart",
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            minimumSize: const Size(180.0, 48.0),
                            backgroundColor: Colors.yellowAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
