# smart_home_app

A new Flutter project.

## API Contract (Auth/User)

- Get current user endpoint:
	- `GET /users/me`
	- header: `Authorization: Bearer <access_token>`

## User Access Rules

- `GET /users/me`: authenticated user can read own profile
- `PATCH /users/me`: authenticated user updates own profile
- `POST /users`: admin only
- `PATCH /users/:id`: admin only
- User role is included in JWT payload
- Role cannot be updated through update user DTO

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
