import sharp from 'sharp';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '..');

const svgPath = resolve(projectRoot, 'assets/images/logo.svg');
const svgContent = readFileSync(svgPath, 'utf-8');

// Read the SVG viewBox to understand dimensions
// The SVG viewBox is "40 40 240 240", so the logo area is 240x240 starting at (40,40)
// We need to render the full 320x320 viewport

const sizes = [
  { name: 'ic_launcher_1024.png', size: 1024 },
  { name: 'ic_launcher_512.png', size: 512 },
  { name: 'ic_launcher_192.png', size: 192 },
];

const outputDir = resolve(projectRoot, 'assets/images/source');

for (const { name, size } of sizes) {
  // Wrap SVG with explicit width/height for sharp to render at correct size
  const wrappedSvg = svgContent.replace(
    '<svg viewBox="80 80 160 160"',
    `<svg viewBox="80 80 160 160" width="${size}" height="${size}"`
  );
  
  await sharp(Buffer.from(wrappedSvg))
    .resize(size, size)
    .png()
    .toFile(resolve(outputDir, name));
    
  console.log(`Generated ${name} (${size}x${size})`);
}

// Also generate the foreground-only version (no background rect) for adaptive icons
const fgSvg = svgContent
  .replace(/<rect[^/]*\/>/g, '') // Remove the dark background rect
  .replace(
    '<svg viewBox="80 80 160 160"',
    `<svg viewBox="30 30 260 260" width="1024" height="1024"`
  );

await sharp(Buffer.from(fgSvg))
  .resize(1024, 1024)
  .png()
  .toFile(resolve(outputDir, 'ic_launcher_foreground.png'));

console.log('Generated ic_launcher_foreground.png (1024x1024)');
console.log('Done!');
