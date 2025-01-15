import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gap/gap.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  var formkey = GlobalKey<FormState>();
  var nameControl = TextEditingController();
  var emailControl = TextEditingController();
  var passControl = TextEditingController();
  var confPassControl = TextEditingController();
  bool passVisible = false;
  bool confPassVisible = false;

  void register() async {
    if (formkey.currentState!.validate()) {
      EasyLoading.show();
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailControl.text, password: passControl.text);
        var userId = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'username': nameControl.text,
          'email': emailControl.text,
          'type': 'user',
        });
        EasyLoading.dismiss();
        Navigator.pop(context);
      } on FirebaseException catch (error) {
        if (error.code == "email-already-in-use") {
          EasyLoading.showError("Email already used");
        } else {
          EasyLoading.showError("Account creation failed");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Form(
            key: formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/logo.png"),
                const Gap(20),
                TextFormField(
                  controller: emailControl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'X Required';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'X Invalid email format';
                    }
                    return null;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: nameControl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'X Required';
                    }
                    return null;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: passControl,
                  obscureText: !passVisible,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: const TextStyle(color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          passVisible = !passVisible;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'X Required';
                    }
                    if (value.length < 6) {
                      return 'X Password must have 6 characters';
                    }
                    return null;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: confPassControl,
                  obscureText: !confPassVisible,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Confirm Password',
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: const TextStyle(color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          confPassVisible = !confPassVisible;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'X Required';
                    }
                    if (value != passControl.text) {
                      return 'X Password does not match';
                    }
                    return null;
                  },
                ),
                const Gap(15),
                ElevatedButton(
                  onPressed: () {
                    register();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      width: 4,
                      color: Colors.white,
                    ),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
