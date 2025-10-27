import { chromium } from 'playwright';

console.log('Launching browser to get Perl output from main app...\n');

const browser = await chromium.launch({ headless: false }); // visible for debugging
const page = await browser.newPage();

// Go to main app
console.log('Loading main app...');
await page.goto('http://localhost:5173/graph-easy/');

// Wait for page to be ready
await page.waitForLoadState('networkidle');
console.log('Page loaded, waiting for WebPerl...');
await page.waitForTimeout(15000); // WebPerl needs time

// Find and click the example dropdown
console.log('Selecting Seven Bridges example...');
const exampleButtons = await page.locator('button:has-text("Simple Flow")').first();
if (await exampleButtons.isVisible()) {
  await exampleButtons.click();
  await page.waitForTimeout(500);
  await page.locator('button:has-text("Seven Bridges")').click();
  await page.waitForTimeout(1000);
}

// Make sure WebPerl is selected
console.log('Selecting WebPerl engine...');
const engineSelect = await page.locator('select').first();
await engineSelect.selectOption('webperl');
await page.waitForTimeout(2000);

// Get the output
console.log('Extracting output...');
const output = await page.locator('pre').first().textContent();

console.log('\n' + '='.repeat(80));
console.log('PERL OUTPUT:');
console.log('='.repeat(80));
console.log(output);
console.log('='.repeat(80));

await page.waitForTimeout(2000);
await browser.close();
