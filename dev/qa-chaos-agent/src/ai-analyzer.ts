import Anthropic from '@anthropic-ai/sdk';
import { Reporter } from './reporter.js';

/**
 * Optional AI-powered page analyzer.
 * Takes a screenshot and asks Claude to identify UI/UX issues.
 * Only active when ANTHROPIC_API_KEY is set.
 */
export class AiAnalyzer {
  private client: Anthropic;

  constructor(private reporter: Reporter) {
    this.client = new Anthropic();
  }

  /** Analyze a page screenshot for visual bugs and UX issues */
  async analyzeScreenshot(screenshot: Buffer, url: string, pageTitle: string): Promise<void> {
    try {
      const response = await this.client.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: 'image/png',
                  data: screenshot.toString('base64'),
                },
              },
              {
                type: 'text',
                text: `You are a QA tester reviewing a page from a youth sports management app called TeamIO.

URL: ${url}
Page Title: ${pageTitle}

Analyze this screenshot for bugs and issues. Look for:
1. Broken layouts (overlapping elements, cut-off text, misaligned items)
2. Missing content (empty states without helpful messages, broken images)
3. Accessibility issues (low contrast text, tiny tap targets)
4. UI inconsistencies (mixed styling, orphaned elements)
5. Data display issues (truncated names, wrong formats, "undefined" or "null" showing)

Respond with a JSON array of issues found. Each issue should have:
- severity: "error" | "warning" | "info"
- title: brief description
- description: detailed explanation

If no issues found, return an empty array: []
Respond ONLY with the JSON array, no other text.`,
              },
            ],
          },
        ],
      });

      const text = response.content[0].type === 'text' ? response.content[0].text : '';
      // Handle both raw JSON and markdown-wrapped JSON (```json ... ```)
      const jsonMatch = text.match(/\[[\s\S]*\]/);
      if (!jsonMatch) return;
      const issues = JSON.parse(jsonMatch[0]);

      if (Array.isArray(issues)) {
        for (const issue of issues) {
          this.reporter.addBug({
            severity: issue.severity || 'info',
            category: 'visual-ai',
            title: issue.title || 'Visual issue detected',
            description: issue.description || '',
            url,
          });
        }
      }
    } catch (err) {
      // AI analysis is best-effort, don't fail the crawl
      const message = err instanceof Error ? err.message : String(err);
      if (!message.includes('Could not process image')) {
        console.log(`  ⚠️  AI analysis failed: ${message.slice(0, 100)}`);
      }
    }
  }
}
