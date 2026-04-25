const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const svgPath = path.join(__dirname, 'assets/images/logo_uwangku.svg');
const outputDir = path.join(__dirname, 'assets/images');

// Android sizes
const androidSizes = [
  { name: 'mipmap-mdpi/ic_launcher.png', size: 48 },
  { name: 'mipmap-hdpi/ic_launcher.png', size: 72 },
  { name: 'mipmap-xhdpi/ic_launcher.png', size: 96 },
  { name: 'mipmap-xxhdpi/ic_launcher.png', size: 144 },
  { name: 'mipmap-xxxhdpi/ic_launcher.png', size: 192 },
];

// iOS sizes
const iosSizes = [
  { name: 'AppIcon-20x20@1x.png', size: 20 },
  { name: 'AppIcon-20x20@2x.png', size: 40 },
  { name: 'AppIcon-20x20@3x.png', size: 60 },
  { name: 'AppIcon-29x29@1x.png', size: 29 },
  { name: 'AppIcon-29x29@2x.png', size: 58 },
  { name: 'AppIcon-29x29@3x.png', size: 87 },
  { name: 'AppIcon-40x40@1x.png', size: 40 },
  { name: 'AppIcon-40x40@2x.png', size: 80 },
  { name: 'AppIcon-40x40@3x.png', size: 120 },
  { name: 'AppIcon-60x60@2x.png', size: 120 },
  { name: 'AppIcon-60x60@3x.png', size: 180 },
  { name: 'AppIcon-76x76@1x.png', size: 76 },
  { name: 'AppIcon-76x76@2x.png', size: 152 },
  { name: 'AppIcon-83.5x83.5@2x.png', size: 167 },
  { name: 'AppIcon-1024x1024@3x.png', size: 1024 },
];

async function generateIcons() {
  const svgBuffer = fs.readFileSync(svgPath);
  
  console.log('Generating Android icons...');
  for (const size of androidSizes) {
    await sharp(svgBuffer)
      .resize(size.size, size.size)
      .png()
      .toFile(path.join('android/app/src/main/res', size.name));
    console.log(`  Created ${size.name} (${size.size}x${size.size})`);
  }
  
  console.log('Generating iOS icons...');
  for (const size of iosSizes) {
    await sharp(svgBuffer)
      .resize(size.size, size.size)
      .png()
      .toFile(path.join('ios/Runner/Assets.xcassets/AppIcon.appiconset', size.name));
    console.log(`  Created ${size.name} (${size.size}x${size.size})`);
  }
  
  // Also create main icon in assets
  await sharp(svgBuffer)
    .resize(512, 512)
    .png()
    .toFile(path.join(outputDir, 'logo_uwangku_icon.png'));
  console.log('Created assets/images/logo_uwangku_icon.png (512x512)');
  
  console.log('Done!');
}

generateIcons().catch(console.error);