/**
 * PostHog Event Seeder for TeamIO
 *
 * Sends realistic synthetic events to PostHog covering all key user journeys:
 * - User signup & onboarding
 * - Registration flow (with realistic dropoff)
 * - Team management (roster updates, score entry)
 * - Schedule & RSVP
 * - Messaging & announcements
 * - Portal usage (coach, parent, player, referee)
 * - League management
 * - Payment flow
 *
 * Usage:
 *   POSTHOG_API_KEY=phc_... npx tsx src/seed-posthog-events.ts
 *
 * Env vars:
 *   POSTHOG_API_KEY     - Project API key (phc_...)
 *   POSTHOG_HOST        - PostHog host (default: https://us.i.posthog.com)
 *   SEED_DAYS           - How many days back to generate (default: 30)
 *   SEED_EVENTS_PER_DAY - Approximate events per day (default: 80)
 */

const PH_KEY = process.env.POSTHOG_API_KEY || process.env.VITE_PUBLIC_POSTHOG_KEY || '';
const PH_HOST = process.env.POSTHOG_HOST || process.env.VITE_PUBLIC_POSTHOG_HOST || 'https://us.i.posthog.com';
const SEED_DAYS = parseInt(process.env.SEED_DAYS || '30', 10);
const EVENTS_PER_DAY = parseInt(process.env.SEED_EVENTS_PER_DAY || '80', 10);

// ============================================================================
// Domain Data (matches seed-data.sql)
// ============================================================================

interface UserProfile {
  distinct_id: string;
  email: string;
  name: string;
  role: 'admin' | 'commissioner' | 'coach' | 'guardian' | 'player';
  org_id: string;
  org_name: string;
}

const USERS: UserProfile[] = [
  // Admins
  { distinct_id: 'a0000001-0000-0000-0000-000000000001', email: 'admin@teamio.local', name: 'Admin User', role: 'admin', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  // Commissioners
  { distinct_id: 'a0000002-0000-0000-0000-000000000001', email: 'commissioner@teamio.local', name: 'League Commissioner', role: 'commissioner', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000003-0000-0000-0000-000000000001', email: 'commissioner.valley@teamio.local', name: 'Carlos Rivera', role: 'commissioner', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  { distinct_id: 'a0000004-0000-0000-0000-000000000001', email: 'commissioner.tournament@teamio.local', name: 'Patricia Nguyen', role: 'commissioner', org_id: 'b0000003-0000-0000-0000-000000000001', org_name: 'Central Valley Tournament Series' },
  // Coaches
  { distinct_id: 'a0000010-0000-0000-0000-000000000001', email: 'coach.smith@teamio.local', name: 'John Smith', role: 'coach', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000011-0000-0000-0000-000000000001', email: 'coach.johnson@teamio.local', name: 'Sarah Johnson', role: 'coach', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000012-0000-0000-0000-000000000001', email: 'coach.williams@teamio.local', name: 'Mike Williams', role: 'coach', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000014-0000-0000-0000-000000000001', email: 'coach.martinez@teamio.local', name: 'Luis Martinez', role: 'coach', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  { distinct_id: 'a0000015-0000-0000-0000-000000000001', email: 'coach.lee@teamio.local', name: 'Kevin Lee', role: 'coach', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  // Guardians
  { distinct_id: 'a0000020-0000-0000-0000-000000000001', email: 'parent.jones@teamio.local', name: 'Robert Jones', role: 'guardian', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000021-0000-0000-0000-000000000001', email: 'parent.davis@teamio.local', name: 'Jennifer Davis', role: 'guardian', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000022-0000-0000-0000-000000000001', email: 'parent.miller@teamio.local', name: 'David Miller', role: 'guardian', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000023-0000-0000-0000-000000000001', email: 'parent.wilson@teamio.local', name: 'Lisa Wilson', role: 'guardian', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000024-0000-0000-0000-000000000001', email: 'parent.chen@teamio.local', name: 'Wei Chen', role: 'guardian', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  { distinct_id: 'a0000025-0000-0000-0000-000000000001', email: 'parent.brooks@teamio.local', name: 'Tamika Brooks', role: 'guardian', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  { distinct_id: 'a0000026-0000-0000-0000-000000000001', email: 'parent.garcia@teamio.local', name: 'Miguel Garcia', role: 'guardian', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  // Players
  { distinct_id: 'a0000030-0000-0000-0000-000000000001', email: 'player1@teamio.local', name: 'Jake Jones', role: 'player', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000031-0000-0000-0000-000000000001', email: 'player2@teamio.local', name: 'Emma Davis', role: 'player', org_id: 'b0000001-0000-0000-0000-000000000001', org_name: 'Riverside Parks & Recreation' },
  { distinct_id: 'a0000042-0000-0000-0000-000000000001', email: 'player13@teamio.local', name: 'Dylan Chen', role: 'player', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
  { distinct_id: 'a0000043-0000-0000-0000-000000000001', email: 'player14@teamio.local', name: 'Marcus Brooks', role: 'player', org_id: 'b0000002-0000-0000-0000-000000000001', org_name: 'Valley Select Baseball' },
];

// Anonymous visitors who don't complete signup
const ANON_VISITORS = Array.from({ length: 15 }, (_, i) => `anon-visitor-${i + 1}`);

const TEAMS = [
  { id: '11000001', name: 'Riverside Eagles', sport: 'soccer', org: 'Riverside Parks & Recreation' },
  { id: '11000002', name: 'Thunder FC', sport: 'soccer', org: 'Riverside Parks & Recreation' },
  { id: '11000003', name: 'Green Machine', sport: 'soccer', org: 'Riverside Parks & Recreation' },
  { id: '11000004', name: 'Blue Lightning', sport: 'soccer', org: 'Riverside Parks & Recreation' },
  { id: '11000005', name: 'Strikers United', sport: 'soccer', org: 'Riverside Parks & Recreation' },
  { id: '11000009', name: 'Valley Vipers', sport: 'baseball', org: 'Valley Select Baseball' },
  { id: '11000010', name: 'Hillcrest Hawks', sport: 'baseball', org: 'Valley Select Baseball' },
  { id: '11000011', name: 'Diamond Dogs', sport: 'baseball', org: 'Valley Select Baseball' },
];

const LEAGUES = [
  { id: 'd0000001', name: 'Youth Soccer League', sport: 'soccer' },
  { id: 'd0000002', name: 'Adult Basketball League', sport: 'basketball' },
  { id: 'd0000004', name: 'Valley Select 12U Travel', sport: 'baseball' },
  { id: 'd0000005', name: 'Tri-County Youth Soccer', sport: 'soccer' },
];

const PAGES = [
  '/dashboard', '/teams', '/schedule', '/standings', '/messages',
  '/profile', '/registration', '/league-management', '/coach-portal',
  '/parent-portal', '/player-portal', '/referee-portal', '/onboarding',
  '/teams/:id', '/schedule/:id', '/registration/step-1', '/registration/step-2',
  '/registration/step-3', '/registration/payment', '/registration/confirmation',
];

const BROWSERS = ['Chrome', 'Safari', 'Firefox', 'Edge'];
const OS_LIST = ['Mac OS X', 'Windows', 'iOS', 'Android'];
const DEVICES = ['Desktop', 'Mobile', 'Tablet'];
const REFERRERS = [
  'https://www.google.com', 'https://www.facebook.com',
  '', 'https://www.instagram.com', 'direct',
];

const BASE_URL = 'https://app.getteamio.com';
const MARKETING_URL = 'https://www.getteamio.com';

// ============================================================================
// GA-style Marketing / Acquisition Data
// ============================================================================

const UTM_CAMPAIGNS = [
  { utm_source: 'google', utm_medium: 'cpc', utm_campaign: 'spring-registration-2026', utm_content: 'youth-soccer-ad', utm_term: 'youth soccer registration' },
  { utm_source: 'google', utm_medium: 'cpc', utm_campaign: 'spring-registration-2026', utm_content: 'baseball-ad', utm_term: 'travel baseball signup' },
  { utm_source: 'google', utm_medium: 'organic', utm_campaign: undefined, utm_content: undefined, utm_term: 'youth sports management app' },
  { utm_source: 'google', utm_medium: 'organic', utm_campaign: undefined, utm_content: undefined, utm_term: 'kids soccer league near me' },
  { utm_source: 'facebook', utm_medium: 'paid_social', utm_campaign: 'parent-awareness-spring', utm_content: 'carousel-team-photos', utm_term: undefined },
  { utm_source: 'facebook', utm_medium: 'paid_social', utm_campaign: 'parent-awareness-spring', utm_content: 'video-testimonial', utm_term: undefined },
  { utm_source: 'facebook', utm_medium: 'social', utm_campaign: undefined, utm_content: 'shared-post', utm_term: undefined },
  { utm_source: 'instagram', utm_medium: 'paid_social', utm_campaign: 'coach-recruitment', utm_content: 'stories-ad', utm_term: undefined },
  { utm_source: 'instagram', utm_medium: 'social', utm_campaign: undefined, utm_content: 'bio-link', utm_term: undefined },
  { utm_source: 'email', utm_medium: 'email', utm_campaign: 'spring-season-reminder', utm_content: 'cta-register-now', utm_term: undefined },
  { utm_source: 'email', utm_medium: 'email', utm_campaign: 'welcome-series', utm_content: 'onboarding-step-2', utm_term: undefined },
  { utm_source: 'email', utm_medium: 'email', utm_campaign: 'weekly-digest', utm_content: 'schedule-update', utm_term: undefined },
  { utm_source: 'partner', utm_medium: 'referral', utm_campaign: 'riverside-parks-partnership', utm_content: 'website-banner', utm_term: undefined },
  { utm_source: 'partner', utm_medium: 'referral', utm_campaign: 'ymca-cross-promo', utm_content: 'newsletter-feature', utm_term: undefined },
  { utm_source: 'nextdoor', utm_medium: 'social', utm_campaign: 'community-post', utm_content: undefined, utm_term: undefined },
  { utm_source: 'tiktok', utm_medium: 'paid_social', utm_campaign: 'youth-sports-awareness', utm_content: 'coach-day-in-life', utm_term: undefined },
];

const LANDING_PAGES = [
  '/', '/register', '/features', '/pricing', '/about',
  '/sports/soccer', '/sports/baseball', '/sports/basketball',
  '/for-coaches', '/for-parents', '/for-leagues',
  '/blog/spring-registration-open', '/blog/5-tips-youth-coaching',
];

const GA_REFERRER_URLS: Record<string, string[]> = {
  google: ['https://www.google.com/search?q=youth+soccer+registration', 'https://www.google.com/search?q=team+management+app', 'https://www.google.com/search?q=kids+baseball+signup'],
  facebook: ['https://www.facebook.com/', 'https://l.facebook.com/l.php?u=getteamio.com'],
  instagram: ['https://www.instagram.com/', 'https://l.instagram.com/'],
  email: [''],
  partner: ['https://www.riversideparks.local/', 'https://www.ymca.org/'],
  nextdoor: ['https://nextdoor.com/'],
  tiktok: ['https://www.tiktok.com/'],
  direct: [''],
};

const CITIES = [
  { city: 'Riverside', region: 'CA', country: 'US', lat: 33.9533, lng: -117.3962 },
  { city: 'Hillcrest', region: 'CA', country: 'US', lat: 33.7489, lng: -117.1545 },
  { city: 'Fresno', region: 'CA', country: 'US', lat: 36.7378, lng: -119.7871 },
  { city: 'San Bernardino', region: 'CA', country: 'US', lat: 34.1083, lng: -117.2898 },
  { city: 'Corona', region: 'CA', country: 'US', lat: 33.8753, lng: -117.5664 },
  { city: 'Temecula', region: 'CA', country: 'US', lat: 33.4936, lng: -117.1484 },
  { city: 'Ontario', region: 'CA', country: 'US', lat: 34.0633, lng: -117.6509 },
  { city: 'Redlands', region: 'CA', country: 'US', lat: 34.0556, lng: -117.1825 },
];

// ============================================================================
// Helpers
// ============================================================================

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function pickWeighted<T>(items: T[], weights: number[]): T {
  const total = weights.reduce((a, b) => a + b, 0);
  let r = Math.random() * total;
  for (let i = 0; i < items.length; i++) {
    r -= weights[i];
    if (r <= 0) return items[i];
  }
  return items[items.length - 1];
}

function randomBetween(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomTimestamp(day: Date): string {
  const hour = pickWeighted(
    [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
    [1, 2, 3, 5, 4, 3, 5, 4, 3, 4, 8, 10, 12, 15, 12, 8, 3] // peak at 7-9pm
  );
  const minute = randomBetween(0, 59);
  const second = randomBetween(0, 59);
  const d = new Date(day);
  d.setHours(hour, minute, second, randomBetween(0, 999));
  return d.toISOString();
}

function sessionId(): string {
  return `sess-${Math.random().toString(36).slice(2, 10)}-${Date.now()}`;
}

function deviceProps() {
  const browser = pick(BROWSERS);
  const os = pick(OS_LIST);
  const device = os === 'iOS' || os === 'Android'
    ? pickWeighted(['Mobile', 'Tablet'], [4, 1])
    : 'Desktop';
  return {
    $browser: browser,
    $os: os,
    $device_type: device,
    $screen_height: device === 'Mobile' ? 844 : device === 'Tablet' ? 1024 : 1080,
    $screen_width: device === 'Mobile' ? 390 : device === 'Tablet' ? 768 : 1920,
    $browser_version: browser === 'Chrome' ? '124.0' : browser === 'Safari' ? '17.4' : '125.0',
  };
}

// ============================================================================
// Event Builders
// ============================================================================

interface PHEvent {
  event: string;
  properties: Record<string, unknown>;
  timestamp: string;
}

function buildEvent(
  distinct_id: string,
  event: string,
  timestamp: string,
  props: Record<string, unknown> = {}
): PHEvent {
  return {
    event,
    timestamp,
    properties: {
      distinct_id,
      $lib: 'web',
      $lib_version: '1.145.0',
      ...deviceProps(),
      ...geoProps(),
      $referrer: pick(REFERRERS),
      ...props,
    },
  };
}

// ---- User Lifecycle ----

function signupEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const url = `${BASE_URL}/register`;
  return [
    buildEvent(user.distinct_id, '$pageview', timestamp, { $current_url: url, $session_id: sid }),
    buildEvent(user.distinct_id, 'user_signed_up', timestamp, {
      $current_url: url,
      $session_id: sid,
      role: user.role,
      org_name: user.org_name,
      signup_method: pick(['email', 'google', 'apple']),
    }),
    buildEvent(user.distinct_id, '$identify', timestamp, {
      $set: { email: user.email, name: user.name, role: user.role },
    }),
    buildEvent(user.distinct_id, '$groupidentify', timestamp, {
      $group_type: 'organization',
      $group_key: user.org_id,
      $group_set: { name: user.org_name },
    }),
  ];
}

function loginEvent(user: UserProfile, timestamp: string): PHEvent {
  return buildEvent(user.distinct_id, 'user_logged_in', timestamp, {
    $current_url: `${BASE_URL}/login`,
    login_method: pick(['email', 'google', 'apple']),
    role: user.role,
  });
}

function onboardingEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const steps = ['welcome', 'profile_setup', 'org_selection', 'role_assignment', 'complete'];
  const events: PHEvent[] = [];
  const completed = Math.random() > 0.15; // 85% completion rate

  for (let i = 0; i < steps.length; i++) {
    if (!completed && i === randomBetween(2, 4)) break; // drop off
    const t = new Date(new Date(timestamp).getTime() + i * 45000).toISOString();
    events.push(buildEvent(user.distinct_id, 'onboarding_step_completed', t, {
      $current_url: `${BASE_URL}/onboarding/${steps[i]}`,
      $session_id: sid,
      step: i + 1,
      step_name: steps[i],
      total_steps: steps.length,
    }));
  }

  if (completed) {
    events.push(buildEvent(user.distinct_id, 'user_onboarded', timestamp, {
      $current_url: `${BASE_URL}/onboarding/complete`,
      $session_id: sid,
      role: user.role,
      time_to_complete_seconds: randomBetween(90, 300),
    }));
  }

  return events;
}

// ---- Registration Flow ----

function registrationEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const events: PHEvent[] = [];
  const team = pick(TEAMS);
  const league = pick(LEAGUES);

  events.push(buildEvent(user.distinct_id, 'registration_started', timestamp, {
    $current_url: `${BASE_URL}/registration`,
    $session_id: sid,
    league_name: league.name,
    sport: league.sport,
  }));

  // Step 1: Player info (95% continue)
  if (Math.random() < 0.95) {
    const t1 = new Date(new Date(timestamp).getTime() + 60000).toISOString();
    events.push(buildEvent(user.distinct_id, 'registration_step_completed', t1, {
      $current_url: `${BASE_URL}/registration/step-1`,
      $session_id: sid,
      step: 1,
      step_name: 'player_info',
    }));

    // Step 2: Team selection (80% continue)
    if (Math.random() < 0.80) {
      const t2 = new Date(new Date(timestamp).getTime() + 180000).toISOString();
      events.push(buildEvent(user.distinct_id, 'registration_step_completed', t2, {
        $current_url: `${BASE_URL}/registration/step-2`,
        $session_id: sid,
        step: 2,
        step_name: 'team_selection',
        team_name: team.name,
      }));

      // Step 3: Waiver/medical (70% continue)
      if (Math.random() < 0.70) {
        const t3 = new Date(new Date(timestamp).getTime() + 300000).toISOString();
        events.push(buildEvent(user.distinct_id, 'registration_step_completed', t3, {
          $current_url: `${BASE_URL}/registration/step-3`,
          $session_id: sid,
          step: 3,
          step_name: 'waiver_medical',
        }));

        // Payment (85% of those who reach it)
        if (Math.random() < 0.85) {
          const t4 = new Date(new Date(timestamp).getTime() + 420000).toISOString();
          const paymentSuccess = Math.random() < 0.92; // 8% payment failure rate

          events.push(buildEvent(user.distinct_id, 'payment_initiated', t4, {
            $current_url: `${BASE_URL}/registration/payment`,
            $session_id: sid,
            amount_cents: pick([7500, 10000, 12500, 15000, 20000]),
            payment_method: pick(['credit_card', 'debit_card', 'apple_pay']),
          }));

          if (paymentSuccess) {
            const t5 = new Date(new Date(timestamp).getTime() + 425000).toISOString();
            events.push(
              buildEvent(user.distinct_id, 'payment_completed', t5, {
                $current_url: `${BASE_URL}/registration/payment`,
                $session_id: sid,
                success: true,
                amount_cents: 10000,
              }),
              buildEvent(user.distinct_id, 'registration_completed', t5, {
                $current_url: `${BASE_URL}/registration/confirmation`,
                $session_id: sid,
                league_name: league.name,
                team_name: team.name,
                sport: league.sport,
              })
            );
          } else {
            events.push(buildEvent(user.distinct_id, 'payment_failed', t4, {
              $current_url: `${BASE_URL}/registration/payment`,
              $session_id: sid,
              error: pick(['card_declined', 'insufficient_funds', 'expired_card', 'processing_error']),
            }));
          }
        }
      }
    }
  }

  return events;
}

// ---- Anonymous visitor funnel (visits register page but doesn't sign up) ----

function anonVisitEvents(anonId: string, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const pages = ['/'];
  if (Math.random() > 0.3) pages.push('/register');
  if (Math.random() > 0.6) pages.push('/register');

  return pages.map((page, i) => {
    const t = new Date(new Date(timestamp).getTime() + i * 30000).toISOString();
    return buildEvent(anonId, '$pageview', t, {
      $current_url: `${BASE_URL}${page}`,
      $session_id: sid,
    });
  });
}

// ---- Team & Schedule ----

function teamManagementEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const events: PHEvent[] = [];
  const team = pick(TEAMS);
  const sid = sessionId();

  if (user.role === 'coach' || user.role === 'commissioner') {
    const action = pick(['roster_updated', 'practice_scheduled', 'lineup_set', 'team_settings_updated']);
    events.push(buildEvent(user.distinct_id, action, timestamp, {
      $current_url: `${BASE_URL}/teams/${team.id}`,
      $session_id: sid,
      team_name: team.name,
      sport: team.sport,
    }));
  }

  // Everyone can view teams
  events.push(buildEvent(user.distinct_id, 'team_viewed', timestamp, {
    $current_url: `${BASE_URL}/teams/${team.id}`,
    $session_id: sid,
    team_name: team.name,
  }));

  return events;
}

function scheduleEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const events: PHEvent[] = [];
  const team = pick(TEAMS);
  const sid = sessionId();
  const eventType = pick(['game', 'practice', 'tournament']);

  events.push(buildEvent(user.distinct_id, 'schedule_viewed', timestamp, {
    $current_url: `${BASE_URL}/schedule`,
    $session_id: sid,
    view_type: pick(['calendar', 'list']),
  }));

  if (user.role === 'guardian' || user.role === 'player') {
    events.push(buildEvent(user.distinct_id, 'event_rsvp_submitted', timestamp, {
      $current_url: `${BASE_URL}/schedule/event-${randomBetween(1, 50)}`,
      $session_id: sid,
      event_type: eventType,
      team_name: team.name,
      rsvp_status: pickWeighted(['attending', 'not_attending', 'maybe'], [7, 2, 1]),
    }));
  }

  if (user.role === 'coach') {
    events.push(buildEvent(user.distinct_id, 'event_created', timestamp, {
      $current_url: `${BASE_URL}/schedule/new`,
      $session_id: sid,
      event_type: eventType,
      team_name: team.name,
    }));
  }

  return events;
}

function gameScoreEvents(user: UserProfile, timestamp: string): PHEvent[] {
  if (user.role !== 'coach' && user.role !== 'commissioner') return [];

  const team = pick(TEAMS);
  const opponent = pick(TEAMS.filter(t => t.id !== team.id));
  const homeScore = randomBetween(0, 8);
  const awayScore = randomBetween(0, 8);

  return [buildEvent(user.distinct_id, 'game_score_submitted', timestamp, {
    $current_url: `${BASE_URL}/schedule/game-${randomBetween(1, 50)}`,
    home_team: team.name,
    away_team: opponent.name,
    home_score: homeScore,
    away_score: awayScore,
    sport: team.sport,
  })];
}

// ---- Messaging ----

function messageEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const events: PHEvent[] = [];

  events.push(buildEvent(user.distinct_id, 'messages_viewed', timestamp, {
    $current_url: `${BASE_URL}/messages`,
    $session_id: sid,
    unread_count: randomBetween(0, 12),
  }));

  if (Math.random() > 0.4) {
    events.push(buildEvent(user.distinct_id, 'message_sent', timestamp, {
      $current_url: `${BASE_URL}/messages`,
      $session_id: sid,
      message_type: pick(['direct', 'team_chat', 'announcement']),
      recipient_role: pick(['coach', 'guardian', 'player', 'commissioner']),
    }));
  }

  if (user.role === 'coach' || user.role === 'commissioner') {
    if (Math.random() > 0.7) {
      events.push(buildEvent(user.distinct_id, 'announcement_created', timestamp, {
        $current_url: `${BASE_URL}/messages/announcements/new`,
        $session_id: sid,
        audience: pick(['team', 'league', 'organization']),
        team_name: pick(TEAMS).name,
      }));
    }
  }

  return events;
}

// ---- Portal Views ----

function portalEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const portalMap: Record<string, string> = {
    coach: 'coach-portal',
    guardian: 'parent-portal',
    player: 'player-portal',
    commissioner: 'league-management',
    admin: 'dashboard',
  };

  const portal = portalMap[user.role] || 'dashboard';

  const events: PHEvent[] = [
    buildEvent(user.distinct_id, `${portal.replace('-', '_')}_viewed`, timestamp, {
      $current_url: `${BASE_URL}/${portal}`,
      $session_id: sid,
    }),
  ];

  // Portal-specific actions
  if (user.role === 'coach') {
    if (Math.random() > 0.5) {
      events.push(buildEvent(user.distinct_id, 'attendance_recorded', timestamp, {
        $current_url: `${BASE_URL}/coach-portal/attendance`,
        $session_id: sid,
        team_name: pick(TEAMS).name,
        present_count: randomBetween(6, 12),
        absent_count: randomBetween(0, 3),
      }));
    }
  }

  if (user.role === 'guardian') {
    if (Math.random() > 0.6) {
      events.push(buildEvent(user.distinct_id, 'child_schedule_viewed', timestamp, {
        $current_url: `${BASE_URL}/parent-portal/schedule`,
        $session_id: sid,
      }));
    }
    if (Math.random() > 0.8) {
      events.push(buildEvent(user.distinct_id, 'medical_info_updated', timestamp, {
        $current_url: `${BASE_URL}/parent-portal/medical`,
        $session_id: sid,
      }));
    }
  }

  if (user.role === 'commissioner') {
    if (Math.random() > 0.5) {
      events.push(buildEvent(user.distinct_id, 'standings_updated', timestamp, {
        $current_url: `${BASE_URL}/league-management/standings`,
        $session_id: sid,
        league_name: pick(LEAGUES).name,
      }));
    }
    if (Math.random() > 0.7) {
      events.push(buildEvent(user.distinct_id, 'season_settings_updated', timestamp, {
        $current_url: `${BASE_URL}/league-management/settings`,
        $session_id: sid,
      }));
    }
  }

  return events;
}

// ---- Standings ----

function standingsEvents(user: UserProfile, timestamp: string): PHEvent[] {
  return [
    buildEvent(user.distinct_id, 'standings_viewed', timestamp, {
      $current_url: `${BASE_URL}/standings`,
      league_name: pick(LEAGUES).name,
      sport: pick(['soccer', 'baseball', 'basketball']),
    }),
  ];
}

// ---- Profile ----

function profileEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const events: PHEvent[] = [
    buildEvent(user.distinct_id, 'profile_viewed', timestamp, {
      $current_url: `${BASE_URL}/profile`,
    }),
  ];

  if (Math.random() > 0.7) {
    events.push(buildEvent(user.distinct_id, 'profile_updated', timestamp, {
      $current_url: `${BASE_URL}/profile/edit`,
      fields_changed: pick([
        ['phone'], ['address'], ['phone', 'address'],
        ['emergency_contact'], ['profile_photo'],
      ]),
    }));
  }

  return events;
}

// ---- Calendar / Export ----

function calendarEvents(user: UserProfile, timestamp: string): PHEvent[] {
  if (Math.random() > 0.3) return [];
  return [
    buildEvent(user.distinct_id, 'calendar_exported', timestamp, {
      $current_url: `${BASE_URL}/schedule`,
      export_type: pick(['ical', 'google_calendar', 'outlook']),
    }),
  ];
}

// ---- Search ----

function searchEvents(user: UserProfile, timestamp: string): PHEvent[] {
  if (Math.random() > 0.3) return [];
  const query = pick([
    'eagles', 'schedule saturday', 'coach smith', 'registration', 'payment',
    'standings', 'practice time', 'field location', 'thunder fc', 'vipers',
  ]);
  return [
    buildEvent(user.distinct_id, 'search_performed', timestamp, {
      $current_url: `${BASE_URL}/search`,
      query,
      results_count: randomBetween(0, 15),
    }),
  ];
}

// ---- Pageviews (general browsing) ----

function browsingEvents(user: UserProfile, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const pageCount = randomBetween(2, 6);
  const events: PHEvent[] = [];

  for (let i = 0; i < pageCount; i++) {
    const page = pick(PAGES).replace(':id', String(randomBetween(1, 50)));
    const t = new Date(new Date(timestamp).getTime() + i * randomBetween(15000, 120000)).toISOString();
    events.push(buildEvent(user.distinct_id, '$pageview', t, {
      $current_url: `${BASE_URL}${page}`,
      $session_id: sid,
      $referrer: i === 0 ? pick(REFERRERS) : `${BASE_URL}${pick(PAGES)}`,
    }));
  }

  return events;
}

// ---- Feature Flags & Experiments ----

function featureFlagEvents(user: UserProfile, timestamp: string): PHEvent[] {
  if (Math.random() > 0.2) return [];
  return [
    buildEvent(user.distinct_id, '$feature_flag_called', timestamp, {
      $feature_flag: pick([
        'new-registration-flow', 'dark-mode', 'enhanced-schedule-view',
        'team-chat-v2', 'payment-apple-pay', 'mobile-push-notifications',
      ]),
      $feature_flag_response: pick([true, false]),
    }),
  ];
}

// ---- Error events ----

function errorEvents(user: UserProfile, timestamp: string): PHEvent[] {
  if (Math.random() > 0.08) return []; // ~8% sessions have errors

  const errors = [
    { type: 'TypeError', message: "Cannot read properties of undefined (reading 'team_id')", url: '/teams' },
    { type: 'NetworkError', message: 'Failed to fetch /api/schedule', url: '/schedule' },
    { type: 'TypeError', message: "Cannot read properties of null (reading 'roster')", url: '/coach-portal' },
    { type: 'SyntaxError', message: 'Unexpected token in JSON at position 0', url: '/messages' },
    { type: 'Error', message: 'Payment processing timeout after 30s', url: '/registration/payment' },
    { type: 'RangeError', message: 'Maximum call stack size exceeded', url: '/standings' },
    { type: 'Error', message: 'WebSocket connection failed', url: '/messages' },
    { type: 'TypeError', message: "undefined is not an object (evaluating 'player.stats')", url: '/player-portal' },
  ];

  const error = pick(errors);
  return [
    buildEvent(user.distinct_id, '$exception', timestamp, {
      $current_url: `${BASE_URL}${error.url}`,
      $exception_type: error.type,
      $exception_message: error.message,
      $exception_source: `${BASE_URL}/assets/app.js`,
      $exception_lineno: randomBetween(100, 5000),
      $exception_colno: randomBetween(1, 80),
    }),
  ];
}

// ---- Web Vitals ----

function webVitalsEvents(user: UserProfile, timestamp: string): PHEvent[] {
  if (Math.random() > 0.4) return [];
  const page = pick(PAGES).replace(':id', String(randomBetween(1, 50)));
  return [
    buildEvent(user.distinct_id, '$web_vitals', timestamp, {
      $current_url: `${BASE_URL}${page}`,
      $web_vitals_LCP_value: randomBetween(800, 4500),
      $web_vitals_FID_value: randomBetween(5, 300),
      $web_vitals_CLS_value: Math.random() * 0.3,
      $web_vitals_FCP_value: randomBetween(400, 2500),
      $web_vitals_TTFB_value: randomBetween(50, 800),
    }),
  ];
}

// ---- GA-style: Marketing Attribution & Landing Pages ----

function utmProps(): Record<string, unknown> {
  // ~40% of sessions have UTM params, rest are direct/organic
  if (Math.random() > 0.4) {
    return {
      utm_source: 'direct',
      utm_medium: '(none)',
      $initial_referrer: '',
      $initial_referring_domain: '$direct',
    };
  }
  const campaign = pick(UTM_CAMPAIGNS);
  const refUrls = GA_REFERRER_URLS[campaign.utm_source] || [''];
  const props: Record<string, unknown> = {
    utm_source: campaign.utm_source,
    utm_medium: campaign.utm_medium,
    $initial_referrer: pick(refUrls),
    $initial_referring_domain: campaign.utm_source === 'email' ? '$direct' : `www.${campaign.utm_source}.com`,
  };
  if (campaign.utm_campaign) props.utm_campaign = campaign.utm_campaign;
  if (campaign.utm_content) props.utm_content = campaign.utm_content;
  if (campaign.utm_term) props.utm_term = campaign.utm_term;
  return props;
}

function geoProps(): Record<string, unknown> {
  const geo = pick(CITIES);
  return {
    $geoip_city_name: geo.city,
    $geoip_subdivision_1_code: geo.region,
    $geoip_country_code: geo.country,
    $geoip_latitude: geo.lat,
    $geoip_longitude: geo.lng,
    $geoip_time_zone: 'America/Los_Angeles',
  };
}

function marketingPageviewEvents(distinctId: string, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const landing = pick(LANDING_PAGES);
  const utm = utmProps();
  const geo = geoProps();
  const events: PHEvent[] = [];

  // Landing page hit
  events.push(buildEvent(distinctId, '$pageview', timestamp, {
    $current_url: `${MARKETING_URL}${landing}`,
    $session_id: sid,
    $pathname: landing,
    $host: 'www.getteamio.com',
    ...utm,
    ...geo,
    $entry_url: `${MARKETING_URL}${landing}`,
    page_type: landing.startsWith('/blog') ? 'blog' : landing.startsWith('/sports') ? 'sport_landing' : landing.startsWith('/for-') ? 'persona_landing' : 'marketing',
  }));

  // Internal navigation from marketing -> app
  if (Math.random() > 0.5) {
    const nextPage = pick(['/', '/features', '/pricing', '/register']);
    const t2 = new Date(new Date(timestamp).getTime() + randomBetween(20000, 180000)).toISOString();
    events.push(buildEvent(distinctId, '$pageview', t2, {
      $current_url: `${MARKETING_URL}${nextPage}`,
      $session_id: sid,
      $pathname: nextPage,
      $host: 'www.getteamio.com',
      ...utm,
      ...geo,
      $referrer: `${MARKETING_URL}${landing}`,
    }));
  }

  // $pageleave
  const leaveT = new Date(new Date(timestamp).getTime() + randomBetween(10000, 600000)).toISOString();
  events.push(buildEvent(distinctId, '$pageleave', leaveT, {
    $current_url: `${MARKETING_URL}${landing}`,
    $session_id: sid,
    $pathname: landing,
    ...utm,
    ...geo,
  }));

  return events;
}

// ---- GA-style: Scroll Depth ----

function scrollDepthEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.5) return [];
  const sid = sessionId();
  const page = pick(PAGES).replace(':id', String(randomBetween(1, 50)));
  const depths = [25, 50, 75, 90, 100];
  const maxDepth = pickWeighted(depths, [5, 15, 30, 30, 20]);
  const events: PHEvent[] = [];

  for (const depth of depths) {
    if (depth > maxDepth) break;
    const t = new Date(new Date(timestamp).getTime() + depth * 300).toISOString();
    events.push(buildEvent(distinctId, 'scroll_depth_reached', t, {
      $current_url: `${BASE_URL}${page}`,
      $session_id: sid,
      depth_percent: depth,
      page_path: page,
    }));
  }

  return events;
}

// ---- GA-style: Engagement Time (time on page) ----

function engagementTimeEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.4) return [];
  const page = pick(PAGES).replace(':id', String(randomBetween(1, 50)));
  const engagementMs = randomBetween(5000, 600000); // 5s to 10min
  const leaveT = new Date(new Date(timestamp).getTime() + engagementMs).toISOString();

  return [
    buildEvent(distinctId, '$pageleave', leaveT, {
      $current_url: `${BASE_URL}${page}`,
      $pathname: page,
      $prev_pageview_pathname: pick(PAGES).replace(':id', String(randomBetween(1, 50))),
      engagement_time_ms: engagementMs,
      scroll_depth_percent: pickWeighted([25, 50, 75, 100], [10, 25, 35, 30]),
    }),
  ];
}

// ---- GA-style: Outbound Link Clicks ----

function outboundClickEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.15) return [];
  const links = [
    { url: 'https://maps.google.com/maps?q=Central+Park+Field', label: 'Get Directions' },
    { url: 'https://www.ussoccer.com/coaching-education', label: 'USSF Coaching Cert' },
    { url: 'https://www.littleleague.org/rules', label: 'Little League Rules' },
    { url: 'https://stripe.com/receipts/payment_123', label: 'View Receipt' },
    { url: 'https://support.getteamio.com', label: 'Help Center' },
    { url: 'https://apps.apple.com/app/teamio', label: 'Download iOS App' },
    { url: 'https://play.google.com/store/apps/details?id=com.teamio', label: 'Download Android App' },
  ];
  const link = pick(links);

  return [
    buildEvent(distinctId, 'outbound_link_clicked', timestamp, {
      $current_url: `${BASE_URL}${pick(PAGES).replace(':id', '1')}`,
      link_url: link.url,
      link_text: link.label,
      link_domain: new URL(link.url).hostname,
    }),
  ];
}

// ---- GA-style: CTA / Conversion Events ----

function ctaClickEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.3) return [];
  const ctas = [
    { name: 'register_now_hero', location: 'hero_section', page: '/' },
    { name: 'register_now_banner', location: 'top_banner', page: '/dashboard' },
    { name: 'view_schedule_cta', location: 'dashboard_widget', page: '/dashboard' },
    { name: 'invite_player_cta', location: 'team_detail', page: '/teams/1' },
    { name: 'upgrade_plan_cta', location: 'settings', page: '/settings/billing' },
    { name: 'download_app_cta', location: 'footer', page: '/' },
    { name: 'contact_support_cta', location: 'help_menu', page: '/help' },
    { name: 'share_team_link', location: 'team_detail', page: '/teams/1' },
    { name: 'export_roster_cta', location: 'coach_portal', page: '/coach-portal' },
    { name: 'view_pricing_cta', location: 'features_page', page: '/features' },
  ];
  const cta = pick(ctas);

  return [
    buildEvent(distinctId, 'cta_clicked', timestamp, {
      $current_url: `${MARKETING_URL}${cta.page}`,
      cta_name: cta.name,
      cta_location: cta.location,
      page_path: cta.page,
    }),
  ];
}

// ---- GA-style: File Downloads ----

function fileDownloadEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.1) return [];
  const files = [
    { name: 'spring-2026-schedule.pdf', type: 'pdf', category: 'schedule' },
    { name: 'team-roster-eagles.csv', type: 'csv', category: 'roster' },
    { name: 'registration-waiver.pdf', type: 'pdf', category: 'registration' },
    { name: 'coaches-handbook-2026.pdf', type: 'pdf', category: 'resources' },
    { name: 'field-map-central-park.png', type: 'image', category: 'maps' },
    { name: 'league-rules-soccer.pdf', type: 'pdf', category: 'rules' },
  ];
  const file = pick(files);

  return [
    buildEvent(distinctId, 'file_downloaded', timestamp, {
      $current_url: `${BASE_URL}${pick(PAGES).replace(':id', '1')}`,
      file_name: file.name,
      file_type: file.type,
      file_category: file.category,
    }),
  ];
}

// ---- GA-style: Form Interactions ----

function formInteractionEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.25) return [];
  const sid = sessionId();
  const forms = [
    { name: 'contact_form', page: '/contact', fields: 5 },
    { name: 'feedback_form', page: '/feedback', fields: 4 },
    { name: 'player_info_form', page: '/registration/step-1', fields: 8 },
    { name: 'team_request_form', page: '/teams/join', fields: 3 },
    { name: 'profile_edit_form', page: '/profile/edit', fields: 6 },
    { name: 'event_creation_form', page: '/schedule/new', fields: 7 },
  ];
  const form = pick(forms);
  const events: PHEvent[] = [];

  events.push(buildEvent(distinctId, 'form_started', timestamp, {
    $current_url: `${BASE_URL}${form.page}`,
    $session_id: sid,
    form_name: form.name,
    field_count: form.fields,
  }));

  // 70% submit, 30% abandon
  if (Math.random() < 0.7) {
    const submitT = new Date(new Date(timestamp).getTime() + randomBetween(30000, 300000)).toISOString();
    events.push(buildEvent(distinctId, 'form_submitted', submitT, {
      $current_url: `${BASE_URL}${form.page}`,
      $session_id: sid,
      form_name: form.name,
      time_to_submit_seconds: randomBetween(30, 300),
    }));
  } else {
    const abandonT = new Date(new Date(timestamp).getTime() + randomBetween(10000, 120000)).toISOString();
    events.push(buildEvent(distinctId, 'form_abandoned', abandonT, {
      $current_url: `${BASE_URL}${form.page}`,
      $session_id: sid,
      form_name: form.name,
      last_field_interacted: pick(['name', 'email', 'phone', 'address', 'date_of_birth']),
      fields_completed: randomBetween(1, form.fields - 1),
    }));
  }

  return events;
}

// ---- GA-style: Social Sharing ----

function socialShareEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.1) return [];
  const platforms = ['facebook', 'twitter', 'whatsapp', 'sms', 'copy_link', 'email'];
  const content = pick([
    { type: 'team_page', title: 'Riverside Eagles' },
    { type: 'schedule', title: 'Spring 2026 Schedule' },
    { type: 'standings', title: 'Youth Soccer Standings' },
    { type: 'registration', title: 'Join our league!' },
    { type: 'game_result', title: 'Eagles 3 - Thunder 1' },
  ]);

  return [
    buildEvent(distinctId, 'content_shared', timestamp, {
      $current_url: `${BASE_URL}/${content.type}`,
      share_platform: pick(platforms),
      content_type: content.type,
      content_title: content.title,
    }),
  ];
}

// ---- GA-style: Notification Interactions ----

function notificationEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.2) return [];
  const types = [
    { type: 'push', category: 'game_reminder', action: pick(['opened', 'dismissed']) },
    { type: 'push', category: 'schedule_change', action: pick(['opened', 'dismissed']) },
    { type: 'email', category: 'weekly_digest', action: pick(['opened', 'clicked', 'unsubscribed']) },
    { type: 'email', category: 'registration_confirmation', action: 'opened' },
    { type: 'in_app', category: 'new_message', action: pick(['clicked', 'dismissed']) },
    { type: 'in_app', category: 'payment_due', action: pick(['clicked', 'dismissed', 'snoozed']) },
    { type: 'sms', category: 'game_cancelled', action: 'delivered' },
  ];
  const notif = pick(types);

  return [
    buildEvent(distinctId, 'notification_interacted', timestamp, {
      notification_type: notif.type,
      notification_category: notif.category,
      notification_action: notif.action,
    }),
  ];
}

// ---- GA-style: Session tracking (session_start / session_end) ----

function sessionTrackingEvents(distinctId: string, timestamp: string): PHEvent[] {
  const sid = sessionId();
  const utm = utmProps();
  const geo = geoProps();
  const landing = pick(PAGES).replace(':id', String(randomBetween(1, 50)));
  const sessionDurationMs = randomBetween(30000, 1800000); // 30s to 30min
  const pageCount = randomBetween(1, 12);
  const endTs = new Date(new Date(timestamp).getTime() + sessionDurationMs).toISOString();

  return [
    buildEvent(distinctId, 'session_started', timestamp, {
      $session_id: sid,
      $current_url: `${BASE_URL}${landing}`,
      $entry_url: `${BASE_URL}${landing}`,
      ...utm,
      ...geo,
      is_returning_user: Math.random() > 0.3,
      days_since_last_session: randomBetween(0, 14),
    }),
    buildEvent(distinctId, 'session_ended', endTs, {
      $session_id: sid,
      session_duration_seconds: Math.floor(sessionDurationMs / 1000),
      pageview_count: pageCount,
      event_count: pageCount + randomBetween(2, 10),
      exit_page: `${BASE_URL}${pick(PAGES).replace(':id', String(randomBetween(1, 50)))}`,
      is_bounce: pageCount === 1,
    }),
  ];
}

// ---- GA-style: Ecommerce / Revenue ----

function ecommerceEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.15) return [];
  const sid = sessionId();
  const items = [
    { id: 'reg-soccer-spring', name: 'Youth Soccer Spring Registration', category: 'registration', price: 75.00 },
    { id: 'reg-soccer-fall', name: 'Youth Soccer Fall Registration', category: 'registration', price: 75.00 },
    { id: 'reg-baseball-travel', name: '12U Travel Baseball Registration', category: 'registration', price: 200.00 },
    { id: 'reg-basketball-winter', name: 'Adult Basketball Winter Registration', category: 'registration', price: 50.00 },
    { id: 'jersey-custom', name: 'Custom Team Jersey', category: 'merchandise', price: 35.00 },
    { id: 'tournament-entry', name: 'Spring Tournament Entry Fee', category: 'tournament', price: 150.00 },
    { id: 'field-rental', name: 'Field Rental - 2 Hours', category: 'facility', price: 100.00 },
  ];
  const item = pick(items);
  const qty = item.category === 'registration' ? 1 : randomBetween(1, 3);
  const total = item.price * qty;
  const events: PHEvent[] = [];

  // View item
  events.push(buildEvent(distinctId, 'product_viewed', timestamp, {
    $current_url: `${BASE_URL}/registration`,
    $session_id: sid,
    item_id: item.id,
    item_name: item.name,
    item_category: item.category,
    price: item.price,
    currency: 'USD',
  }));

  // Add to cart (80%)
  if (Math.random() < 0.8) {
    const t2 = new Date(new Date(timestamp).getTime() + 60000).toISOString();
    events.push(buildEvent(distinctId, 'item_added_to_cart', t2, {
      $current_url: `${BASE_URL}/registration/payment`,
      $session_id: sid,
      item_id: item.id,
      item_name: item.name,
      item_category: item.category,
      quantity: qty,
      price: item.price,
      cart_total: total,
      currency: 'USD',
    }));

    // Begin checkout (70%)
    if (Math.random() < 0.7) {
      const t3 = new Date(new Date(timestamp).getTime() + 120000).toISOString();
      events.push(buildEvent(distinctId, 'checkout_started', t3, {
        $current_url: `${BASE_URL}/registration/payment`,
        $session_id: sid,
        cart_total: total,
        item_count: qty,
        currency: 'USD',
        payment_method: pick(['credit_card', 'debit_card', 'apple_pay', 'google_pay']),
      }));

      // Purchase (85%)
      if (Math.random() < 0.85) {
        const t4 = new Date(new Date(timestamp).getTime() + 180000).toISOString();
        events.push(buildEvent(distinctId, 'purchase_completed', t4, {
          $current_url: `${BASE_URL}/registration/confirmation`,
          $session_id: sid,
          transaction_id: `txn-${Math.random().toString(36).slice(2, 10)}`,
          revenue: total,
          currency: 'USD',
          item_count: qty,
          items: [{ id: item.id, name: item.name, category: item.category, price: item.price, quantity: qty }],
          payment_method: pick(['credit_card', 'debit_card', 'apple_pay', 'google_pay']),
          coupon_code: Math.random() > 0.8 ? pick(['SPRING20', 'EARLYBIRD', 'SIBLING10', 'REFERRAL15']) : undefined,
          discount_amount: Math.random() > 0.8 ? Math.round(total * 0.15 * 100) / 100 : 0,
        }));
      }
    }
  }

  return events;
}

// ---- GA-style: Site Search (enhanced) ----

function siteSearchEvents(distinctId: string, timestamp: string): PHEvent[] {
  if (Math.random() > 0.2) return [];
  const sid = sessionId();
  const queries = [
    { q: 'soccer registration', category: 'registration', results: randomBetween(2, 8) },
    { q: 'practice schedule', category: 'schedule', results: randomBetween(3, 15) },
    { q: 'coach contact', category: 'people', results: randomBetween(1, 5) },
    { q: 'payment receipt', category: 'billing', results: randomBetween(0, 3) },
    { q: 'field directions', category: 'facilities', results: randomBetween(1, 4) },
    { q: 'eagles roster', category: 'teams', results: randomBetween(1, 2) },
    { q: 'tournament dates', category: 'events', results: randomBetween(0, 6) },
    { q: 'refund policy', category: 'help', results: randomBetween(0, 2) },
  ];
  const search = pick(queries);
  const events: PHEvent[] = [];

  events.push(buildEvent(distinctId, 'site_search_performed', timestamp, {
    $current_url: `${BASE_URL}/search?q=${encodeURIComponent(search.q)}`,
    $session_id: sid,
    search_query: search.q,
    search_category: search.category,
    results_count: search.results,
    has_results: search.results > 0,
  }));

  // Click on result (60% if results exist)
  if (search.results > 0 && Math.random() < 0.6) {
    const t2 = new Date(new Date(timestamp).getTime() + randomBetween(3000, 15000)).toISOString();
    events.push(buildEvent(distinctId, 'search_result_clicked', t2, {
      $current_url: `${BASE_URL}/search?q=${encodeURIComponent(search.q)}`,
      $session_id: sid,
      search_query: search.q,
      result_position: randomBetween(1, Math.min(search.results, 5)),
      result_type: search.category,
    }));
  }

  return events;
}

// ============================================================================
// PostHog Batch API
// ============================================================================

async function sendBatch(events: PHEvent[]): Promise<void> {
  const BATCH_SIZE = 500;

  for (let i = 0; i < events.length; i += BATCH_SIZE) {
    const batch = events.slice(i, i + BATCH_SIZE);
    const payload = {
      api_key: PH_KEY,
      batch: batch.map(e => ({
        event: e.event,
        properties: e.properties,
        timestamp: e.timestamp,
      })),
    };

    const res = await fetch(`${PH_HOST}/batch/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error(`  Batch failed (${res.status}): ${text.slice(0, 200)}`);
    } else {
      console.log(`  Sent batch ${Math.floor(i / BATCH_SIZE) + 1}: ${batch.length} events`);
    }

    // Small delay between batches to avoid rate limiting
    if (i + BATCH_SIZE < events.length) {
      await new Promise(r => setTimeout(r, 200));
    }
  }
}

// ============================================================================
// Main: Generate and send events
// ============================================================================

async function main() {
  console.log(`
╔═══════════════════════════════════════════╗
║     PostHog Event Seeder                  ║
║     Generating ${SEED_DAYS} days of events          ║
╚═══════════════════════════════════════════╝
`);

  if (!PH_KEY) {
    console.error('Missing POSTHOG_API_KEY (or VITE_PUBLIC_POSTHOG_KEY)');
    process.exit(1);
  }

  console.log(`PostHog host: ${PH_HOST}`);
  console.log(`Days to seed: ${SEED_DAYS}`);
  console.log(`Events/day target: ~${EVENTS_PER_DAY}`);
  console.log(`Users: ${USERS.length} registered + ${ANON_VISITORS.length} anonymous\n`);

  const allEvents: PHEvent[] = [];
  const now = new Date();

  // Phase 1: Identify all users (once, at start of period)
  console.log('Phase 1: User identifications & signups...');
  for (const user of USERS) {
    const dayOffset = randomBetween(SEED_DAYS - 5, SEED_DAYS);
    const day = new Date(now);
    day.setDate(day.getDate() - dayOffset);
    const ts = randomTimestamp(day);

    allEvents.push(...signupEvents(user, ts));

    // Onboarding (slightly later)
    const obTs = new Date(new Date(ts).getTime() + randomBetween(60000, 600000)).toISOString();
    allEvents.push(...onboardingEvents(user, obTs));
  }

  // Phase 2: Daily activity
  console.log('Phase 2: Generating daily activity...');
  for (let d = SEED_DAYS; d >= 0; d--) {
    const day = new Date(now);
    day.setDate(day.getDate() - d);

    // Weekend multiplier (more activity on weekends for sports)
    const dayOfWeek = day.getDay();
    const weekendMultiplier = (dayOfWeek === 0 || dayOfWeek === 6) ? 1.5 : 1.0;
    const targetEvents = Math.floor(EVENTS_PER_DAY * weekendMultiplier * (0.8 + Math.random() * 0.4));
    let dayEventCount = 0;

    // Active users for the day (not everyone logs in every day)
    const activeUsers = USERS.filter(() => Math.random() < 0.6);
    const activeAnons = ANON_VISITORS.filter(() => Math.random() < 0.25);

    for (const user of activeUsers) {
      const ts = randomTimestamp(day);

      // Login
      allEvents.push(loginEvent(user, ts));
      dayEventCount++;

      // Browsing session
      allEvents.push(...browsingEvents(user, ts));

      // Role-based activities (weighted by role)
      if (Math.random() > 0.3) {
        allEvents.push(...scheduleEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.5) {
        allEvents.push(...messageEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.4) {
        allEvents.push(...portalEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.6) {
        allEvents.push(...teamManagementEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.7) {
        allEvents.push(...standingsEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.8) {
        allEvents.push(...profileEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.85) {
        allEvents.push(...searchEvents(user, randomTimestamp(day)));
      }
      if (Math.random() > 0.9) {
        allEvents.push(...calendarEvents(user, randomTimestamp(day)));
      }

      // Game scores on weekends
      if ((dayOfWeek === 0 || dayOfWeek === 6) && Math.random() > 0.5) {
        allEvents.push(...gameScoreEvents(user, randomTimestamp(day)));
      }

      // Registration events (guardians registering kids)
      if (user.role === 'guardian' && d > 20 && Math.random() > 0.6) {
        allEvents.push(...registrationEvents(user, randomTimestamp(day)));
      }

      // Errors & web vitals
      allEvents.push(...errorEvents(user, randomTimestamp(day)));
      allEvents.push(...webVitalsEvents(user, randomTimestamp(day)));
      allEvents.push(...featureFlagEvents(user, randomTimestamp(day)));

      // GA-style: marketing attribution, engagement, conversions
      if (Math.random() > 0.7) {
        allEvents.push(...marketingPageviewEvents(user.distinct_id, randomTimestamp(day)));
      }
      allEvents.push(...sessionTrackingEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...scrollDepthEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...engagementTimeEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...outboundClickEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...ctaClickEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...fileDownloadEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...formInteractionEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...socialShareEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...notificationEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...ecommerceEvents(user.distinct_id, randomTimestamp(day)));
      allEvents.push(...siteSearchEvents(user.distinct_id, randomTimestamp(day)));
    }

    // Anonymous visitors: marketing pages, UTM attribution, partial funnels
    for (const anonId of activeAnons) {
      allEvents.push(...anonVisitEvents(anonId, randomTimestamp(day)));
      allEvents.push(...marketingPageviewEvents(anonId, randomTimestamp(day)));
      allEvents.push(...sessionTrackingEvents(anonId, randomTimestamp(day)));
      allEvents.push(...scrollDepthEvents(anonId, randomTimestamp(day)));
      allEvents.push(...engagementTimeEvents(anonId, randomTimestamp(day)));
      allEvents.push(...ctaClickEvents(anonId, randomTimestamp(day)));
      allEvents.push(...siteSearchEvents(anonId, randomTimestamp(day)));
    }

    if (d % 5 === 0) {
      console.log(`  Day -${d}: ${activeUsers.length} active users, ${activeAnons.length} anon visitors`);
    }
  }

  // Sort by timestamp
  allEvents.sort((a, b) => a.timestamp.localeCompare(b.timestamp));

  console.log(`\nTotal events generated: ${allEvents.length}`);
  console.log(`Unique event types: ${new Set(allEvents.map(e => e.event)).size}`);
  console.log(`\nEvent breakdown:`);

  const counts = new Map<string, number>();
  for (const e of allEvents) {
    counts.set(e.event, (counts.get(e.event) || 0) + 1);
  }
  for (const [event, count] of [...counts.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`  ${event}: ${count}`);
  }

  // Send to PostHog
  console.log(`\nSending to PostHog (${PH_HOST})...`);
  await sendBatch(allEvents);

  console.log('\nDone! Events should appear in PostHog within a few minutes.');
}

main().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
