import sharp from 'sharp';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const hiddifyAppRoot = resolve(__dirname, '..');
const webAppRoot = resolve(hiddifyAppRoot, '../xboard-user-custom');

const svgPath = resolve(webAppRoot, 'src/assets/logo.svg');
const svgContent = readFileSync(svgPath, 'utf-8');

const outputDir = resolve(webAppRoot, 'public');

const sizes = [
  { name: 'logo192.png', size: 192 },
  { name: 'logo512.png', size: 512 },
  { name: 'apple-touch-icon.png', size: 180 },
];

for (const { name, size } of sizes) {
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

// Generate favicon.svg by just copying the content
import { writeFileSync } from 'fs';
writeFileSync(resolve(outputDir, 'favicon.svg'), svgContent);
console.log('Copied favicon.svg');

// Generate favicon.ico (32x32)
const wrappedSvgIco = svgContent.replace(
  '<svg viewBox="80 80 160 160"',
  `<svg viewBox="80 80 160 160" width="32" height="32"`
);
await sharp(Buffer.from(wrappedSvgIco))
  .resize(32, 32)
  .toFormat('png') // Standard way for simple ICO is just to rename a small PNG or we can just leave it as favicon.svg for modern browsers, but let's make a 32x32 png as favicon.ico
  .toFile(resolve(outputDir, 'favicon.ico'));

console.log('Generated favicon.ico (32x32)');
console.log('Done generating web icons!');
