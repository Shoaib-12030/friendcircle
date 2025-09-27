// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v9-compat and v9
// https://firebase.google.com/docs/web/setup#config-object
const firebaseConfig = {
  apiKey: "YOUR_API_KEY_HERE",
  authDomain: "friendcircle-3e3ee.firebaseapp.com",
  projectId: "friendcircle-3e3ee",
  storageBucket: "friendcircle-3e3ee.appspot.com",
  messagingSenderId: "162211746751",
  appId: "1:162211746751:android:b8cd16fccce927be65470a",
  measurementId: "G-XXXXXXXXXX"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);