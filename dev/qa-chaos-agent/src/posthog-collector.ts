/**
 * PostHog error collector.
 *
 * Queries PostHog for recent errors, exceptions, and failed events,
 * then converts them into bugs for the chaos agent report.
 *
 * Requires: POSTHOG_API_KEY (personal API key, not project key)
 *           POSTHOG_PROJECT_ID
 *           POSTHOG_HOST (optional, defaults to https://us.i.posthog.com)
 */

import { Reporter } from './reporter.js';

const HOST = process.env.POSTHOG_HOST || 'https://us.i.posthog.com';
const API_KEY = process.env.POSTHOG_API_KEY || '';
const PROJECT_ID = process.env.POSTHOG_PROJECT_ID || '';

interface PostHogEvent {
  id: string;
  event: string;
  timestamp: string;
  properties: Record<string, unknown>;
  person?: { distinct_ids?: string[]; properties?: Record<string, unknown> };
}

interface PostHogQueryResult {
  results: unknown[][];
  columns: string[];
}

export class PostHogCollector {
  private reporter: Reporter;

  constructor(reporter: Reporter) {
    this.reporter = reporter;
  }

  get isConfigured(): boolean {
    return !!(API_KEY && PROJECT_ID);
  }

  /** Collect recent errors from PostHog and add them to the report */
  async collect(): Promise<number> {
    if (!this.isConfigured) {
      console.log('  PostHog: skipped (set POSTHOG_API_KEY and POSTHOG_PROJECT_ID)');
      return 0;
    }

    console.log('\n📊 Collecting errors from PostHog...');

    let totalBugs = 0;

    // 1. Query for $exception events (JS errors captured by PostHog)
    totalBugs += await this.queryExceptions();

    // 2. Query for $pageview with error indicators
    totalBugs += await this.queryPageErrors();

    // 3. Query for failed API calls tracked as events
    totalBugs += await this.queryFailedEvents();

    console.log(`  PostHog: ${totalBugs} error(s) collected`);
    return totalBugs;
  }

  /** Query $exception events from the last 24 hours */
  private async queryExceptions(): Promise<number> {
    const query = `
      SELECT
        properties.$exception_message as message,
        properties.$exception_type as type,
        properties.$current_url as url,
        properties.$browser as browser,
        count() as occurrences,
        max(timestamp) as last_seen
      FROM events
      WHERE event = '$exception'
        AND timestamp > now() - INTERVAL 24 HOUR
      GROUP BY message, type, url, browser
      ORDER BY occurrences DESC
      LIMIT 50
    `;

    const result = await this.hogqlQuery(query);
    if (!result) return 0;

    let bugs = 0;
    for (const row of result.results) {
      const [message, type, url, browser, occurrences, lastSeen] = row as [string, string, string, string, number, string];

      this.reporter.addBug({
        severity: (occurrences as number) > 10 ? 'critical' : 'error',
        category: 'posthog-exception',
        title: `${type || 'Error'}: ${(message || 'Unknown error').slice(0, 100)}`,
        description: [
          `**Type:** ${type || 'Unknown'}`,
          `**Message:** ${message}`,
          `**Occurrences (24h):** ${occurrences}`,
          `**Last seen:** ${lastSeen}`,
          `**Browser:** ${browser || 'Unknown'}`,
        ].join('\n'),
        url: url || 'unknown',
      });
      bugs++;
    }

    return bugs;
  }

  /** Query pages with high error rates */
  private async queryPageErrors(): Promise<number> {
    const query = `
      SELECT
        properties.$current_url as url,
        countIf(event = '$exception') as exceptions,
        countIf(event = '$pageview') as pageviews,
        round(countIf(event = '$exception') * 100.0 / greatest(countIf(event = '$pageview'), 1), 1) as error_rate
      FROM events
      WHERE timestamp > now() - INTERVAL 24 HOUR
        AND (event = '$exception' OR event = '$pageview')
        AND properties.$current_url IS NOT NULL
      GROUP BY url
      HAVING exceptions > 0
      ORDER BY error_rate DESC
      LIMIT 20
    `;

    const result = await this.hogqlQuery(query);
    if (!result) return 0;

    let bugs = 0;
    for (const row of result.results) {
      const [url, exceptions, pageviews, errorRate] = row as [string, number, number, number];

      // Only report pages with significant error rates
      if ((errorRate as number) < 5 && (exceptions as number) < 3) continue;

      this.reporter.addBug({
        severity: (errorRate as number) > 25 ? 'critical' : (errorRate as number) > 10 ? 'error' : 'warning',
        category: 'posthog-error-rate',
        title: `High error rate (${errorRate}%) on ${stripDomain(url as string)}`,
        description: [
          `**Error rate:** ${errorRate}%`,
          `**Exceptions:** ${exceptions}`,
          `**Pageviews:** ${pageviews}`,
          `**Period:** Last 24 hours`,
        ].join('\n'),
        url: url || 'unknown',
      });
      bugs++;
    }

    return bugs;
  }

  /** Query for failed events (registration failures, payment errors, etc.) */
  private async queryFailedEvents(): Promise<number> {
    const query = `
      SELECT
        event,
        properties.$current_url as url,
        count() as occurrences,
        max(timestamp) as last_seen
      FROM events
      WHERE timestamp > now() - INTERVAL 24 HOUR
        AND (
          event LIKE '%failed%'
          OR event LIKE '%error%'
          OR (event = 'registration_submitted' AND properties.success = false)
          OR (event = 'payment_completed' AND properties.success = false)
        )
      GROUP BY event, url
      ORDER BY occurrences DESC
      LIMIT 20
    `;

    const result = await this.hogqlQuery(query);
    if (!result) return 0;

    let bugs = 0;
    for (const row of result.results) {
      const [event, url, occurrences, lastSeen] = row as [string, string, number, string];

      this.reporter.addBug({
        severity: (occurrences as number) > 5 ? 'error' : 'warning',
        category: 'posthog-failed-event',
        title: `Failed event "${event}" (${occurrences}x in 24h)`,
        description: [
          `**Event:** ${event}`,
          `**Occurrences (24h):** ${occurrences}`,
          `**Last seen:** ${lastSeen}`,
        ].join('\n'),
        url: url || 'unknown',
      });
      bugs++;
    }

    return bugs;
  }

  /** Execute a HogQL query against the PostHog API */
  private async hogqlQuery(query: string): Promise<PostHogQueryResult | null> {
    try {
      const res = await fetch(`${HOST}/api/projects/${PROJECT_ID}/query/`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query: { kind: 'HogQLQuery', query: query.trim() },
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.log(`  PostHog query failed (${res.status}): ${text.slice(0, 200)}`);
        return null;
      }

      const data = await res.json() as { results: PostHogQueryResult };
      return data.results as unknown as PostHogQueryResult;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.log(`  PostHog query error: ${msg.slice(0, 200)}`);
      return null;
    }
  }
}

function stripDomain(url: string): string {
  try {
    return new URL(url).pathname;
  } catch {
    return url;
  }
}
