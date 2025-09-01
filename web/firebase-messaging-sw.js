// Firebase Cloud Messaging Service Worker
// SecuryFlex - Nederlandse Security Marketplace Platform

importScripts('https://www.gstatic.com/firebasejs/9.15.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.15.0/firebase-messaging-compat.js');

// Firebase configuration - SecuryFlex Development
const firebaseConfig = {
  apiKey: "AIzaSyCBOvB4b_3RqeDREBbP3RIrf4Xt_6q2lCM",
  authDomain: "securyflex-dev.firebaseapp.com",
  projectId: "securyflex-dev",
  storageBucket: "securyflex-dev.firebasestorage.app",
  messagingSenderId: "1043280489748",
  appId: "1:1043280489748:web:f2d1e0549ab4a4f7486601",
  measurementId: "G-KQQK104EB5"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve Firebase Messaging object
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification?.title || 'SecuryFlex Notificatie';
  const notificationOptions = {
    body: payload.notification?.body || 'Je hebt een nieuwe notificatie ontvangen',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    actions: [
      {
        action: 'open',
        title: 'Bekijk',
        icon: '/icons/Icon-192.png'
      },
      {
        action: 'close',
        title: 'Sluiten'
      }
    ],
    requireInteraction: true,
    tag: payload.data?.type || 'default',
    renotify: true,
    vibrate: [100, 50, 100]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked: ', event);
  
  event.notification.close();
  
  if (event.action === 'open') {
    // Open the app
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Handle push events
self.addEventListener('push', (event) => {
  console.log('[firebase-messaging-sw.js] Push event received: ', event);
});

// Service worker install
self.addEventListener('install', (event) => {
  console.log('[firebase-messaging-sw.js] Service Worker installing');
  self.skipWaiting();
});

// Service worker activate
self.addEventListener('activate', (event) => {
  console.log('[firebase-messaging-sw.js] Service Worker activating');
  event.waitUntil(self.clients.claim());
});