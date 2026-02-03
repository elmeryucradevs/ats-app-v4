// Firebase Cloud Messaging Service Worker
// Maneja notificaciones push en background para la web

importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Configuración de Firebase (debe coincidir con firebase_options.dart web)
firebase.initializeApp({
  apiKey: 'AIzaSyAHTKDvJPt8SsQM8QlblmdqIAofT3cF1v0',
  authDomain: 'atesur-app-v4.firebaseapp.com',
  projectId: 'atesur-app-v4',
  storageBucket: 'atesur-app-v4.firebasestorage.app',
  messagingSenderId: '860080885808',
  appId: '1:860080885808:web:fe43bfa8f7baa1aa389df5',
  measurementId: 'G-PCB7NF1VWL'
});

const messaging = firebase.messaging();

// Handler para mensajes en background
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);
  
  const notificationTitle = payload.notification?.title || 'ATESUR';
  const notificationOptions = {
    body: payload.notification?.body || 'Nueva notificación',
    icon: '/favicon.png',
    badge: '/favicon.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handler para clicks en notificaciones
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification);
  
  event.notification.close();
  
  // Abrir la app o traerla al frente
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Si la app ya está abierta, enfocarla
        for (const client of clientList) {
          if (client.url === '/' && 'focus' in client) {
            return client.focus();
          }
        }
        // Si no está abierta, abrirla
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      })
  );
});
