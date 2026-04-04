/**
 * PostHog QA Reviewer
 *
 * An AI agent that acts as a QA engineer reviewing PostHog data.
 * It queries PostHog for errors, trends, and user friction,
 * then uses Claude to analyze findings and file GitHub issues.
 *
 * Usage:
 *   POSTHOG_API_KEY=phx_... POSTHOG_PROJECT_ID=12345 \
 *   ANTHROPIC_API_KEY=sk-... GH_TOKEN=ghp_... \
 *   npx tsx src/posthog-reviewer.ts
 */

import Anthropic from '@anthropic-ai/sdk';
import { fileBugsAsIssues } from './github-reporter.js';
import type { Bug } from './types.js';

const HOST = process.env.POSTHOG_HOST || 'https://us.i.posthog.com';
const PH_KEY = process.env.POSTHOG_API_KEY || '';
const PROJECT = process.env.POSTHOG_PROJECT_ID || '';
const LOOKBACK = process.env.LOOKBACK_HOURS || '24';

interface QueryResult {
  results: unknown[][];
  columns: string[];
}

// ============================================================================
// PostHog Queries
// ============================================================================

async function hogql(query: string): Promise<QueryResult | null> {
  const res = await fetch(`${HOST}/api/projects/${PROJECT}/query/`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${PH_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query: { kind: 'HogQLQuery', query: query.trim() } }),
  });

  if (!res.ok) {
    console.error(`  PostHog query failed (${res.status}): ${(await res.text()).slice(0, 200)}`);
    return null;
  }

  return (await res.json() as { results: QueryResult }).results as unknown as QueryResult;
}

async function gatherPostHogData(): Promise<Record<string, unknown>> {
  const hours = parseInt(LOOKBACK, 10);
  const data: Record<string, unknown> = {};

  console.log(`  Querying PostHog (last ${hours}h)...`);

  // 1. Top JS exceptions
  data.exceptions = await hogql(`
    SELECT
      properties.\`$exception_type\` as type,
      properties.\`$exception_message\` as message,
      properties.\`$current_url\` as url,
      count() as occurrences,
      countDistinct(distinct_id) as affected_users,
      max(timestamp) as last_seen
    FROM events
    WHERE event = '$exception'
      AND timestamp > now() - INTERVAL ${hours} HOUR
    GROUP BY type, message, url
    ORDER BY occurrences DESC
    LIMIT 25
  `);
  console.log(`    Exceptions: ${(data.exceptions as QueryResult | null)?.results?.length ?? 0} unique errors`);

  // 2. Pages with most errors
  data.errorPages = await hogql(`
    SELECT
      properties.\`$current_url\` as url,
      countIf(event = '$exception') as exceptions,
      countIf(event = '$pageview') as views,
      round(countIf(event = '$exception') * 100.0 / greatest(countIf(event = '$pageview'), 1), 1) as error_rate_pct,
      countDistinct(distinct_id) as unique_visitors
    FROM events
    WHERE timestamp > now() - INTERVAL ${hours} HOUR
      AND (event = '$exception' OR event = '$pageview')
      AND properties.\`$current_url\` IS NOT NULL
    GROUP BY url
    HAVING exceptions > 0
    ORDER BY exceptions DESC
    LIMIT 15
  `);
  console.log(`    Error pages: ${(data.errorPages as QueryResult | null)?.results?.length ?? 0} pages`);

  // 3. Failed user actions (registration, payment, login)
  data.failedActions = await hogql(`
    SELECT
      event,
      properties.\`$current_url\` as url,
      count() as occurrences,
      countDistinct(distinct_id) as affected_users,
      max(timestamp) as last_seen
    FROM events
    WHERE timestamp > now() - INTERVAL ${hours} HOUR
      AND (
        event LIKE '%error%'
        OR event LIKE '%failed%'
        OR event LIKE '%fail%'
      )
    GROUP BY event, url
    ORDER BY occurrences DESC
    LIMIT 15
  `);
  console.log(`    Failed actions: ${(data.failedActions as QueryResult | null)?.results?.length ?? 0} event types`);

  // 4. Signup funnel dropoff
  data.signupFunnel = await hogql(`
    SELECT
      step,
      users
    FROM (
      SELECT 1 as step, 'visited_register' as label, countDistinct(distinct_id) as users
      FROM events
      WHERE event = '$pageview'
        AND properties.\`$current_url\` LIKE '%/register%'
        AND timestamp > now() - INTERVAL ${hours} HOUR
      UNION ALL
      SELECT 2, 'started_form', countDistinct(distinct_id)
      FROM events
      WHERE event = 'registration_step_completed'
        AND timestamp > now() - INTERVAL ${hours} HOUR
      UNION ALL
      SELECT 3, 'completed_signup', countDistinct(distinct_id)
      FROM events
      WHERE event = 'user_signed_up'
        AND timestamp > now() - INTERVAL ${hours} HOUR
    )
    ORDER BY step
  `);
  console.log(`    Signup funnel: queried`);

  // 5. Rage clicks (rapid repeated clicks indicating frustration)
  data.rageClicks = await hogql(`
    SELECT
      properties.\`$current_url\` as url,
      count() as clicks,
      countDistinct(distinct_id) as users
    FROM events
    WHERE event = '$rageclick'
      AND timestamp > now() - INTERVAL ${hours} HOUR
    GROUP BY url
    ORDER BY clicks DESC
    LIMIT 10
  `);
  console.log(`    Rage clicks: ${(data.rageClicks as QueryResult | null)?.results?.length ?? 0} pages`);

  // 6. Slow page loads
  data.slowPages = await hogql(`
    SELECT
      properties.\`$current_url\` as url,
      avg(properties.\`$performance_raw\`.\`duration\`) as avg_load_ms,
      max(properties.\`$performance_raw\`.\`duration\`) as max_load_ms,
      count() as samples
    FROM events
    WHERE event = '$pageview'
      AND properties.\`$performance_raw\`.\`duration\` IS NOT NULL
      AND properties.\`$performance_raw\`.\`duration\` > 3000
      AND timestamp > now() - INTERVAL ${hours} HOUR
    GROUP BY url
    ORDER BY avg_load_ms DESC
    LIMIT 10
  `);
  console.log(`    Slow pages: ${(data.slowPages as QueryResult | null)?.results?.length ?? 0} pages > 3s`);

  // 7. Browser/device breakdown of errors (helps repro)
  data.errorDevices = await hogql(`
    SELECT
      properties.\`$browser\` as browser,
      properties.\`$os\` as os,
      properties.\`$device_type\` as device,
      count() as exceptions
    FROM events
    WHERE event = '$exception'
      AND timestamp > now() - INTERVAL ${hours} HOUR
    GROUP BY browser, os, device
    ORDER BY exceptions DESC
    LIMIT 10
  `);
  console.log(`    Error devices: ${(data.errorDevices as QueryResult | null)?.results?.length ?? 0} combos`);

  return data;
}

// ============================================================================
// Claude Analysis
// ============================================================================

async function analyzeWithClaude(data: Record<string, unknown>): Promise<Bug[]> {
  if (!process.env.ANTHROPIC_API_KEY) {
    console.error('  ANTHROPIC_API_KEY not set -- cannot analyze');
    return [];
  }

  console.log('\n  Sending to Claude for QA review...');

  const client = new Anthropic();

  const response = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 4096,
    messages: [
      {
        role: 'user',
        content: `You are a senior QA engineer reviewing PostHog analytics data for TeamIO, a youth sports management platform. Your job is to identify bugs, user friction, and issues that need developer attention.

Here is the PostHog data from the last ${LOOKBACK} hours:

## JS Exceptions (columns: type, message, url, occurrences, affected_users, last_seen)
${JSON.stringify((data.exceptions as QueryResult | null)?.results ?? [], null, 2)}

## Pages With Highest Error Rates (columns: url, exceptions, views, error_rate_pct, unique_visitors)
${JSON.stringify((data.errorPages as QueryResult | null)?.results ?? [], null, 2)}

## Failed User Actions (columns: event, url, occurrences, affected_users, last_seen)
${JSON.stringify((data.failedActions as QueryResult | null)?.results ?? [], null, 2)}

## Signup Funnel (columns: step, users)
${JSON.stringify((data.signupFunnel as QueryResult | null)?.results ?? [], null, 2)}

## Rage Clicks (columns: url, clicks, users)
${JSON.stringify((data.rageClicks as QueryResult | null)?.results ?? [], null, 2)}

## Slow Page Loads >3s (columns: url, avg_load_ms, max_load_ms, samples)
${JSON.stringify((data.slowPages as QueryResult | null)?.results ?? [], null, 2)}

## Error Device Breakdown (columns: browser, os, device, exceptions)
${JSON.stringify((data.errorDevices as QueryResult | null)?.results ?? [], null, 2)}

Analyze this data and create actionable bug tickets. For each issue:
1. Look for patterns (same error on multiple pages = systematic issue)
2. Prioritize by user impact (affected_users, not just occurrences)
3. Note the device/browser if it's device-specific
4. Flag funnel dropoffs > 50% as conversion issues
5. Flag rage clicks as UX problems
6. Cluster related exceptions into single issues

Respond with a JSON array of bugs. Each bug:
{
  "severity": "critical" | "error" | "warning",
  "category": "exception" | "error-rate" | "funnel-dropoff" | "ux-friction" | "performance" | "failed-action",
  "title": "Short descriptive title (under 80 chars)",
  "description": "Detailed markdown description including:\n- What's happening\n- How many users are affected\n- Which pages/flows are impacted\n- Suggested investigation steps\n- Device/browser info if relevant",
  "url": "Most relevant URL"
}

Only include genuine issues worth filing. Skip noise (e.g., a single 404 from a bot, expected auth redirects). If the data shows no significant issues, return an empty array.

Respond ONLY with the JSON array.`,
      },
    ],
  });

  const text = response.content[0].type === 'text' ? response.content[0].text : '[]';

  try {
    // Extract JSON from response (handle markdown code blocks)
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) return [];

    const issues = JSON.parse(jsonMatch[0]) as Array<{
      severity: 'critical' | 'error' | 'warning';
      category: string;
      title: string;
      description: string;
      url: string;
    }>;

    return issues.map((issue, i) => ({
      id: `PH-${String(i + 1).padStart(3, '0')}`,
      severity: issue.severity,
      category: `posthog-${issue.category}`,
      title: issue.title,
      description: issue.description,
      url: issue.url || 'unknown',
      timestamp: new Date().toISOString(),
    }));
  } catch (err) {
    console.error('  Failed to parse Claude response:', (err as Error).message);
    return [];
  }
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  console.log(`
╔═══════════════════════════════════════════╗
║     PostHog QA Reviewer                   ║
║     Analyze errors → File tickets         ║
╚═══════════════════════════════════════════╝
`);

  if (!PH_KEY || !PROJECT) {
    console.error('Missing required env vars: POSTHOG_API_KEY, POSTHOG_PROJECT_ID');
    process.exit(1);
  }

  if (!process.env.ANTHROPIC_API_KEY) {
    console.error('Missing required env var: ANTHROPIC_API_KEY');
    process.exit(1);
  }

  // 1. Gather data from PostHog
  const data = await gatherPostHogData();

  // 2. Have Claude analyze it like a QA engineer
  const bugs = await analyzeWithClaude(data);

  console.log(`\n  Claude identified ${bugs.length} issue(s)`);

  for (const bug of bugs) {
    const icon = { critical: '🔴', error: '🟠', warning: '🟡', info: '🔵' }[bug.severity] || '🔵';
    console.log(`  ${icon} [${bug.severity}] ${bug.title}`);
  }

  // 3. File as GitHub issues
  if (bugs.length > 0 && process.env.FILE_GITHUB_ISSUES === 'true') {
    const minSeverity = (process.env.GITHUB_MIN_SEVERITY || 'warning') as 'critical' | 'error' | 'warning';
    const { filed, skipped } = await fileBugsAsIssues(bugs, { minSeverity });
    console.log(`\n  GitHub: ${filed} filed, ${skipped} skipped`);
  } else if (bugs.length > 0) {
    console.log(`\n  Set FILE_GITHUB_ISSUES=true to create GitHub issues`);
  }

  // 4. Save local report
  const { writeFileSync, mkdirSync, existsSync } = await import('fs');
  const reportDir = new URL('../reports', import.meta.url).pathname;
  if (!existsSync(reportDir)) mkdirSync(reportDir, { recursive: true });

  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const report = {
    type: 'posthog-review',
    timestamp: new Date().toISOString(),
    lookbackHours: parseInt(LOOKBACK, 10),
    bugs,
    rawData: data,
  };

  writeFileSync(`${reportDir}/posthog-review-${ts}.json`, JSON.stringify(report, null, 2));

  const md = [
    `# PostHog QA Review`,
    ``,
    `**Date:** ${new Date().toISOString()}`,
    `**Lookback:** ${LOOKBACK} hours`,
    `**Issues found:** ${bugs.length}`,
    ``,
    ...bugs.map(b => {
      const icon = ({ critical: '🔴', error: '🟠', warning: '🟡', info: '🔵' } as Record<string, string>)[b.severity] || '🔵';
      return [
        `## ${icon} ${b.title}`,
        `**Severity:** ${b.severity} | **Category:** ${b.category} | **URL:** ${b.url}`,
        ``,
        b.description,
        ``,
      ].join('\n');
    }),
  ].join('\n');

  const mdPath = `${reportDir}/posthog-review-${ts}.md`;
  writeFileSync(mdPath, md);
  console.log(`\n📋 Report: ${mdPath}`);
}

main().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
