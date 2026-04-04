import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { config } from './config.js';
import { fileBugsAsIssues } from './github-reporter.js';
import type { Bug, CrawlStats, PageVisit } from './types.js';

export class Reporter {
  private bugs: Bug[] = [];
  private visits: PageVisit[] = [];
  private startTime = Date.now();
  private bugCounter = 0;

  addBug(bug: Omit<Bug, 'id' | 'timestamp'>): Bug {
    const full: Bug = {
      ...bug,
      id: `BUG-${String(++this.bugCounter).padStart(4, '0')}`,
      timestamp: new Date().toISOString(),
    };
    this.bugs.push(full);
    const icon = bug.severity === 'critical' ? '🔴' : bug.severity === 'error' ? '🟠' : bug.severity === 'warning' ? '🟡' : '🔵';
    console.log(`  ${icon} ${full.id} [${bug.severity}] ${bug.title}`);
    return full;
  }

  addVisit(visit: PageVisit) {
    this.visits.push(visit);
  }

  getStats(): CrawlStats {
    return {
      pagesVisited: this.visits.length,
      formsFound: this.visits.reduce((sum, v) => sum + v.forms, 0),
      formsFuzzed: 0, // updated by agent
      bugsFound: this.bugs.length,
      startTime: new Date(this.startTime).toISOString(),
      duration: Date.now() - this.startTime,
    };
  }

  async save() {
    if (!existsSync(config.reportDir)) {
      mkdirSync(config.reportDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const stats = this.getStats();

    // JSON report
    const report = { stats, bugs: this.bugs, visits: this.visits };
    const jsonPath = `${config.reportDir}/chaos-report-${timestamp}.json`;
    writeFileSync(jsonPath, JSON.stringify(report, null, 2));

    // Markdown summary
    const md = this.toMarkdown(stats);
    const mdPath = `${config.reportDir}/chaos-report-${timestamp}.md`;
    writeFileSync(mdPath, md);

    console.log(`\n📋 Report saved: ${mdPath}`);

    // File bugs as GitHub issues if enabled
    if (process.env.FILE_GITHUB_ISSUES === 'true' && this.bugs.length > 0) {
      const minSeverity = (process.env.GITHUB_MIN_SEVERITY || 'warning') as 'critical' | 'error' | 'warning' | 'info';
      const { filed, skipped } = await fileBugsAsIssues(this.bugs, { minSeverity });
      console.log(`  GitHub: ${filed} issues filed, ${skipped} skipped (duplicates)`);
    }

    return { jsonPath, mdPath };
  }

  getBugs(): Bug[] {
    return [...this.bugs];
  }

  private toMarkdown(stats: CrawlStats): string {
    const lines: string[] = [
      `# QA Chaos Agent Report`,
      ``,
      `**Run:** ${stats.startTime}`,
      `**Duration:** ${Math.round(stats.duration / 1000)}s`,
      `**Pages visited:** ${stats.pagesVisited}`,
      `**Bugs found:** ${stats.bugsFound}`,
      ``,
    ];

    if (this.bugs.length === 0) {
      lines.push(`## No bugs found! ✅`);
    } else {
      // Group by severity
      for (const severity of ['critical', 'error', 'warning', 'info'] as const) {
        const group = this.bugs.filter(b => b.severity === severity);
        if (group.length === 0) continue;

        lines.push(`## ${severity.toUpperCase()} (${group.length})`);
        lines.push(``);

        for (const bug of group) {
          lines.push(`### ${bug.id}: ${bug.title}`);
          lines.push(`- **Category:** ${bug.category}`);
          lines.push(`- **URL:** ${bug.url}`);
          lines.push(`- **Description:** ${bug.description}`);
          if (bug.consoleErrors?.length) {
            lines.push(`- **Console errors:**`);
            for (const e of bug.consoleErrors) {
              lines.push(`  - \`${e.slice(0, 200)}\``);
            }
          }
          if (bug.networkErrors?.length) {
            lines.push(`- **Network errors:**`);
            for (const e of bug.networkErrors) {
              lines.push(`  - \`${e.method} ${e.url}\` → ${e.status} ${e.statusText}`);
            }
          }
          if (bug.screenshot) {
            lines.push(`- **Screenshot:** ${bug.screenshot}`);
          }
          lines.push(``);
        }
      }
    }

    // Page visit summary
    lines.push(`## Pages Visited`);
    lines.push(``);
    lines.push(`| URL | Console Errors | Network Errors | Forms |`);
    lines.push(`|-----|---------------|----------------|-------|`);
    for (const v of this.visits) {
      const path = v.url.replace(config.baseUrl, '');
      lines.push(`| ${path || '/'} | ${v.consoleErrors.length} | ${v.networkErrors.length} | ${v.forms} |`);
    }

    return lines.join('\n');
  }
}
