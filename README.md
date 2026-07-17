<h1 align="center"> EPN 360 </h1>

Aplicación móvil y web desarrollada en Flutter para la comunidad de la Escuela Politécnica Nacional (EPN), que centraliza en un solo lugar la información de eventos, noticias institucionales y ubicación del campus.

## Objetivo de la aplicación

EPN 360 busca facilitar la vida universitaria dentro del campus de la Escuela Politécnica Nacional, ofreciendo a estudiantes, docentes y personal administrativo una herramienta única para:

- Enterarse de los eventos que se organizan dentro de la institución y su ubicación exacta.
- Mantenerse informados con las noticias oficiales publicadas por la EPN.
- Ubicarse dentro del campus mediante un mapa interactivo con rutas peatonales hacia edificios, eventos y puntos de interés (cafeterías, bibliotecas, parqueaderos, zonas verdes, etc.).

## Principales funcionalidades

### Gestión de eventos
- Creación, edición y listado de eventos institucionales.
- Asignación de ubicación a cada evento mediante selección directa en el mapa.
- Visualización de eventos agrupados por lugar, con imagen, fecha y descripción.

### Noticias
- Obtención automática de noticias desde el sitio web oficial de la EPN.
- Listado y vista de detalle de cada noticia.

### Mapa del campus
- Mapa interactivo del campus basado en OpenStreetMap.
- Ubicación en tiempo real del usuario dentro del campus.
- Cálculo y trazado de rutas peatonales hacia eventos y lugares, con seguimiento en vivo de la posición del usuario y aviso de llegada.
- Filtros por categoría (bloques/aulas, parqueaderos, cafeterías, bibliotecas, teatro/recreativo, zonas verdes).
- Registro de nuevos puntos de interés directamente desde el mapa.

### Autenticación y perfil
- Registro e inicio de sesión con correo y contraseña.
- Recuperación de contraseña.
- Gestión del perfil del usuario.

### Directorio
- Directorio institucional de contactos y dependencias.

## Consumo de APIs

La aplicación consume las siguientes APIs y servicios externos:

| Servicio | Uso dentro de la aplicación |
|---|---|
| OpenStreetMap (tiles) | Renderizado del mapa base del campus. |
| Nominatim (OpenStreetMap) | Geocodificación inversa: obtener la dirección legible a partir de coordenadas. |
| OSRM (OpenStreetMap.de, perfil peatonal) | Cálculo de rutas a pie entre la ubicación del usuario y un evento o lugar. |
| Sitio web de la EPN (`epn.edu.ec`) | Obtención de noticias institucionales mediante lectura del contenido público del sitio. En la versión web se utiliza un proxy intermedio para evitar restricciones del navegador (CORS). |
| Geolocalización del dispositivo | Obtención de la posición actual del usuario y seguimiento en tiempo real durante una ruta. |

## Tecnologías utilizadas

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Flutter Map
- OpenStreetMap
- Geolocator


## Uso de Firebase

El backend de la aplicación está construido sobre Firebase. Los servicios utilizados son:

- **Firebase Authentication**: registro, inicio de sesión, cierre de sesión y recuperación de contraseña de los usuarios.
- **Cloud Firestore**: base de datos en tiempo real utilizada para almacenar eventos, lugares/puntos de interés y perfiles de usuario.
- **Firebase Storage**: almacenamiento de imágenes asociadas a eventos y otros recursos multimedia de la aplicación.

No se utiliza Supabase en este proyecto.

## Estructura organizada del proyecto

```
lib/
├── main.dart                  Punto de entrada de la aplicación e inicialización de Firebase
├── app.dart                   Configuración general de la app
├── firebase_options.dart      Configuración de Firebase generada por FlutterFire
│
├── models/                    Modelos de datos de la aplicación
│   ├── event_model.dart
│   ├── news_model.dart
│   ├── place_model.dart
│   └── user_model.dart
│
├── pages/                     Pantallas de la aplicación, organizadas por módulo
│   ├── auth/                  Inicio de sesión, registro y recuperación de contraseña
│   ├── directory/             Directorio institucional
│   ├── events/                Listado y formulario de eventos
│   ├── home/                  Pantalla principal
│   ├── maps/                  Mapa del campus y rutas
│   ├── news/                  Listado y detalle de noticias
│   └── profile/                Perfil del usuario
│
├── services/                  Capa de acceso a datos y APIs externas
│   ├── auth_service.dart          Autenticación (Firebase Auth)
│   ├── event_service.dart         CRUD de eventos (Firestore)
│   ├── geocoding_service.dart     Geocodificación inversa (Nominatim)
│   ├── location_service.dart      Ubicación del dispositivo
│   ├── new_service.dart           Obtención de noticias (sitio web EPN)
│   ├── place_service.dart         CRUD de lugares/puntos de interés (Firestore)
│   ├── route_service.dart         Cálculo de rutas peatonales (OSRM)
│   ├── storage_service.dart       Subida de archivos (Firebase Storage)
│   └── user_service.dart          Perfiles de usuario (Firestore)
│
├── theme/                     Estilos y colores institucionales
├── utils/                     Utilidades generales (manejo de imágenes, etc.)
└── widgets/                   Componentes de interfaz reutilizables
```

## Pantallas de la aplicación

| Ícono | Splash Screen |
|---|---|
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 03 AM" src="https://github.com/user-attachments/assets/63b134cd-3bfe-4537-98e4-092df80ea125" />| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 23 AM" src="https://github.com/user-attachments/assets/9821cb36-e3b8-4e31-95d2-2cdb2229e51a" />|
| Login | Home |
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 21 AM" src="https://github.com/user-attachments/assets/580fa31d-70e0-4184-bc4e-4203b725cdac" />| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 22 AM" src="https://github.com/user-attachments/assets/b50962b6-8c6e-4424-b520-2adc5a08644c" />|
| Mapa | Noticias |
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 23 AM (1)" src="https://github.com/user-attachments/assets/3e08f670-b7be-4885-94c6-39f11b2b8815" />| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 23 AM (2)" src="https://github.com/user-attachments/assets/196a63e6-e385-477d-9832-bdbf669d9c70" />|
| Directorio | Perfil |
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 23 AM (3)" src="https://github.com/user-attachments/assets/43f72b6e-43b9-438a-ab9a-1105aa5fc17c" />| <img width="720" height="1600" alt="WhatsApp Image 2026-07-16 at 10 25 23 AM (4)" src="https://github.com/user-attachments/assets/7d28df7e-8fc5-4803-b9e8-e920929b6677" />|


## Videos

- Video demostrativo

https://youtu.be/yeJ_7tgkEps?si=MaXPk9aO-tUKUjaI

- Video promocional

https://vm.tiktok.com/ZS9r1F3LSB4A6-v9R9K/


## Descargas

### APK

Disponible en:

https://drive.google.com/drive/folders/1WNAjdw8wpLsFrbKUiNjFU4JEyF2zH9oF?usp=sharing

### AAB

Disponible en:

https://drive.google.com/drive/folders/1uvI0PKfAyMfuS9e4fFdLGdaASzkoltEH?usp=sharing


## Publicación

La aplicación fue enviada para publicación en Huawei AppGallery durante el desarrollo del proyecto académico. El proceso de revisión no fue aprobado por la plataforma, por lo que actualmente no se encuentra disponible para descarga desde una tienda oficial.


## Instrucciones para ejecutar la aplicación

### Requisitos previos

- Flutter SDK instalado (canal estable).
- Una cuenta y un proyecto de Firebase configurados para la aplicación.
- Editor de código (Visual Studio Code o Android Studio recomendado).

### Pasos

1. Clonar el repositorio del proyecto.

   ```
   git clone <url-del-repositorio>
   cd <carpeta-del-proyecto>
   ```

2. Instalar las dependencias del proyecto.

   ```
   flutter pub get
   ```

3. Configurar Firebase.

   El archivo `lib/firebase_options.dart` debe corresponder al proyecto de Firebase del equipo. Si es necesario regenerarlo, ejecutar:

   ```
   flutterfire configure
   ```

4. Verificar que los siguientes servicios estén habilitados en la consola de Firebase:

   - Authentication (correo y contraseña)
   - Cloud Firestore
   - Storage

5. Ejecutar la aplicación.

   Para ejecutar en un navegador (Chrome):

   ```
   flutter run -d chrome
   ```

   Para ejecutar en un emulador o dispositivo Android/iOS conectado:

   ```
   flutter run
   ```

6. Compilar para producción (opcional).

   ```
   flutter build web
   flutter build apk
   flutter build appbundle
   ```

## Integrantes del equipo y roles asignados

| Integrante | Rol asignado |
|---|---|
| Ayol Guanoluisa Nayely Del Rocio | Módulo de Eventos |
| Chang Alvarez Anthon Andre | Módulo de Mapa |
| Galeas Tingo Emily Alejandra | Módulo de Noticias |
| Naula Charco Jhosselin Britani | Frontend |
| Torres Mora Joel Eduardo | Entorno de desarrollo, conexiones y base de datos |


## Estado de cumplimiento del MVP

- https://epn360.netlify.app/
