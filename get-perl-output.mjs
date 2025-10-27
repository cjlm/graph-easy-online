import { chromium } from 'playwright';

const input = `[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ Island Lomse ] -- [ South Bank ]
[ Island Lomse ] -- [ Island Kneiphof ]`;

console.log('Launching browser to get Perl output...\n');

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

// Go to the comparison page
await page.goto('http://localhost:5173/graph-easy/perl-seven-bridges.html');

// Wait for WebPerl to load (it's slow!)
console.log('Waiting for WebPerl to initialize...');
await page.waitForTimeout(10000);

// Click the button to generate output
console.log('Clicking button to generate output...');
await page.click('button');

// Wait for Perl to execute
await page.waitForTimeout(5000);

// Get the output
const output = await page.textContent('#output');

console.log('PERL OUTPUT:');
console.log('='.repeat(80));
console.log(output);
console.log('='.repeat(80));

await browser.close();
