import { chromium } from 'playwright';

console.log('Getting Perl output for Seven Bridges...\n');

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

// Go to main app
await page.goto('http://localhost:5173/graph-easy/');
await page.waitForLoadState('networkidle');

console.log('Waiting for WebPerl to initialize (15s)...');
await page.waitForTimeout(15000);

// Look for the example with Seven Bridges in the text
console.log('Setting up Seven Bridges input...');
const textarea = await page.locator('textarea').first();
const sevenBridgesInput = `[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ Island Lomse ] -- [ South Bank ]
[ Island Lomse ] -- [ Island Kneiphof ]`;

await textarea.fill(sevenBridgesInput);
await page.waitForTimeout(1000);

// Click the WebPerl engine button
console.log('Selecting WebPerl engine...');
await page.click('button:has-text("WebPerl")');
await page.waitForTimeout(3000);

// Get the pre element with output
const output = await page.locator('pre').first().textContent();

console.log('\n' + '='.repeat(80));
console.log('PERL OUTPUT (Seven Bridges):');
console.log('='.repeat(80));
console.log(output);
console.log('='.repeat(80));

await browser.close();
