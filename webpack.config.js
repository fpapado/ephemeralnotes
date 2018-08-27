const HtmlWebpackPlugin = require("html-webpack-plugin");
const Critters = require("critters-webpack-plugin");
const SizePlugin = require("size-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

// webpack.config.js
module.exports = {
  entry: ["./dist/js/elm.js", "./src/styles/index.css"],
  output: {
    path: __dirname + "/dist",
    filename: "index.js"
  },
  plugins: [
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
    new Critters({
      // Outputs: <link rel="preload" onload="this.rel='stylesheet'"> and LoadCSS fallback
      //preload: "js",
      preload: "swap"

      // Don't inline critical font-face rules, but preload the font URLs:
      // preloadFonts: true
      // font: true
    }),
    // Track bundle size
    new SizePlugin()
  ],
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
