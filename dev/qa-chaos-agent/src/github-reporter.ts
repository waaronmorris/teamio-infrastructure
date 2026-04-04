import type { Bug } from './types.js';

const REPO = process.env.GITHUB_REPO || 'waaronmorris/teamio';
const TOKEN = process.env.GH_TOKEN || process.env.GITHUB_TOKEN || '';
const LABEL = 'qa-chaos-agent';
const DRY_RUN = process.env.DRY_RUN === 'true';
const API = `https://api.github.com/repos/${REPO}`;

function headers() {
  return {
    Authorization: `Bearer ${TOKEN}`,
    Accept: 'application/vnd.github+json',
    'Content-Type': 'application/json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
}

async function ensureLabel(): Promise<void> {
  if (!TOKEN) return;
  try {
    const res = await fetch(`${API}/labels/${LABEL}`, { headers: headers() });
    if (res.status === 404) {
      await fetch(`${API}/labels`, {
        method: 'POST',
        headers: headers(),
        body: JSON.stringify({
          name: LABEL,
          color: 'D93F0B',
          description: 'Auto-filed by QA Chaos Agent',
        }),
      });
      console.log(`  Created GitHub label: ${LABEL}`);
    }
  } catch {
    // Best effort
  }
}

async function issueExists(title: string): Promise<boolean> {
  if (!TOKEN) return false;
  try {
    const q = encodeURIComponent(`repo:${REPO} is:issue is:open label:${LABEL} "${title.slice(0, 80)}"`);
    const res = await fetch(`https://api.github.com/search/issues?q=${q}&per_page=1`, {
      headers: headers(),
    });
    if (!res.ok) return false;
    const data = await res.json() as { total_count: number };
    return data.total_count > 0;
  } catch {
    return false;
  }
}

async function fileIssue(bug: Bug): Promise<string | null> {
  const title = `[${bug.severity.toUpperCase()}] ${bug.title}`;

  if (await issueExists(bug.title)) {
    console.log(`  ⏭️  Skipped (duplicate): ${bug.title}`);
    return null;
  }

  const icon = { critical: '🔴', error: '🟠', warning: '🟡', info: '🔵' }[bug.severity];

  const bodyParts = [
    `## ${icon} ${bug.severity.toUpperCase()} Bug`,
    ``,
    `**Category:** ${bug.category}`,
    `**URL:** ${bug.url}`,
    `**Detected:** ${bug.timestamp}`,
    ``,
    `### Description`,
    bug.description,
    ``,
  ];

  if (bug.consoleErrors?.length) {
    bodyParts.push(`### Console Errors`);
    for (const e of bug.consoleErrors) {
      bodyParts.push('```', e.slice(0, 500), '```');
    }
    bodyParts.push('');
  }

  if (bug.networkErrors?.length) {
    bodyParts.push(`### Network Errors`);
    bodyParts.push('| Method | URL | Status |', '|--------|-----|--------|');
    for (const e of bug.networkErrors) {
      const short = e.url.length > 80 ? e.url.slice(0, 77) + '...' : e.url;
      bodyParts.push(`| ${e.method} | ${short} | ${e.status} ${e.statusText} |`);
    }
    bodyParts.push('');
  }

  bodyParts.push(`---`, `*Filed automatically by QA Chaos Agent*`);

  if (DRY_RUN) {
    console.log(`  🔸 [DRY RUN] Would file: ${title}`);
    return null;
  }

  if (!TOKEN) {
    console.log(`  ⚠️  No GH_TOKEN set, skipping: ${title}`);
    return null;
  }

  try {
    const res = await fetch(`${API}/issues`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify({
        title,
        body: bodyParts.join('\n'),
        labels: [LABEL, `severity:${bug.severity}`],
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      console.log(`  ❌ Failed to file issue (${res.status}): ${err.slice(0, 200)}`);
      return null;
    }

    const data = await res.json() as { html_url: string };
    console.log(`  ✅ Filed: ${data.html_url}`);
    return data.html_url;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.log(`  ❌ Failed to file issue: ${msg.slice(0, 200)}`);
    return null;
  }
}

/** File bugs as GitHub issues */
export async function fileBugsAsIssues(bugs: Bug[], options?: {
  minSeverity?: 'critical' | 'error' | 'warning' | 'info';
}): Promise<{ filed: number; skipped: number }> {
  const minSeverity = options?.minSeverity || 'warning';
  const order = ['info', 'warning', 'error', 'critical'];
  const minIdx = order.indexOf(minSeverity);
  const eligible = bugs.filter(b => order.indexOf(b.severity) >= minIdx);

  if (eligible.length === 0) {
    console.log('  No bugs meet the severity threshold for filing.');
    return { filed: 0, skipped: 0 };
  }

  console.log(`\n📝 Filing ${eligible.length} bugs as GitHub issues (min severity: ${minSeverity})...`);
  await ensureLabel();

  let filed = 0;
  let skipped = 0;

  for (const bug of eligible) {
    const result = await fileIssue(bug);
    if (result) filed++;
    else skipped++;
  }

  return { filed, skipped };
}
