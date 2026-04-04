export type Severity = 'critical' | 'error' | 'warning' | 'info';

export interface Bug {
  id: string;
  severity: Severity;
  category: string;
  title: string;
  description: string;
  url: string;
  screenshot?: string;
  consoleErrors?: string[];
  networkErrors?: NetworkError[];
  timestamp: string;
  reproducible?: string;
}

export interface NetworkError {
  url: string;
  method: string;
  status: number;
  statusText: string;
}

export interface PageVisit {
  url: string;
  title: string;
  timestamp: string;
  duration: number;
  consoleErrors: string[];
  networkErrors: NetworkError[];
  forms: number;
  links: number;
}

export interface CrawlStats {
  pagesVisited: number;
  formsFound: number;
  formsFuzzed: number;
  bugsFound: number;
  startTime: string;
  duration: number;
}
