# Itinify — Product Requirements Document

> Backend API for **Itinify**, a collaborative group trip planner.
> Status: Active development · Last updated: 2026-11-02

---

## 1. Overview

Planning a group trip today means juggling a group chat for ideas, a spreadsheet for the schedule, a notes app for bookings, and a separate app for splitting costs. Ideas get lost, decisions stall, and nobody knows who owes whom.

**Itinify brings the whole trip into one shared space.** Friends throw ideas onto a live collaborative board, vote on what they like, drag the winners into a day-by-day itinerary (or have AI draft one), keep booking confirmations in one place, and track shared expenses with automatic balance settlement.

This repository is the Rails API that powers the Itinify web client.

## 2. Problem Statement

| Pain point | Today | With Itinify |
|---|---|---|
| Ideas scattered across chats and links | Lost in scrollback | Idea cards on a shared, real-time board |
| Group can't agree on what to do | Endless back-and-forth | Upvotes surface what the group wants |
| Building a schedule from scratch | Hours of research | AI-generated itinerary in seconds, fully editable |
| Bookings and tickets everywhere | Inbox searching | Travel documents stored per trip |
| Who paid for what? | Manual spreadsheet math | Expense log with computed balances and settlements |
| Planning a trip someone already did | Start from zero | Duplicate a published trip template |

## 3. Goals & Non-Goals

### Goals
- Make group trip planning **collaborative and real-time**, with everyone seeing changes as they happen.
- Shorten the path from "we should go to X" to a usable day-by-day plan.
- Remove the awkwardness of money in group travel through transparent expense tracking.
- Let users share finished trips as reusable templates.

### Non-Goals (for now)
- Booking flights, hotels, or activities in-app (no payments or OTA integrations).
- Native mobile apps (the web client is responsive-first).
- Moving real money between users. Settlements are *recorded*, not processed.
- Offline-first editing.

## 4. Target Users

- **The Organizer** — usually one person who kicks off the trip, invites friends, and wants the plan to come together without nagging.
- **The Contributor** — friends who want to drop in ideas and vote, but won't build a spreadsheet.
- **The Template Browser** — someone planning a trip to a popular destination who wants a proven starting point.

## 5. Core Features & Requirements

Priority: **P0** = MVP, must have · **P1** = important · **P2** = nice to have.
Status: ✅ Shipped · 🚧 In progress · 📋 Planned.

### 5.1 Authentication & Accounts
| ID | Requirement | Priority | Status |
|---|---|---|---|
| AUTH-1 | Sign up and log in with email + password (bcrypt, JWT) | P0 | ✅ |
| AUTH-2 | Sign in with Google, including avatar import | P0 | ✅ |
| AUTH-3 | `GET /api/me` returns the current user profile | P0 | ✅ |
| AUTH-4 | Track onboarding and tutorial completion per user | P1 | ✅ |
| AUTH-5 | Rate-limit requests and login attempts (Rack::Attack) | P0 | ✅ |
| AUTH-6 | Password reset via email | P1 | 📋 |

### 5.2 Trips & Membership
| ID | Requirement | Priority | Status |
|---|---|---|---|
| TRIP-1 | Create, view, update, and delete a trip (name, location, dates, cover image) | P0 | ✅ |
| TRIP-2 | Itinerary days are created automatically from the trip's date range and re-synced when dates change | P0 | ✅ |
| TRIP-3 | Roles: `owner`, `editor`, `viewer` | P0 | ✅ |
| TRIP-4 | Invite by shareable link (invite token) and regenerate it to revoke old links | P0 | ✅ |
| TRIP-5 | Send an invite email to a specific address | P1 | ✅ |
| TRIP-6 | Members can leave a trip | P1 | ✅ |
| TRIP-7 | Enforce role permissions on every write (viewers are read-only) | P0 | 📋 |
| TRIP-8 | Invite links expire (`invite_expires_at`) | P1 | 📋 |

### 5.3 Idea Board (Real-time Collaboration)
| ID | Requirement | Priority | Status |
|---|---|---|---|
| IDEA-1 | Create, edit, and delete idea cards with title, notes, URL, image, address, and category | P0 | ✅ |
| IDEA-2 | Cards have x/y positions on a freeform canvas | P0 | ✅ |
| IDEA-3 | Group cards into colored, resizable category zones | P1 | ✅ |
| IDEA-4 | One upvote per user per card | P0 | ✅ |
| IDEA-5 | Broadcast card, category, and upvote changes to all trip members over ActionCable (`TripChannel`) | P0 | ✅ |
| IDEA-6 | Show live cursors of other members on the board | P1 | ✅ |
| IDEA-7 | Presence indicator showing who is currently viewing the trip | P2 | 📋 |

### 5.4 Itinerary
| ID | Requirement | Priority | Status |
|---|---|---|---|
| ITIN-1 | Day-by-day view with city and accommodation per day | P0 | ✅ |
| ITIN-2 | Itinerary items are linked to idea cards, with time of day (morning, afternoon, evening), scheduled time, order, notes, and address | P0 | ✅ |
| ITIN-3 | Reorder and move items between days | P0 | ✅ |
| ITIN-4 | Add and remove days | P1 | ✅ |
| ITIN-5 | Export the itinerary (PDF / calendar `.ics`) | P2 | 📋 |
| ITIN-6 | Map view of each day's stops | P2 | 📋 |

### 5.5 AI Itinerary Generation
| ID | Requirement | Priority | Status |
|---|---|---|---|
| AI-1 | Generate a full itinerary from destination, dates, and season using Claude | P0 | ✅ |
| AI-2 | Accept preferences: budget, travel style, group type, interests | P0 | ✅ |
| AI-3 | Generated output is persisted as normal idea cards, days, and items so it stays fully editable | P0 | ✅ |
| AI-4 | Fail gracefully with a 503 when the AI provider is unavailable | P0 | ✅ |
| AI-5 | Move generation to a background job and stream progress to the client | P1 | 📋 |
| AI-6 | Regenerate a single day without touching the rest | P2 | 📋 |
| AI-7 | Per-user or per-trip generation quota to control cost | P1 | 📋 |

### 5.6 Expenses & Settlements
| ID | Requirement | Priority | Status |
|---|---|---|---|
| EXP-1 | Log expenses (amount, description, payer) per trip | P0 | ✅ |
| EXP-2 | Compute each member's balance (`GET /trips/:id/balances`) | P0 | ✅ |
| EXP-3 | Record settlements between members | P0 | ✅ |
| EXP-4 | Real-time expense updates across members | P1 | ✅ |
| EXP-5 | Uneven splits (by share, percentage, or selected members only) | P1 | 📋 |
| EXP-6 | Multi-currency support with conversion | P2 | 📋 |

### 5.7 Travel Documents
| ID | Requirement | Priority | Status |
|---|---|---|---|
| DOC-1 | Upload documents (PDF, PNG, JPEG; max 20 MB) via Active Storage | P1 | 🚧 |
| DOC-2 | Categorize as hotel, flight, activity, transport, or other, with title and notes | P1 | 🚧 |
| DOC-3 | List, update, and delete documents per trip, showing who uploaded each one | P1 | 🚧 |
| DOC-4 | Restrict documents to trip members only (signed, expiring URLs) | P0 | 📋 |

### 5.8 Trip Templates
| ID | Requirement | Priority | Status |
|---|---|---|---|
| TPL-1 | Publish a trip as a public template with a description and tags (copies idea cards and itinerary) | P1 | ✅ |
| TPL-2 | Browse all published templates with owner name | P1 | ✅ |
| TPL-3 | Duplicate a template into a new private trip, tracking a duplicate count | P1 | ✅ |
| TPL-4 | Search and filter templates by destination, tags, or popularity | P2 | 📋 |
| TPL-5 | Unpublish or update a published template | P2 | 📋 |

## 6. Key User Flows

1. **Start a trip:** Sign up → create a trip (name, destination, dates) → days are generated automatically → share the invite link.
2. **Collect ideas:** Members join via the link → add idea cards to the board → upvote favorites → everyone sees changes live.
3. **Build the plan:** Drag cards into days *or* click "Generate itinerary", pick preferences, and get an editable AI draft.
4. **Travel:** Upload booking confirmations → log expenses as you go → check balances → record settlements at the end.
5. **Share:** Publish the finished trip as a template so others can duplicate it.

## 7. Success Metrics

| Metric | What it tells us |
|---|---|
| % of trips with ≥ 2 members | Is the product actually used collaboratively? |
| Ideas and upvotes per trip | Engagement on the board |
| % of trips with a generated or populated itinerary | Do users reach a usable plan? |
| AI generation success rate and p95 latency | Reliability of the AI feature |
| % of trips with ≥ 1 expense logged | Adoption of expense tracking |
| Template duplications per week | Value of the template library |
| D7 / D30 retention of trip creators | Long-term product value |

## 8. Non-Functional Requirements

- **Security:** JWT auth on all `/api` routes. Rate limiting via Rack::Attack. Trip data is visible to members only. Uploaded files are validated by type and size.
- **Real-time:** ActionCable broadcasts backed by Redis in production. A board change should reach other members in under 500 ms.
- **Performance:** Standard API endpoints p95 < 300 ms. AI generation p95 < 30 s (target < 10 s once it runs as a background job).
- **Reliability:** `/up` health check for uptime monitoring. Multi-step writes (templates, trip creation) run inside DB transactions.
- **Code quality:** RuboCop (rails-omakase) enforced.

## 9. Tech Stack & Architecture

| Layer | Choice |
|---|---|
| Framework | Ruby 3.3, Rails 7.1 (API mode) |
| Database | PostgreSQL |
| Real-time | ActionCable + Redis |
| Auth | JWT, bcrypt, Google OAuth |
| AI | Anthropic Claude (`anthropic` gem) |
| File storage | Active Storage |
| Email | Action Mailer (`TripMailer`) |
| Deployment | Docker Compose on a self-hosted GitHub Actions runner; deploys on push to `main` |

**Data model (simplified):**

```
User ─< TripMember >─ Trip
                       ├─< IdeaCard ─< IdeaUpvote >─ User
                       ├─< Category
                       ├─< ItineraryDay ─< ItineraryItem >─ IdeaCard
                       ├─< Expense >─ User
                       ├─< Settlement (payer → receiver)
                       └─< TravelDocument (file attached) >─ User
```

## 10. Risks & Open Questions

- **Authorization gaps:** Some endpoints look up a trip with `Trip.find` instead of scoping to the current user's trips. These need to be audited before public launch (TRIP-7).
- **AI cost and abuse:** Generation is synchronous and unmetered. Needs a quota and a background job (AI-5, AI-7).
- **AI output reliability:** The JSON response from the model can fail to parse. Consider structured outputs or tool use.
- **Template moderation:** Published templates are public. Do we need reporting or review?
- **Open:** Should viewers be allowed to upvote? Should templates copy expenses and documents? (Current answer: no.)

## 11. Roadmap

| Phase | Scope |
|---|---|
| **Now** | Finish Travel Documents (DOC-1 to DOC-4), role enforcement (TRIP-7), invite expiry (TRIP-8) |
| **Next** | Background AI generation with quotas, uneven expense splits, password reset |
| **Later** | Template search, itinerary export and map view, multi-currency, presence indicators |

---
