// Captures the open laptop from the main scene as a transparent PNG for the opener.
const { chromium } = require('playwright'); // npm i playwright
const path = require('path');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 2 });
  await page.goto('file://' + path.join(__dirname, 'index.html?render'));
  await page.waitForFunction(() => window.seek);
  await page.waitForTimeout(400);
  const clip = await page.evaluate(() => {
    window.seek(3.9 + 4.85);
    for (const s of ['#walk', '#end', '#capB1', '#capB2', '#pill', '#desk', '#capA']) document.querySelector(s).style.display = 'none';
    document.querySelector('#stage').style.background = 'transparent';
    document.body.style.background = 'transparent';
    document.documentElement.style.background = 'transparent';
    const r = [document.querySelector('#lid .front'), document.querySelector('#base')].map(e => e.getBoundingClientRect());
    const x = Math.min(...r.map(b => b.left)), y = Math.min(...r.map(b => b.top));
    return { x: x - 4, y: y - 4, width: Math.max(...r.map(b => b.right)) - x + 8, height: Math.max(...r.map(b => b.bottom)) - y + 8 };
  });
  await page.screenshot({ path: 'walk_laptop.png', clip, omitBackground: true });
  await browser.close();
  console.log(clip);
})();
