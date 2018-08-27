const HtmlWebpackPlugin = require("html-webpack-plugin");
const Critters = require("critters-webpack-plugin");
const SizePlugin = require("size-plugin");

// webpack.config.js
module.exports = {
  entry: "./dist/js/elm.js",
  output: {
    path: __dirname + "/dist/js",
    filename: "index.js"
  },
  plugins: [
    // Inline critical (well, all) css preload fonts
    new Critters({
      // Outputs: <link rel="preload" onload="this.rel='stylesheet'"> and LoadCSS fallback
      preload: "js",

      // Don't inline critical font-face rules, but preload the font URLs:
      preloadFonts: true
      // font: true
    }),
    // Place things in template
    new HtmlWebpackPlugin({
      template: "index.html",
      filename: "dist/index.html"
    }),
    // Track bundle size
    new SizePlugin()
  ]
};
