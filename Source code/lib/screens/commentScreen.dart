import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

class CommentScreen extends StatefulWidget {
  CommentScreen({super.key, required this.mangaName});

  String mangaName;

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  @override
  void initState() {
    super.initState();
    checkComments();
    getUserData();
  }

  var userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isCommentEmpty = true;
  String uname = '';
  int totalComments = 0;

  var commentControl = TextEditingController();
  void checkComments() async {
    var commentsCollection = await FirebaseFirestore.instance
        .collection('comments')
        .where('manga', isEqualTo: widget.mangaName)
        .get();

    if (commentsCollection.size > 0) {
      isCommentEmpty = true;
      totalComments = commentsCollection.size;
      setState(() {});
    } else {
      // walang laman
      isCommentEmpty = false;
      setState(() {});
    }
  }

  void getUserData() async {
    var userCollection =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    var data = userCollection.data()!;
    uname = data['username'];
  }

  void postComment() async {
    FirebaseFirestore.instance.collection('comments').add({
      'manga': widget.mangaName,
      'content': commentControl.text,
      'username': uname,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      commentControl.clear();
    });
    setState(() {});
    //checkComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Comments",
          style: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('comments')
            .where('manga', isEqualTo: widget.mangaName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment,
                          size: 40,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Comments Will Be Here.",
                          style: TextStyle(fontSize: 17),
                        )
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 100,
                  width: double.maxFinite,
                  color: const Color.fromARGB(48, 128, 127, 125),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentControl,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your Comment here',
                            ),
                          ),
                        ),
                        const Gap(5),
                        IconButton(
                            onPressed: () {
                              postComment();
                            },
                            icon: const Icon(Icons.send))
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          var document = snapshot.data!.docs;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                  top: 20,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    Text(
                      "${document.length} Comments(s)",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: document.length,
                  itemBuilder: (context, index) {
                    var comment = document[index];
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, top: 20, bottom: 30, right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${comment['username']} says: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Gap(10),
                              Text(comment['content']),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                height: 100,
                width: double.maxFinite,
                color: const Color.fromARGB(48, 128, 127, 125),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentControl,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your Comment here',
                          ),
                        ),
                      ),
                      const Gap(5),
                      IconButton(
                          onPressed: () {
                            postComment();
                          },
                          icon: const Icon(Icons.send))
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
