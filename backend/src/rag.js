import { readFile } from 'fs/promises';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const STOP_WORDS = new Set([
  'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from', 'has', 'in',
  'into', 'is', 'it', 'of', 'on', 'or', 'that', 'the', 'this', 'to', 'with',
  'when', 'while', 'after', 'before', 'then', 'only', 'same', 'should',
]);

const KNOWLEDGE_PATH = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'knowledge',
  'documents.json',
);

let cachedChunks;

export async function retrieveKnowledge({ query = '', codeContext = '', limit = 5 } = {}) {
  const chunks = await loadChunks();
  const queryText = [query, codeContext].filter(Boolean).join('\n\n');
  const queryTokens = tokenize(queryText);
  if (!queryTokens.length) return [];

  const querySet = new Set(queryTokens);
  const codeTokens = new Set(tokenize(codeContext));
  const scored = chunks
    .map((chunk) => scoreChunk(chunk, queryTokens, querySet, codeTokens))
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ chunk, score }) => ({
      source: chunk.source,
      title: chunk.title,
      excerpt: excerpt(chunk.text),
      score: Number(score.toFixed(3)),
    }));

  return scored;
}

async function loadChunks() {
  if (cachedChunks) return cachedChunks;
  const documents = JSON.parse(await readFile(KNOWLEDGE_PATH, 'utf8'));
  cachedChunks = documents.flatMap((document) => chunkDocument(document));
  return cachedChunks;
}

function chunkDocument(document) {
  const paragraphs = String(document.body || '')
    .split(/\n{2,}|(?<=\.)\s+(?=[A-Z])/g)
    .map((text) => text.trim())
    .filter(Boolean);

  return paragraphs.map((text, index) => {
    const fullText = `${document.title}. ${text}`;
    return {
      source: document.source,
      title: document.title,
      index,
      text,
      tokens: tokenize(fullText),
    };
  });
}

function scoreChunk(chunk, queryTokens, querySet, codeTokens) {
  const chunkTokens = new Set(chunk.tokens);
  let overlap = 0;
  let codeOverlap = 0;

  for (const token of querySet) {
    if (chunkTokens.has(token)) overlap += 1;
  }
  for (const token of codeTokens) {
    if (chunkTokens.has(token)) codeOverlap += 1;
  }

  const phraseBoost = importantPhraseBoost(chunk.text, queryTokens.join(' '));
  const density = overlap / Math.sqrt(chunk.tokens.length || 1);
  const score = density + codeOverlap * 0.12 + phraseBoost;
  return { chunk, score };
}

function importantPhraseBoost(text, queryText) {
  const haystack = `${text} ${queryText}`.toLowerCase();
  let boost = 0;
  for (const phrase of [
    'google translate',
    'third-party script',
    'callback',
    'green deployment',
    'dependency',
    'configuration',
    'rollback',
    'permission',
    'outage',
  ]) {
    if (haystack.includes(phrase)) boost += 0.2;
  }
  return boost;
}

function tokenize(text) {
  return String(text)
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .toLowerCase()
    .match(/[a-z0-9]{3,}/g)?.filter((token) => !STOP_WORDS.has(token)) || [];
}

function excerpt(text) {
  const clean = String(text).replace(/\s+/g, ' ').trim();
  if (clean.length <= 240) return clean;
  return `${clean.slice(0, 237).trim()}...`;
}
