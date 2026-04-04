export const config = {
  baseUrl: process.env.BASE_URL || 'http://localhost:5173',
  apiUrl: process.env.API_URL || 'http://localhost:3000',
  headless: process.env.HEADLESS === 'true',

  // How long to run (0 = forever)
  maxDurationMs: parseInt(process.env.MAX_DURATION || '0', 10),

  // Pause between actions (ms)
  actionDelay: parseInt(process.env.ACTION_DELAY || '1000', 10),

  // Max pages to visit per crawl cycle
  maxPagesPerCycle: parseInt(process.env.MAX_PAGES || '50', 10),

  // Test accounts
  users: {
    admin: { email: 'admin@teamio.local', password: 'password123' },
    coach: { email: 'coach.smith@teamio.local', password: 'password123' },
    parent: { email: 'parent.jones@teamio.local', password: 'password123' },
  },

  // Claude API for intelligent analysis (optional)
  useClaudeAnalysis: !!process.env.ANTHROPIC_API_KEY,

  // GitHub issue filing (set FILE_GITHUB_ISSUES=true to enable)
  fileGithubIssues: process.env.FILE_GITHUB_ISSUES === 'true',
  githubRepo: process.env.GITHUB_REPO || 'waaronmorris/teamio',
  githubMinSeverity: process.env.GITHUB_MIN_SEVERITY || 'warning',

  // Report output
  reportDir: new URL('../reports', import.meta.url).pathname,
};
