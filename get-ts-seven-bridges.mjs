import { chromium } from 'playwright';

console.log('Getting TypeScript output for Seven Bridges...\\n');

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

await page.goto('http://localhost:5173/graph-easy/');
await page.waitForLoadState('networkidle');

console.log('Waiting for app...');
await page.waitForTimeout(5000);

// Fill in Seven Bridges input with flow:east
const input = `graph { flow: east; }

[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ Island Lomse ] -- [ South Bank ]
[ Island Lomse ] -- [ Island Kneiphof ]`;

console.log('Setting input...');
await page.locator('textarea').first().fill(input);
await page.waitForTimeout(1000);

// Click TS button (or ELK if that's the TypeScript button)
console.log('Clicking TS button...');
await page.locator('button[title*="TypeScript"]').click();

// Wait for processing
console.log('Waiting for TS to process...');
await page.waitForTimeout(2000);

// Get output
const output = await page.locator('pre').first().textContent();

console.log('\\n' + '='.repeat(80));
console.log('TYPESCRIPT OUTPUT (Seven Bridges with flow:east):');
console.log('='.repeat(80));
console.log(output);
console.log('='.repeat(80));

await browser.close();
