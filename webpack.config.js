const HtmlWebpackPlugin = require("html-webpack-plugin");
const Critters = require("critters-webpack-plugin");
const SizePlugin = require("size-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const WorkboxPlugin = require("workbox-webpack-plugin");

// Utils
const removeEmpty = items => items.filter(i => i !== null && i !== undefined);
const propIf = (envVal, value, alt) => (envVal ? value : alt);
const propIfNot = (envVal, value, alt) => (!envVal ? value : alt);
const makeIfProp = envValue => (value, alt) =>
  isUndefined(value) ? envValue : propIf(envValue, value, alt);
const makeIfNotProp = envValue => (value, alt) =>
  isUndefined(value) ? !envValue : propIfNot(envValue, value, alt);

// Env setup
const isProduction = process.env.NODE_ENV == "production";
const ifProduction = makeIfProp(isProduction);
const ifNotProduction = makeIfNotProp(isProduction);

// webpack.config.js
module.exports = {
  mode: ifProduction("production", "development"),
  entry: ["./src/index.js", "./src/styles/index.css"],
  output: {
    path: __dirname + "/dist",
    filename: "index.js"
  },
  plugins: removeEmpty([
    // Place things in template
    new HtmlWebpackPlugin({
      template: "index.html"
    }),
    new MiniCssExtractPlugin({
      // Options similar to the same options in webpackOptions.output
      // both options are optional
      filename: "[name].css",
      chunkFilename: "[id].css"
    }),
    // Inline critical (well, all) css preload fonts
    ifProduction(
      new Critters({
        // Outputs: <link rel="preload" onload="this.rel='stylesheet'"> and LoadCSS fallback
        preload: "js",
        // Inline critical font-face rules, and preload the font URLs
        // inlineFonts: false,
        // preloadFonts: false
        fonts: true
      })
    ),
    new WorkboxPlugin.InjectManifest({
      swSrc: "./src/sw.js",
      importWorkboxFrom: "local"
    }),
    // Track bundle size
    new SizePlugin()
  ]),
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              // you can specify a publicPath here
              // by default it use publicPath in webpackOptions.output
              // publicPath: "../"
            }
          },
          "css-loader"
        ]
      }
    ]
  }
};

function isUndefined(val) {
  return typeof val === "undefined";
}
