import { Page } from 'playwright';
import { config } from './config.js';
import { Reporter } from './reporter.js';
import type { NetworkError, PageVisit } from './types.js';

/**
 * Crawls the app, collecting links and detecting errors on each page.
 */
export class Crawler {
  private visited = new Set<string>();
  private queue: string[] = [];

  constructor(
    private page: Page,
    private reporter: Reporter,
  ) {}

  /** Seed the crawl queue with starting URLs */
  seed(urls: string[]) {
    for (const url of urls) {
      this.enqueue(url);
    }
  }

  /** Crawl the next page in the queue. Returns false if queue is empty. */
  async crawlNext(): Promise<boolean> {
    const url = this.queue.shift();
    if (!url) return false;

    if (this.visited.has(url)) return true;
    this.visited.add(url);

    const visit = await this.visitPage(url);
    this.reporter.addVisit(visit);

    // Report console errors
    if (visit.consoleErrors.length > 0) {
      this.reporter.addBug({
        severity: visit.consoleErrors.some(e => e.includes('Uncaught') || e.includes('TypeError')) ? 'error' : 'warning',
        category: 'console-error',
        title: `Console errors on ${url.replace(config.baseUrl, '')}`,
        description: `${visit.consoleErrors.length} console error(s) detected`,
        url,
        consoleErrors: visit.consoleErrors,
      });
    }

    // Report network errors
    const serverErrors = visit.networkErrors.filter(e => e.status >= 500);
    if (serverErrors.length > 0) {
      this.reporter.addBug({
        severity: 'critical',
        category: 'server-error',
        title: `Server error (5xx) on ${url.replace(config.baseUrl, '')}`,
        description: `${serverErrors.length} server error(s): ${serverErrors.map(e => `${e.method} ${e.url} → ${e.status}`).join(', ')}`,
        url,
        networkErrors: serverErrors,
      });
    }

    const clientErrors = visit.networkErrors.filter(e => e.status >= 400 && e.status < 500 && e.status !== 401);
    if (clientErrors.length > 0) {
      this.reporter.addBug({
        severity: 'warning',
        category: 'client-error',
        title: `Client error (4xx) on ${url.replace(config.baseUrl, '')}`,
        description: `${clientErrors.length} client error(s): ${clientErrors.map(e => `${e.method} ${e.url} → ${e.status}`).join(', ')}`,
        url,
        networkErrors: clientErrors,
      });
    }

    return true;
  }

  /** Visit a page, collect errors and discover links */
  private async visitPage(url: string): Promise<PageVisit> {
    const consoleErrors: string[] = [];
    const networkErrors: NetworkError[] = [];
    const start = Date.now();

    // Listen for console errors
    const onConsole = (msg: { type: () => string; text: () => string }) => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    };
    this.page.on('console', onConsole);

    // Listen for failed network requests
    const onResponse = (response: { url: () => string; status: () => number; statusText: () => string; request: () => { method: () => string } }) => {
      const status = response.status();
      if (status >= 400) {
        networkErrors.push({
          url: response.url(),
          method: response.request().method(),
          status,
          statusText: response.statusText(),
        });
      }
    };
    this.page.on('response', onResponse);

    try {
      console.log(`  📄 Visiting: ${url.replace(config.baseUrl, '') || '/'}`);
      await this.page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
      await this.page.waitForTimeout(config.actionDelay);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (!message.includes('net::ERR_ABORTED')) {
        this.reporter.addBug({
          severity: 'error',
          category: 'navigation-error',
          title: `Failed to load ${url.replace(config.baseUrl, '')}`,
          description: message.slice(0, 500),
          url,
        });
      }
    }

    // Discover internal links
    const links = await this.page.$$eval('a[href]', (anchors, baseUrl) => {
      return anchors
        .map(a => a.getAttribute('href') || '')
        .filter(href => href.startsWith('/') || href.startsWith(baseUrl))
        .map(href => href.startsWith('/') ? `${baseUrl}${href}` : href);
    }, config.baseUrl);

    for (const link of links) {
      this.enqueue(link);
    }

    // Count forms
    const formCount = await this.page.$$eval('form, [role="form"], input, textarea, select', els => {
      const forms = els.filter(e => e.tagName === 'FORM' || e.getAttribute('role') === 'form');
      return forms.length || (els.length > 0 ? 1 : 0);
    });

    const title = await this.page.title();

    this.page.removeListener('console', onConsole);
    this.page.removeListener('response', onResponse);

    return {
      url,
      title,
      timestamp: new Date().toISOString(),
      duration: Date.now() - start,
      consoleErrors,
      networkErrors,
      forms: formCount,
      links: links.length,
    };
  }

  private enqueue(url: string) {
    // Normalize and filter
    const clean = url.split('#')[0].split('?')[0];
    if (!clean.startsWith(config.baseUrl)) return;
    if (this.visited.has(clean)) return;
    if (this.queue.includes(clean)) return;
    // Skip external and special URLs
    if (clean.includes('logout') || clean.includes('mailto:') || clean.includes('tel:')) return;
    this.queue.push(clean);
  }

  get queueSize() { return this.queue.length; }
  get visitCount() { return this.visited.size; }
}
