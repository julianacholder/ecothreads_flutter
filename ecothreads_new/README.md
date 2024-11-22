# ecothreads_new

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


#3ecothreads Backend with Firebase
This document outlines how Firebase integrates with the various screens of the ecothreads app, providing functionalities like authentication, database management, and image storage.
Firebase is  seamlessly integrated into the ecothreads app to provide a secure, scalable backend for user authentication, data management, and image storage. Each screen interacts with Firebase services to deliver a smooth and efficient user experience.

##Firebase Services Overview
Authentication:
ecothreads app uses Email/Password Authentication,  this authentication method allows users to sign up or log in to our application using their email address and a secure password.This will ensure that  only authenticated users can read/write their profile and donation data.
Firestore Database:Our app is implement to use a firestore an NOSQL database to manage  structured data for screens such  as user profiles, donations, and environmental impact statistics
Firebase Storages:Our app have screens that will require images to be store and uploaded to the database and due to that we chose firebasebase storage   for storing and retrieving large files, such as images, securely and efficientlyStores images, sample screens that include user profile photos and donation item images.The authentication ensure Users can only upload and view images associated with their account.


 ##Firebase Integration in different screens
Loading Screen:
 The firebase verifies the user's authentication state,Redirects authenticated users to their profile or unauthenticated users to the onboarding screen.

 Onboarding Screen:
This screen Introduces the app and its core features.and the firebase does not directly interact with it but Users proceed to login or sign-up.

 Sign-Up Screen:
This  allows users to create a new account.
 The Firebase ensures that  authentication is used to register users with their email and password.once the user is registered the firestore store their basic profile information e.g name,email


sign in Screen:
It  enables users to log into their accounts.The Firebase Role is Authentication: Firebase Authentication validates the email and password. It also handles secure sessions.

 Profile Screen:
Displays the user's profile details and their donation listings.Firestore fetches user profile details (e.g., name, bio, username from the users collection.Retrieves donation listings associated with the user from the donation collection.Firebase Storage:Loads the user's profile photo from Firebase Storage using the stored URL.

 Real-Time Chat (Messages):

The Firebase ensure that the conversation between two users is store
Message Subcollection: Each conversation document has a subcollection of messages, each message with details like sender, timestamp, and text content.


 Edit Profile Screen:
Allows users to update their profile details.Firestore updates user details e.g name, bio, username, location ,Firebase Storage upload the updated profile photo to Firebase Storage and update the corresponding URL in Firestore.

 Donation Screen:
Lets users donate clothes by uploading images and providing item details  e.g item name, description
Firebase Storage Upload donation item images and stores the URL in the Firestore document.


Settings Screen:
 Allows users to manage account settings.
Authentication Provides functionality for logging out users securely.
Firestore updates privacy settings or other preferences

## Environmental Impact Screen:
Displays user stats, achievements, and activity related to their donations.Firebase Role is to fetch user-specific environmental impact data e.g., total donations, carbon savings from the database and also retrieves leaderboard data to show the user's rank compared to others.




