import { chromium, Browser, Page } from 'playwright';
import { config } from './config.js';
import { Crawler } from './crawler.js';
import { FormFuzzer } from './form-fuzzer.js';
import { Reporter } from './reporter.js';
import { AiAnalyzer } from './ai-analyzer.js';
import { PostHogCollector } from './posthog-collector.js';

const BANNER = `
╔═══════════════════════════════════════════╗
║       TeamIO QA Chaos Agent               ║
║       Crawl • Fuzz • Report               ║
╚═══════════════════════════════════════════╝
`;

async function login(page: Page, role: 'admin' | 'coach' | 'parent') {
  const user = config.users[role];
  console.log(`  🔑 Logging in as ${role} (${user.email})`);

  // Log in via API directly, then inject tokens into localStorage
  // This is more reliable than filling the form in an SPA
  try {
    const apiUrl = config.apiUrl || config.baseUrl;
    const res = await page.request.post(`${apiUrl}/api/auth/login`, {
      data: { email: user.email, password: user.password },
    });

    if (!res.ok()) {
      console.log(`  ❌ Login API returned ${res.status()}`);
      return false;
    }

    const data = await res.json() as { access_token: string; refresh_token: string; user: { role: string } };

    // Inject tokens into localStorage (same as the app does on login)
    await page.goto(config.baseUrl, { waitUntil: 'domcontentloaded', timeout: 10000 });
    await page.evaluate((tokens) => {
      localStorage.setItem('access_token', tokens.access_token);
      localStorage.setItem('refresh_token', tokens.refresh_token);
    }, data);

    // Navigate to dashboard (or wherever the role goes)
    await page.goto(`${config.baseUrl}/dashboard`, { waitUntil: 'networkidle', timeout: 15000 });
    console.log(`  ✅ Logged in as ${role} → ${page.url().replace(config.baseUrl, '')}`);
    return true;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.log(`  ❌ Login failed for ${role}: ${msg.slice(0, 100)}`);
    return false;
  }
}

async function runCycle(
  page: Page,
  reporter: Reporter,
  aiAnalyzer: AiAnalyzer | null,
  role: 'admin' | 'coach' | 'parent',
) {
  console.log(`\n🔄 Starting crawl cycle as "${role}"`);

  // Login
  const loggedIn = await login(page, role);

  // Seed URLs
  const publicUrls = [
    config.baseUrl,
    `${config.baseUrl}/login`,
    `${config.baseUrl}/register`,
    `${config.baseUrl}/discover`,
    `${config.baseUrl}/pricing`,
  ];

  const authUrls = loggedIn ? [
    `${config.baseUrl}/dashboard`,
    `${config.baseUrl}/dashboard/schedule`,
    `${config.baseUrl}/dashboard/leagues`,
    `${config.baseUrl}/dashboard/teams`,
    `${config.baseUrl}/dashboard/registrations`,
    `${config.baseUrl}/dashboard/join-requests`,
    `${config.baseUrl}/dashboard/messages`,
    `${config.baseUrl}/dashboard/fields`,
    `${config.baseUrl}/dashboard/users`,
    `${config.baseUrl}/dashboard/settings`,
    `${config.baseUrl}/dashboard/stats`,
    `${config.baseUrl}/dashboard/reports`,
    `${config.baseUrl}/dashboard/photos`,
    `${config.baseUrl}/dashboard/seasons`,
    `${config.baseUrl}/dashboard/organizations`,
    `${config.baseUrl}/dashboard/payments`,
  ] : [];

  const crawler = new Crawler(page, reporter);
  crawler.seed([...publicUrls, ...authUrls]);

  // Phase 1: Crawl pages
  console.log(`\n📡 Phase 1: Crawling pages (max ${config.maxPagesPerCycle})`);
  let pageCount = 0;

  while (pageCount < config.maxPagesPerCycle && await crawler.crawlNext()) {
    pageCount++;

    // AI screenshot analysis every 5th page
    if (aiAnalyzer && pageCount % 5 === 0) {
      try {
        const screenshot = await page.screenshot({ type: 'png' });
        const title = await page.title();
        await aiAnalyzer.analyzeScreenshot(screenshot, page.url(), title);
      } catch {
        // Screenshot failed, continue
      }
    }
  }

  console.log(`  Crawled ${pageCount} pages (${crawler.queueSize} remaining in queue)`);

  // Phase 2: Fuzz forms on key pages
  console.log(`\n🔧 Phase 2: Fuzzing forms`);
  const fuzzer = new FormFuzzer(page, reporter);

  const formPages = [
    `${config.baseUrl}/register`,
    `${config.baseUrl}/login`,
    `${config.baseUrl}/forgot-password`,
  ];

  if (loggedIn) {
    formPages.push(
      `${config.baseUrl}/dashboard/settings`,
      `${config.baseUrl}/dashboard/organizations`,
    );
  }

  for (const url of formPages) {
    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 10000 });
      await fuzzer.fuzzCurrentPage();
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.log(`  ⚠️  Could not fuzz ${url}: ${msg.slice(0, 100)}`);
    }
  }

  // Phase 3: Rapid random navigation (chaos clicks)
  console.log(`\n🎲 Phase 3: Chaos navigation (random clicks)`);
  if (loggedIn) {
    await page.goto(`${config.baseUrl}/dashboard`, { waitUntil: 'networkidle', timeout: 10000 }).catch(() => {});

    for (let i = 0; i < 20; i++) {
      try {
        // Find all clickable elements
        const clickables = page.locator('a, button, [role="button"], [role="tab"]');
        const count = await clickables.count();
        if (count === 0) break;

        // Pick a random one
        const idx = Math.floor(Math.random() * count);
        const el = clickables.nth(idx);

        // Skip if it looks like logout or destructive
        const text = await el.textContent().catch(() => '');
        const href = await el.getAttribute('href').catch(() => '');
        if (text?.toLowerCase().includes('logout') || text?.toLowerCase().includes('delete') ||
            href?.includes('logout')) {
          continue;
        }

        if (await el.isVisible({ timeout: 500 })) {
          await el.click({ timeout: 2000 });
          await page.waitForTimeout(800);

          // Check for crash
          const body = await page.locator('body').textContent().catch(() => null);
          if (body?.trim() === '' || body === null) {
            reporter.addBug({
              severity: 'error',
              category: 'crash',
              title: `Page crashed after random click`,
              description: `Clicked "${text?.slice(0, 50)}" (${href || 'no href'}) and got blank page`,
              url: page.url(),
            });
            // Navigate back to dashboard
            await page.goto(`${config.baseUrl}/dashboard`, { waitUntil: 'networkidle', timeout: 10000 }).catch(() => {});
          }
        }
      } catch {
        // Random click failed, keep going
      }
    }
  }

  console.log(`  Chaos clicks complete`);
}

async function main() {
  console.log(BANNER);
  const posthogConfigured = !!(process.env.POSTHOG_API_KEY && process.env.POSTHOG_PROJECT_ID);

  console.log(`Target: ${config.baseUrl}`);
  console.log(`Headless: ${config.headless}`);
  console.log(`AI Analysis: ${config.useClaudeAnalysis ? 'enabled' : 'disabled (set ANTHROPIC_API_KEY to enable)'}`);
  console.log(`PostHog: ${posthogConfigured ? 'enabled' : 'disabled (set POSTHOG_API_KEY + POSTHOG_PROJECT_ID to enable)'}`);
  console.log(`Max pages/cycle: ${config.maxPagesPerCycle}`);

  const reporter = new Reporter();
  const aiAnalyzer = config.useClaudeAnalysis ? new AiAnalyzer(reporter) : null;
  const posthog = new PostHogCollector(reporter);

  // Collect PostHog errors before crawling
  if (posthog.isConfigured) {
    await posthog.collect();
  }

  let browser: Browser | null = null;

  // Handle shutdown gracefully
  const shutdown = async () => {
    console.log('\n\n🛑 Shutting down...');
    await reporter.save();
    const stats = reporter.getStats();
    console.log(`\n📊 Summary: ${stats.pagesVisited} pages, ${stats.bugsFound} bugs found`);
    await browser?.close().catch(() => {});
    process.exit(0);
  };

  process.on('SIGINT', () => { shutdown(); });
  process.on('SIGTERM', () => { shutdown(); });

  try {
    browser = await chromium.launch({ headless: config.headless });
    const context = await browser.newContext({
      viewport: { width: 1280, height: 720 },
      // Simulate geolocation for discovery testing
      geolocation: { latitude: 39.7990, longitude: -89.6440 }, // Springfield, IL
      permissions: ['geolocation'],
    });
    const page = await context.newPage();

    const startTime = Date.now();
    let cycleCount = 0;

    // Main loop: cycle through different user roles
    const roles: Array<'admin' | 'coach' | 'parent'> = ['admin', 'parent', 'coach'];

    while (true) {
      const role = roles[cycleCount % roles.length];
      await runCycle(page, reporter, aiAnalyzer, role);
      cycleCount++;

      // Check if we should stop
      if (config.maxDurationMs > 0 && (Date.now() - startTime) > config.maxDurationMs) {
        console.log('\n⏱️  Max duration reached');
        break;
      }

      console.log(`\n💤 Cycle ${cycleCount} complete. Starting next in 3s...`);
      await new Promise(r => setTimeout(r, 3000));
    }
  } catch (err) {
    console.error('Agent error:', err);
  }

  await shutdown();
}

main();
