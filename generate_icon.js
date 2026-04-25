const sharp = require('sharp');
const path = require('path');

const svgPath = path.join(__dirname, 'assets/images/logo_uwangku.svg');
const pngPath = path.join(__dirname, 'assets/images/logo_uwangku_icon.png');

sharp(svgPath)
  .resize(1024, 1024)
  .png()
  .toFile(pngPath)
  .then(info => console.log('Icon generated:', info))
  .catch(err => console.error('Error:', err));