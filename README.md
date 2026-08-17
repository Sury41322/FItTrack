# FitTrack

A native iOS fitness and nutrition tracking app built with SwiftUI and SwiftData, combining workout logging, calorie/macro tracking via a live food database, and weight/progress monitoring in one app.

## Features
- **Workout logging** — log sets, reps, and weight per exercise, with warm-up set tracking and completion status
- **Nutrition tracking** — search a live food database (USDA FoodData Central API) for accurate calorie, protein, carb, and fat data per 100g, log meals, and track daily intake
- **Weight tracking** — daily weigh-ins with a morning weigh-in prompt and historical trend view
- **Activity calendar** — visual calendar view of logged workout days
- **Smart notifications** — local notifications that remind users of missed workouts, scheduled per weekday and automatically cancelled/rescheduled when a workout split changes
- **Onboarding flow** — guided first-run setup for user profile and goals
- **Dashboard** — unified daily summary of workouts, nutrition, and weight

## Tech Stack
- **Framework:** SwiftUI, SwiftData (for local persistence of workouts, food logs, weight entries, and user profile)
- **Architecture:** MVVM-style separation — dedicated `Store` classes (`WorkoutStore`, `FoodStore`, `WeightStore`, `DayLogStore`, `ProfileStore`) manage state per domain, with views consuming them via `ObservableObject`
- **External API:** USDA FoodData Central API integration for real-time food/nutrition lookup, with response parsing, deduplication, and nutrient extraction logic
- **Notifications:** `UserNotifications` framework for scheduled local reminders
- **Platform:** iOS (Xcode project)

## Project Structure
25 Swift files (~5,600 lines) organized by feature: workout logging & models, nutrition/food search, weight tracking, profile & onboarding, notifications, and shared UI components.

## Status
Personal project — fully functional, tested on iOS. Built to explore SwiftData persistence, real-world API integration, and local notification scheduling in a production-style multi-feature app.
