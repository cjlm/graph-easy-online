import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: false });
const page = await browser.newPage();

await page.goto('http://localhost:5173/graph-easy/');
await page.waitForLoadState('networkidle');

console.log('Waiting for app to load...');
await page.waitForTimeout(5000);

// Take screenshot
await page.screenshot({ path: '/tmp/app-screenshot.png', fullPage: true });
console.log('Screenshot saved to /tmp/app-screenshot.png');

// Get all button text
const buttons = await page.locator('button').allTextContents();
console.log('\nButtons on page:', buttons);

// Get any select elements
const selects = await page.locator('select').count();
console.log('Number of select elements:', selects);

// Look for pre elements
const pres = await page.locator('pre').count();
console.log('Number of pre elements:', pres);

if (pres > 0) {
  const preText = await page.locator('pre').first().textContent();
  console.log('\nFirst pre element content (first 200 chars):');
  console.log(preText?.substring(0, 200));
}

await page.waitForTimeout(3000);
await browser.close();
