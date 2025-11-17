// firebase.js - Firebase initialization using CDN modular SDK
// Add these script tags to pages that need Firebase (or to a base layout):
// <script type="module" src="/assets/js/firebase.js"></script>

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.13.1/firebase-app.js";
import { getAuth, onAuthStateChanged, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut, updateProfile } from "https://www.gstatic.com/firebasejs/10.13.1/firebase-auth.js";
import { getFirestore, doc, setDoc, getDoc, addDoc, collection, serverTimestamp } from "https://www.gstatic.com/firebasejs/10.13.1/firebase-firestore.js";

// TODO: Replace with your Firebase web app config
export const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID",
  measurementId: "YOUR_MEASUREMENT_ID"
};

// Initialize Firebase
export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

// Helper: observe auth
export function observeAuthState(callback) {
  return onAuthStateChanged(auth, callback);
}

// Helper: sign up user and create profile doc
export async function signUpWithEmail({ email, password, displayName }) {
  const cred = await createUserWithEmailAndPassword(auth, email, password);
  if (displayName) {
    await updateProfile(cred.user, { displayName });
  }
  // Create user profile document
  await setDoc(doc(db, "users", cred.user.uid), {
    uid: cred.user.uid,
    email,
    displayName: cred.user.displayName || displayName || null,
    createdAt: serverTimestamp(),
  });
  return cred.user;
}

// Helper: sign in
export async function signInWithEmail({ email, password }) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  return cred.user;
}

// Helper: sign out
export function signOutUser() {
  return signOut(auth);
}

// Helper: save sample site data
export async function saveSiteEvent({ type, payload }) {
  return addDoc(collection(db, "site_events"), {
    type,
    payload,
    createdAt: serverTimestamp(),
    uid: auth.currentUser ? auth.currentUser.uid : null,
  });
}
