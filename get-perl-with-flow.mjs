import { chromium } from 'playwright';

console.log('Getting Perl output with flow:east directive...\n');

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

await page.goto('http://localhost:5173/graph-easy/');
await page.waitForLoadState('networkidle');

console.log('Waiting for app...');
await page.waitForTimeout(5000);

// Full Seven Bridges from the app
const input = `graph { flow: east; }

[ North Bank ] -- { label: Bridge 1; } [ Island Kneiphof ]
[ North Bank ] -- { label: Bridge 2; } [ Island Kneiphof ]
[ South Bank ] -- { label: Bridge 3; } [ Island Kneiphof ]
[ South Bank ] -- { label: Bridge 4; } [ Island Kneiphof ]
[ North Bank ] -- { label: Bridge 5; } [ Island Lomse ]
[ Island Lomse ] -- { label: Bridge 6; } [ South Bank ]
[ Island Lomse ] -- { label: Bridge 7; } [ Island Kneiphof ]`;

console.log('Setting input with flow:east...');
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
console.log('PERL OUTPUT (with flow:east and labels):');
console.log('='.repeat(80));
console.log(output);
console.log('='.repeat(80));

await browser.close();
