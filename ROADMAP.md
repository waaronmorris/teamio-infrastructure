# TeamIO Development Roadmap

## Current Status

The core features of the TeamIO sports league management platform are implemented:

### Completed Features

| Feature | Backend | Frontend | Notes |
|---------|:-------:|:--------:|-------|
| Authentication | ✅ | ✅ | JWT tokens, login, registration |
| User Management | ✅ | ✅ | List, edit, deactivate/reactivate users |
| Leagues CRUD | ✅ | ✅ | Create, edit, delete leagues |
| Teams CRUD | ✅ | ✅ | Team management with colors |
| Field Management | ✅ | ✅ | Fields with amenities, availability |
| Player Rosters | ✅ | ✅ | Team roster management |
| Draft System | ✅ | ✅ | Real-time drafts with WebSocket |
| Calendar Subscriptions | ✅ | ✅ | iCal feed generation |
| Registrations | ✅ | ✅ | Registration workflow |
| Schedule/Events | ✅ | ✅ | Game and practice scheduling |
| Dashboard Navigation | - | ✅ | Sidebar and breadcrumbs |
| Settings | ✅ | ✅ | Persistent user preferences |
| Registration Forms | ✅ | ✅ | Configurable form builder + templates |
| User Invites | ✅ | ✅ | Email invitations with token-based flow |
| Game Scoring | ✅ | ✅ | Score entry, standings calculations |
| Reports & Analytics | ✅ | ✅ | Standings, results, event/registration stats |
| Mobile Responsiveness | - | ✅ | Scroll tables, responsive grids, mobile-first |
| Testing | - | ✅ | 20 unit tests (Vitest + React Testing Library) |
| Invite Acceptance | ✅ | ✅ | /invite/:token page with account creation |
| Notification Center | - | ✅ | Bell icon popover with unread badges |
| Player Stats | ✅ | ✅ | Stat types, leaderboards, player season stats |
| Messaging | ✅ | ✅ | Inbox, conversations, compose, mark-as-read |
| Audit Logging | ✅ | ✅ | Track admin actions with filtering |
| PWA Support | - | ✅ | Web manifest, service worker, installable app |

---

## Next Steps

### 1. Settings Functionality
**Priority:** Medium
**Complexity:** Low

Currently the Settings page has UI but no backend persistence.

**Tasks:**
- [ ] Create settings API endpoint (`GET/PUT /users/:id/settings`)
- [ ] Create user_settings table in database
- [ ] Implement theme switching (light/dark/system)
- [ ] Save notification preferences to backend
- [ ] Persist timezone preference per user

**Files to modify:**
- `backend/src/handlers/` - Add settings handler
- `backend/src/services/` - Add settings service
- `frontend-lovable/src/pages/Settings.tsx` - Connect to API

---

### 2. Player Registration Flow
**Priority:** High
**Complexity:** Medium

Allow guardians to register players for seasons through the parent portal.

**Tasks:**
- [ ] Create registration form for guardians
- [ ] Add player profile creation during registration
- [ ] Implement waiver/consent form workflow
- [ ] Add payment integration placeholder
- [ ] Email confirmation on registration
- [ ] Admin approval workflow for registrations

**Files to create:**
- `frontend-lovable/src/pages/PlayerRegistration.tsx`
- `frontend-lovable/src/components/registration/RegistrationForm.tsx`
- `frontend-lovable/src/components/registration/WaiverForm.tsx`

---

### 3. Invite Users
**Priority:** Medium
**Complexity:** Low

Add ability to invite new users via email from User Management.

**Tasks:**
- [ ] Create invite endpoint (`POST /users/invite`)
- [ ] Generate invite tokens with expiration
- [ ] Send invitation email with signup link
- [ ] Create invite acceptance page
- [ ] Track pending invitations
- [ ] Add "Invite User" button to User Management page

**Backend changes:**
- Add `user_invites` table
- Add email sending service (SendGrid, AWS SES, etc.)

---

### 4. Game Scoring
**Priority:** High
**Complexity:** Medium

Enter and edit game scores, update team standings.

**Tasks:**
- [ ] Create score entry UI for completed games
- [ ] Implement standings calculation service
- [ ] Add standings view to league/division pages
- [ ] Track wins, losses, ties, points for/against
- [ ] Support different scoring formats (runs, goals, points)
- [ ] Add game result history

**Files to modify:**
- `frontend-lovable/src/pages/DashboardSchedule.tsx` - Add score entry
- `frontend-lovable/src/components/schedule/GameScoreCard.tsx` - Create new
- `backend/src/services/stats.rs` - Standings calculations

---

### 5. Notifications System
**Priority:** Medium
**Complexity:** High

Email and in-app notifications for important events.

**Tasks:**
- [ ] Set up email service provider integration
- [ ] Create notification templates (schedule changes, draft picks, etc.)
- [ ] Implement in-app notification center
- [ ] Add notification preferences per user
- [ ] Create notification queue/worker for async sending
- [ ] Add push notification support (optional)

**Notification types:**
- Schedule changes (game time/location updates)
- Draft notifications (your turn, pick made)
- Registration confirmations
- Team announcements
- Practice reminders

---

### 6. Reports & Analytics
**Priority:** Low
**Complexity:** Medium

Dashboards for league stats and player statistics.

**Tasks:**
- [ ] Team standings leaderboard
- [ ] Player statistics tracking (batting avg, goals, etc.)
- [ ] Season summary reports
- [ ] Registration analytics (signups over time)
- [ ] Attendance tracking
- [ ] Export reports to PDF/CSV

**Pages to create:**
- `frontend-lovable/src/pages/Reports.tsx`
- `frontend-lovable/src/pages/PlayerStats.tsx`
- `frontend-lovable/src/pages/SeasonSummary.tsx`

---

### 7. Mobile Responsiveness
**Priority:** Medium
**Complexity:** Low

Improve UI for mobile devices.

**Tasks:**
- [ ] Audit all pages for mobile layout issues
- [ ] Fix table layouts for small screens (horizontal scroll or card view)
- [ ] Improve touch targets for buttons/links
- [ ] Test draft room on mobile
- [ ] Add mobile-friendly navigation (hamburger menu)
- [ ] Optimize images and assets for mobile

**Focus areas:**
- Dashboard sidebar (collapsible on mobile)
- Data tables (responsive or card layout)
- Draft room (simplified mobile view)
- Forms (full-width inputs)

---

### 8. Testing
**Priority:** High
**Complexity:** Medium

Add automated tests for reliability.

**Tasks:**
- [ ] Set up testing framework for frontend (Vitest + React Testing Library)
- [ ] Add unit tests for critical services
- [ ] Add integration tests for API endpoints
- [ ] Add E2E tests for key user flows (Playwright)
- [ ] Set up CI/CD pipeline for automated testing
- [ ] Add test coverage reporting

**Key flows to test:**
- User authentication (login, register, logout)
- Draft lifecycle (create, setup, start, pick, complete)
- Registration workflow
- CRUD operations for leagues/teams/players

---

## Technical Debt

### CSS Warning
The `@import` statement in `index.css` should be moved before `@tailwind` directives:
```css
@import url('https://fonts.googleapis.com/css2?family=Inter...');
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### Browserslist Update
Run `npx update-browserslist-db@latest` to update browser compatibility data.

### Type Improvements
- Add stricter TypeScript types for API responses
- Create shared types package for frontend/backend

---

## Future Considerations

- **Multi-organization support** - Allow multiple leagues/organizations
- **Payment processing** - Stripe/PayPal integration for registration fees
- **Communication tools** - In-app messaging between coaches/parents
- **Photo galleries** - Team and game photos
- **Mobile app** - React Native or PWA
- **API documentation** - OpenAPI/Swagger docs
- **Audit logging** - Track admin actions for compliance
