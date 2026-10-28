// Usage: node render.js stills 0.5 2.3 ...   |   node render.js video
const { chromium } = require('playwright'); // npm i playwright
const { spawn } = require('child_process');
const path = require('path');
(async () => {
  const [mode, ...times] = process.argv.slice(2);
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1.5 });
  await page.goto('file://' + path.join(__dirname, 'index.html?render'));
  await page.waitForFunction(() => window.seek && document.fonts.ready);
  await page.waitForTimeout(500);
  if (mode === 'stills') {
    for (const t of times) {
      await page.evaluate(t => window.seek(t), +t);
      await page.screenshot({ path: `out/still_${t}.jpg`, quality: 80, type: 'jpeg' });
    }
  } else {
    const fps = 30, dur = await page.evaluate(() => window.DURATION);
    const ff = spawn('ffmpeg', ['-y', '-f', 'image2pipe', '-framerate', fps, '-i', '-', '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
      '-crf', '16', '-preset', 'slow', '-movflags', '+faststart', 'out/LidAwake_promo.mp4'], { stdio: ['pipe', 'ignore', 'inherit'] });
    for (let i = 0; i <= Math.round(dur * fps); i++) {
      await page.evaluate(t => window.seek(t), i / fps);
      const buf = await page.screenshot({ type: 'png' });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  await browser.close();
})();
