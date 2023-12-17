# RE-Fridge-Server
RE:Fridge is a mobile application that helps users manage their pantry effciently. It allows users to keep track of the ingredients they have and suggests recipes based on the ingredients they have. This repository contains the server-side code for the RE:Fridge application.

# 🚀 Getting Started
### 1. Install Flutter
### 2. Clone the repository
```bash
git clone
```
### 3. Install dependencies
```bash
flutter pub get
```
### 4. Run the app
```bash
flutter run
```

# 📦 Dependencies
- [shelf](https://pub.dev/packages/shelf)
- [shelf_router](https://pub.dev/packages/shelf_router)
- [mysql_client](https://pub.dev/packages/mysql_client)

# 📖 Contribution Guide 
Thank you for contributing to the RE:Fridge! Please follow this contribution guide to help advance the project together.

## Before Contributing
- Check the open issues in the issue tracker to see if there are existing tasks or discussions.
- Consider what modifications or additions are needed, and start a discussion by creating an issue.


## How to Contribute
### 1. Fork this repository
### 2. Clone it to your local environment
```bash
git clone https://github.com/YunDo-Gi/RE-Fridge.git
```
### 3. Create a development branch
```bash
git checkout -b <branch-name>
```
### 4. Make changes and commit
```bash
git add .
git commit -m "<commit-message>"
```
### 5. Push changes
```bash
git push origin <branch-name>
```
### 6. Create a pull request
### 7. Wait for the pull request to be reviewed and merged

## Reporting Issues
Bugs, improvement ideas, and new feature suggestions are all welcome.

Click the `New Issue` button in the issue tracker to create a new issue.
Provide detailed information about the issue and the environment in which it occurs.

# Project Structure
```
RE-Fridge-Server
└─📦 bin
   ├─ 📂 api
   │  ├─ 📄 cart_api.dart
   │  ├─ 📄 ingredient_api.dart
   │  ├─ 📄 init_api.dart
   │  ├─ 📄 pantry_api.dart
   │  └─ 📄 recipe_api.dart
   ├─ 📂 controllers
   │  ├─ 📄 cart_controller.dart
   │  ├─ 📄 ingredient_controller.dart
   │  ├─ 📄 pantry_controller.dart
   │  └─ 📄 recipe_controller.dart
   ├─ 📂 db
   │  └─ 📄 setup_db.dart
   ├─ 📄 server.dart
   └─ 📂 utils
```