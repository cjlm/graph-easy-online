import { chromium } from 'playwright';

console.log('Getting ACTUAL Perl output for Seven Bridges...\n');

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

await page.goto('http://localhost:5173/graph-easy/');
await page.waitForLoadState('networkidle');

console.log('Waiting for app...');
await page.waitForTimeout(5000);

// Fill in Seven Bridges input
const input = `[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ Island Lomse ] -- [ South Bank ]
[ Island Lomse ] -- [ Island Kneiphof ]`;

console.log('Setting input...');
await page.locator('textarea').first().fill(input);
await page.waitForTimeout(1000);

// Click Perl button
console.log('Clicking Perl engine button...');
await page.locator('button:has-text("Perl")').click();

// Wait for WebPerl to process
console.log('Waiting for WebPerl to process...');
await page.waitForTimeout(10000);

// Get output
const output = await page.locator('pre').first().textContent();

console.log('\n' + '='.repeat(80));
console.log('PERL OUTPUT (Seven Bridges - no labels):');
console.log('='.repeat(80));
console.log(output);
console.log('='.repeat(80));

await browser.close();
