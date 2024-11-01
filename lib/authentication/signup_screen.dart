import 'dart:io';

import 'package:driver_app/pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../authentication/login_screen.dart';
import '../../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController vehicleModelTextEditingController = TextEditingController();
  TextEditingController vehicleColorTextEditingController = TextEditingController();
  TextEditingController vehicleNumberTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImages = "";

  checkIfNetworkIsAvailable() async
  {
    final isConnected = await cMethods.checkConnectivity(context);
    if (isConnected)
    {
      if (imageFile != null)
      {
        signUpFormValidation();
      }
      else
      {
        cMethods.displaySnackBar("Please choose an image first", context);
      }
    }
  }



  signUpFormValidation() {
    if (userNameTextEditingController.text.trim().length < 3)
    {
      cMethods.displaySnackBar("Your name must be at least 3 or more characters", context);
    }
    else if (userPhoneTextEditingController.text.trim().length < 8)
    {
      cMethods.displaySnackBar("Your phone number must be at least 8 or more characters", context);
    }
    else if (!emailTextEditingController.text.contains("@"))
    {
      cMethods.displaySnackBar("Please write your valid email", context);
    }
    else if (passwordTextEditingController.text.trim().length < 6)
    {
      cMethods.displaySnackBar("Your password must be at least 6 or more characters", context);
    }
    else if (vehicleModelTextEditingController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please write your Car Model", context);
    }
    else if (vehicleColorTextEditingController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please write your Car Model", context);
    }
    else if (vehicleNumberTextEditingController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please write your Car Model", context);
    }
    else
    {
      uploadImageToStorage();
    }
  }

  uploadImageToStorage() async
  {
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImages = FirebaseStorage.instance.ref().child("Images").child(imageIDName);
    UploadTask uploadTask = referenceImages.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    setState(()
    {
      urlOfUploadedImages = downloadUrl;
    });

    registerNewDriver();

  }

  registerNewDriver() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>  LoadingDialog(messageText: "Registering"),
    );

    try
    {
      final User? userFirebase = (
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailTextEditingController.text.trim(),
            password: passwordTextEditingController.text.trim(),
          )
      ).user;

      if (userFirebase != null)
      {
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);

        Map driverCarInfo =
        {
          "model": vehicleModelTextEditingController.text.trim(),
          "color": vehicleColorTextEditingController.text.trim(),
          "number": vehicleNumberTextEditingController.text.trim(),
        };

        Map driverDataMap =
        {
          "photo": urlOfUploadedImages,
          "vehicle_Details": driverCarInfo,
          "name": userNameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": userPhoneTextEditingController.text.trim(),
          "id": userFirebase.uid,
          "blockStatus": "no",
          "image": urlOfUploadedImages,
        };
        userRef.set(driverDataMap);

        if (!context.mounted) return;
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboard()));
      }
    }
    on FirebaseAuthException catch (error)
    {
      Navigator.pop(context);
      if (error.code == 'email-already-in-use')
      {
        cMethods.displaySnackBar("The email address is already in use by another account.", context);
      }
      else
      {
        cMethods.displaySnackBar(error.message.toString(), context);
      }
    } catch (error)
    {
      Navigator.pop(context);
      cMethods.displaySnackBar("An unexpected error occurred. Please try again.", context);
    }
  }

  chooseImageFromGallery() async
  {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null)
    {
      setState(()
      {
        imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              imageFile == null
                  ? const CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage("assets/images/driver_avater.png"),
              )
                  : Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(File(imageFile!.path)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: chooseImageFromGallery,
                child: const Text(
                  "Choose Image",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              buildTextField(
                controller: userNameTextEditingController,
                label: "Your Name",
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: userPhoneTextEditingController,
                label: "Your Phone",
                icon: Icons.phone,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: emailTextEditingController,
                label: "Your Email",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: passwordTextEditingController,
                label: "Your Password",
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: vehicleModelTextEditingController,
                label: "Your Car Model",
                icon: Icons.directions_car,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: vehicleColorTextEditingController,
                label: "Your Car Color",
                icon: Icons.color_lens,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: vehicleNumberTextEditingController,
                label: "Your Car Number",
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: checkIfNetworkIsAvailable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                child: const Text(
                  "Already have an Account? Login here",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 15,
      ),
    );
  }
}
