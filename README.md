# Live Score App

Live Score is an open-source Flutter football app with 82 stars, built for fast match-day browsing. It brings together live fixtures, today's schedule, standings, lineups, statistics, and match events in a clean cross-platform experience for football fans.

## 📱 App Mockup
<img width="1892" height="1493" alt="live-score-app-cover" src="https://github.com/user-attachments/assets/45ba9f94-41d1-466c-a042-8769b36ab744" />

## Overview

The app focuses on the information people usually need most during a match day:

- live scores and match status
- today's fixtures across supported competitions
- league tables and standings
- lineups, events, and match statistics
- a mobile-first interface built with Flutter and BLoC

## Features

- Live football fixtures and score updates
- Competition-based browsing for major leagues and tournaments
- Match details including lineups, events, and statistics
- League standings for supported competitions
- Android, iOS, and web support

## Tech Stack

- Flutter
- BLoC / Cubit
- Dio
- GetIt
- Clean architecture-inspired project structure

## Web Support

The mobile apps call `365scores` directly. For Flutter Web, this repository uses a small Cloudflare Worker proxy because the API cannot be called directly from the browser.

Current deployed proxy:

- [https://live-score-proxy-2.radyhaggag50.workers.dev](https://live-score-proxy-2.radyhaggag50.workers.dev)

The Flutter web app is already configured to use that proxy by default. If you ever replace it, you can override the URL with:

```bash
flutter run -d chrome --dart-define=WEB_API_PROXY_BASE_URL=https://your-proxy-url
```

## GitHub Pages Deployment

This repository includes a GitHub Pages workflow at [.github/workflows/deploy_web.yml](/Users/radyhaggag/Programming/Flutter/live_score/.github/workflows/deploy_web.yml:1).

To publish the web app:

1. Push the repository to GitHub on `main` or `master`.
2. In the GitHub repository settings, enable `Pages` and choose `GitHub Actions` as the source.
3. The workflow builds the Flutter web app, adds a single-page-app fallback, and deploys it automatically.

If you later attach a custom domain or host the app at the site root instead of `/<repo-name>/`, update the `--base-href` value in the workflow.

You do not need to add any environment variable for the current setup. The app already points to the deployed Cloudflare proxy by default. The `WEB_API_PROXY_BASE_URL` value is only an optional override for the future if you ever move the proxy to a different URL.

## 📱 Screenshots

Here are some previews of **Live Score App** after the latest update:

<p align="center">
  <img src="https://github.com/user-attachments/assets/2a434a88-85f9-41ee-a05c-e92423431d47" alt="Live score screen - 1" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/7797df8d-c62a-4051-b388-712708f758d8" alt="Live score screen - 2" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/d4c24c4c-a9e7-4ca6-96d2-ddd7b00550ff" alt="Fixtures screen" width="30%"/> &nbsp;
  <br/><br/>
  <img src="https://github.com/user-attachments/assets/3005b687-900a-4bef-8bed-c539c743e5d1" alt="Live score screen - 3" width="30%"/>
  <img src="https://github.com/user-attachments/assets/f43e2111-398d-46ce-aa89-76dd760ed89d" alt="Standings Screen - 1" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/2788bb4b-10f9-4070-9d02-b00c0528b2d4" alt="Standings Screen - 2" width="30%"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/81ae7248-db8b-45e6-a196-355924945a25" alt="Fixture screen lineup - 1" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/a6a5fe84-6588-4099-bb9f-35f53ce909e3" alt="Fixture screen lineup - 2" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/421e6cca-a5f8-44ff-acf7-c2a0e229f6bc" alt="Fixture screen statistics - 1" width="30%"/>
  <br/><br/>
  <img src="https://github.com/user-attachments/assets/c5837505-0faf-4d1f-974e-e9193871cc87" alt="Fixture screen statistics - 2" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/2f739c83-b9c4-4557-8438-cc8b0fdcafc8" alt="Fixture screen events - 1" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/a5ae300b-2b04-4dd8-a8ab-ab98d31fd0cf" alt="Fixture screen events - 2" width="30%"/> &nbsp;
  <br/><br/>
  <img src="https://github.com/user-attachments/assets/0c9c7990-cc51-4641-8137-e81ddb7e142f" alt="Fixture lineup 1" width="30%"/> &nbsp;
  <img src="https://github.com/user-attachments/assets/cc873c39-069f-43a0-850f-3dd27a8eac62" alt="Fixture lineup 2" width="30%"/>
  <img src="https://github.com/user-attachments/assets/eff986c1-30c2-4b54-be39-beccaaefbdcc" alt="Fixture statistics" width="30%"/> &nbsp;
  <br/><br/>
  <img src="https://github.com/user-attachments/assets/fde752ac-f3ff-4bda-948a-07c459ab72fb" alt="Fixture events" width="30%"/>
</p>

## 📥 Download

Get the signed APK from [GitHub Releases](https://github.com/al3nkboot/live_score/releases/latest).

## Screenshots

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/1.jpg" width="180" alt="Matches"/>
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2.jpg" width="180" alt="Match facts"/>
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3.jpg" width="180" alt="Lineup"/>
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/4.jpg" width="180" alt="Ratings"/>
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/5.jpg" width="180" alt="Table"/>
</p>

### Packages used in the project:

- [Dio](https://pub.dev/packages/dio)
- [internet_connection_checker](https://pub.dev/packages/internet_connection_checker)
- [equatable](https://pub.dev/packages/equatable)
- [dartz](https://pub.dev/packages/dartz)
- [bloc](https://pub.dev/packages/bloc)
- [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- [hexcolor](https://pub.dev/packages/hexcolor)
- [get_it](https://pub.dev/packages/get_it)
- [intl](https://pub.dev/packages/intl)

### in the project:

- bloc as State managment
- Clean code
- Clean architecture
- [Restful api](https://www.api-football.com/documentation-v3)
