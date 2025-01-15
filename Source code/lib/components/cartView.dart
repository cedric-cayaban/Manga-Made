import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:manga_made_v2/components/mangaInfo.dart';

import 'package:manga_made_v2/screens/splashScreen.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  _CartViewState() {
    PriceCalulator();
    //checkCart();
  }

  late double total = 0;
  final amountFormat = NumberFormat.currency(customPattern: "₱ #,##0.00");
  var userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isCartEmpty = true;

  void PriceCalulator() async {
    var cartCollection = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();
    var document = cartCollection.docs;
    for (int a = 0; a < cartCollection.size; a++) {
      total += double.parse(document[a]['total-Price'].toString());
    }
    setState(() {});
  }

  void logout() {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const SplashScreenView(),
    ));
  }

  void checkCart() async {
    var favoritesCollection = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    if (favoritesCollection.size > 0) {
      // may laman
      isCartEmpty = false;
      setState(() {});
    } else {
      // walang laman
      isCartEmpty = true;
      setState(() {});
    }
  }

  void removeCartItem(
      QueryDocumentSnapshot<Map<String, dynamic>> mangaSnapshot) async {
    var faveItem = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(mangaSnapshot.id)
        .get()
        .then((value) {
      total -= mangaSnapshot['total-Price'];
      setState(() {});
    });
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(mangaSnapshot.id)
        .delete();
  }

  void checkOutItems() async {
    var favoritesCollection = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    if (favoritesCollection.size < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          "Please select items first",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.grey.shade900,
      ));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Check out items?",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 10,
              ),
              const Text(
                "Total Price",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                amountFormat.format(total),
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("No"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Center(child: Text("Purchase Successful!")),
                      content: Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sentiment_satisfied_alt,
                              color: Colors.greenAccent,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  var userCart = FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('cart');
                  var querySnapshot = await userCart.get();
                  for (var doc in querySnapshot.docs) {
                    doc.reference.delete();
                  }
                  total = 0;
                  setState(() {});
                },
                child: const Text(
                  "Yes",
                )),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "My Cart",
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 40,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Your Items Will Be Here.",
                    style: TextStyle(fontSize: 17),
                  )
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 40,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Your Items Will Be Here.",
                    style: TextStyle(fontSize: 17),
                  )
                ],
              ),
            );
          }

          var document = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                  top: 20,
                ),
                child: Row(
                  children: [
                    Text(
                      "${document.length} Manga(s)",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: document.length,
                  itemBuilder: (context, index) => Dismissible(
                    background: const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                    key: Key(document[index]['name']),
                    onDismissed: (direction) {
                      removeCartItem(document[index]); 
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MangaInfoView(
                                shouldOrder: false,
                                mangaSnapshot: document[index],
                                
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black12,
                            border: Border(),
                          ),
                          height: 160,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    document[index]['imageUrl'],
                                    fit: BoxFit.cover,
                                    height: 130,
                                    width: 100,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 20, left: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        document[index]['name'].toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "${document[index]['quantity']} Items",
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        amountFormat.format(
                                            document[index]['total-Price']),
                                        style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 60,
                width: double.infinity,
                color: const Color.fromARGB(48, 128, 127, 125),
                child: Padding(
                  padding: const EdgeInsets.only(right: 15, left: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Subtotal:",
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              amountFormat.format(total),
                              style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.yellowAccent),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          checkOutItems();
                        },
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            minimumSize: const Size(125.0, 45.0),
                            backgroundColor: Colors.yellowAccent),
                        child: const Text(
                          "Check Out",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
