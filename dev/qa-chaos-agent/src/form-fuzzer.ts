import { Page, Locator } from 'playwright';
import { config } from './config.js';
import { Reporter } from './reporter.js';

interface FormField {
  locator: Locator;
  type: string;
  name: string;
  required: boolean;
  tagName: string;
}

/** Fuzz values designed to trigger edge cases and vulnerabilities */
const FUZZ_STRINGS = {
  // XSS payloads
  xss: [
    '<script>alert("xss")</script>',
    '"><img src=x onerror=alert(1)>',
    "'; DROP TABLE users; --",
    '{{constructor.constructor("return this")()}}',
  ],
  // Boundary values
  boundaries: [
    '',
    ' ',
    '   ',
    'a'.repeat(1000),
    'a'.repeat(10000),
    '0',
    '-1',
    '999999999999',
    '0.0000001',
    'NaN',
    'undefined',
    'null',
    'true',
  ],
  // Unicode and special chars
  unicode: [
    '日本語テスト',
    '🏈⚽🏀🎾',
    'Ñoño García-López',
    'test\x00null',
    'test\nline\nbreak',
    '<>&"\'',
  ],
  // Email edge cases
  emails: [
    'notanemail',
    'test@',
    '@example.com',
    'test@example',
    'a@b.c',
    'very.long.email.address.that.goes.on.and.on@extremely.long.domain.name.example.com',
  ],
  // Phone edge cases
  phones: [
    '000',
    '555-123-456789012345',
    '+1 (555) 123-4567',
    'not-a-phone',
  ],
};

type FuzzStrategy = 'valid' | 'empty' | 'xss' | 'boundary' | 'unicode';

export class FormFuzzer {
  private fuzzCount = 0;

  constructor(
    private page: Page,
    private reporter: Reporter,
  ) {}

  get formsFuzzed() { return this.fuzzCount; }

  /** Find and fuzz all forms on the current page */
  async fuzzCurrentPage(): Promise<void> {
    const url = this.page.url();
    const fields = await this.discoverFields();

    if (fields.length === 0) return;

    console.log(`  🔧 Found ${fields.length} form fields on ${url.replace(config.baseUrl, '')}`);

    // Run each fuzz strategy
    for (const strategy of ['empty', 'xss', 'boundary', 'unicode'] as FuzzStrategy[]) {
      await this.runStrategy(fields, strategy, url);
    }
  }

  /** Discover all input fields on the page */
  private async discoverFields(): Promise<FormField[]> {
    const fields: FormField[] = [];
    const inputs = this.page.locator('input:visible, textarea:visible, select:visible');
    const count = await inputs.count();

    for (let i = 0; i < count; i++) {
      const locator = inputs.nth(i);
      try {
        const type = await locator.getAttribute('type') || 'text';
        const name = await locator.getAttribute('name') || await locator.getAttribute('id') || `field-${i}`;
        const required = await locator.getAttribute('required') !== null;
        const tagName = await locator.evaluate(el => el.tagName.toLowerCase());

        // Skip hidden, submit, and file inputs
        if (['hidden', 'submit', 'button', 'file', 'image'].includes(type)) continue;

        fields.push({ locator, type, name, required, tagName });
      } catch {
        // Element might have disappeared
      }
    }

    return fields;
  }

  /** Run a fuzz strategy on all fields */
  private async runStrategy(fields: FormField[], strategy: FuzzStrategy, url: string) {
    this.fuzzCount++;

    for (const field of fields) {
      try {
        const value = this.getFuzzValue(field, strategy);
        if (value === null) continue;

        if (field.tagName === 'select') {
          // For selects, try to select an invalid option
          try {
            await field.locator.selectOption({ index: 0 });
          } catch { /* may not have options */ }
        } else {
          await field.locator.fill('');
          await field.locator.fill(value);
        }
      } catch {
        // Field might not be interactable
      }
    }

    // Try to submit the form
    const submitted = await this.trySubmit();

    // Check for errors after submission
    await this.page.waitForTimeout(1500);
    await this.checkForIssues(url, strategy, submitted);
  }

  /** Get a fuzz value for a field based on strategy */
  private getFuzzValue(field: FormField, strategy: FuzzStrategy): string | null {
    switch (strategy) {
      case 'empty':
        return '';

      case 'xss':
        return pick(FUZZ_STRINGS.xss);

      case 'boundary':
        if (field.type === 'email') return pick(FUZZ_STRINGS.emails);
        if (field.type === 'tel') return pick(FUZZ_STRINGS.phones);
        if (field.type === 'number') return pick(['-1', '0', '999999999', 'NaN']);
        return pick(FUZZ_STRINGS.boundaries);

      case 'unicode':
        return pick(FUZZ_STRINGS.unicode);

      case 'valid':
        return this.getValidValue(field);

      default:
        return null;
    }
  }

  /** Generate a plausible valid value */
  private getValidValue(field: FormField): string {
    switch (field.type) {
      case 'email': return 'chaos-test@example.com';
      case 'password': return 'ChaosTest123!';
      case 'tel': return '555-123-4567';
      case 'number': return '42';
      case 'url': return 'https://example.com';
      default: return 'Chaos Test Value';
    }
  }

  /** Try to submit the form via button click */
  private async trySubmit(): Promise<boolean> {
    try {
      const submitBtn = this.page.locator(
        'button[type="submit"], button:has-text("Submit"), button:has-text("Save"), button:has-text("Create"), button:has-text("Next"), button:has-text("Complete")'
      ).first();

      if (await submitBtn.isVisible({ timeout: 1000 })) {
        await submitBtn.click({ timeout: 3000 });
        return true;
      }
    } catch {
      // No submit button or click failed
    }
    return false;
  }

  /** Check for issues after form submission */
  private async checkForIssues(url: string, strategy: string, submitted: boolean) {
    // Check for unhandled errors in the page
    const hasErrorBoundary = await this.page.locator('text=/something went wrong/i, text=/error/i, text=/500/i, text=/internal server/i').count();

    if (hasErrorBoundary > 0) {
      const text = await this.page.locator('text=/something went wrong/i, text=/error/i').first().textContent().catch(() => null);
      this.reporter.addBug({
        severity: 'error',
        category: 'form-error',
        title: `Form crash with ${strategy} input on ${url.replace(config.baseUrl, '')}`,
        description: `Page showed error state after ${strategy} fuzz input${submitted ? ' and submit' : ''}. Text: "${text?.slice(0, 200)}"`,
        url,
      });
    }

    // Check if XSS payload was reflected as executable HTML (not just as an input value)
    if (strategy === 'xss') {
      // Use Playwright to check if a <script> tag or event handler was injected
      // into the DOM outside of input values/attributes
      const xssExecuted = await this.page.evaluate(() => {
        // Check for injected script tags that aren't part of the app bundle
        const scripts = document.querySelectorAll('script');
        for (const s of scripts) {
          if (s.textContent?.includes('alert("xss")')) return true;
        }
        // Check for injected img tags with onerror
        const imgs = document.querySelectorAll('img[onerror]');
        if (imgs.length > 0) return true;
        return false;
      });

      if (xssExecuted) {
        this.reporter.addBug({
          severity: 'critical',
          category: 'xss-vulnerability',
          title: `XSS vulnerability on ${url.replace(config.baseUrl, '')}`,
          description: 'XSS payload was injected into the DOM as executable HTML (script tag or event handler found outside input values)',
          url,
        });
      }
    }

    // Check if page navigated unexpectedly (e.g., white screen)
    const bodyText = await this.page.locator('body').textContent().catch(() => '');
    if (bodyText?.trim() === '' || bodyText === null) {
      this.reporter.addBug({
        severity: 'error',
        category: 'blank-page',
        title: `Blank page after ${strategy} fuzz on ${url.replace(config.baseUrl, '')}`,
        description: 'Page body is empty after form interaction - possible crash or unhandled error',
        url,
      });
    }
  }
}

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}
