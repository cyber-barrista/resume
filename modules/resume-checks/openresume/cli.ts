// OpenResume's parser run in Node: prints what it extracts from a PDF as JSON.
// Bundled by esbuild from inside the OpenResume checkout, whose tsconfig resolves `lib/...`.
import { parseResumeFromPdf } from 'lib/parse-resume-from-pdf';
import * as worker from 'pdfjs-dist/build/pdf.worker.js';

declare global {
  var pdfjsWorker: unknown;
}

// OpenResume hands pdf.js a browser worker URL. In Node pdf.js runs the worker in-process, and takes it from this
// global when set instead of require()-ing that URL.
globalThis.pdfjsWorker = worker;

const main = async (): Promise<void> => {
  const pdf = process.argv[2];
  if (pdf === undefined) {
    console.error('usage: node <parser> <resume.pdf>');
    process.exit(2);
  }
  const resume = await parseResumeFromPdf(pdf);
  process.stdout.write(`${JSON.stringify(resume, null, 2)}\n`);
};

void main();
