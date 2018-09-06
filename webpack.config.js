const HtmlWebpackPlugin = require('html-webpack-plugin');
const Critters = require('critters-webpack-plugin');
const SizePlugin = require('size-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const WorkboxPlugin = require('workbox-webpack-plugin');
const history = require('koa-connect-history-api-fallback');

const cssnano = require('cssnano');

// Utils
const removeEmpty = items => items.filter(i => i !== null && i !== undefined);
const propIf = (envVal, value, alt) => (envVal ? value : alt);
const propIfNot = (envVal, value, alt) => (!envVal ? value : alt);
const makeIfProp = envValue => (value, alt) =>
  isUndefined(value) ? envValue : propIf(envValue, value, alt);
const makeIfNotProp = envValue => (value, alt) =>
  isUndefined(value) ? !envValue : propIfNot(envValue, value, alt);

// Env setup
const isProduction = process.env.NODE_ENV == 'production';
const ifProduction = makeIfProp(isProduction);
const ifNotProduction = makeIfNotProp(isProduction);

// webpack.config.js
module.exports = {
  mode: ifProduction('production', 'development'),
  entry: ifProduction(['./src/index-prod.js'], ['./src/index-dev.js']),
  output: {
    path: __dirname + '/dist',
    chunkFilename: '[name]-[contenthash].js',
    filename: ifProduction('[name]-[contenthash].js', '[name].js'),
    publicPath: '/',
  },
  plugins: removeEmpty([
    // Place things in template
    new HtmlWebpackPlugin({
      template: 'index.html',
    }),
    new OptimizeCssAssetsPlugin({
      cssProcessor: cssnano,
      cssProcessorOptions: {
        discardComments: {
          removeAll: true,
        },
      },
      canPrint: false,
    }),
    new MiniCssExtractPlugin({
      // Options similar to the same options in webpackOptions.output
      // both options are optional
      filename: ifNotProduction('[name].css', '[name]-[contenthash].css'),
      chunkFilename: ifNotProduction('[id].css', '[id]-[hash].css'),
    }),
    // Inline critical css, preload fonts
    ifProduction(
      new Critters({
        // Outputs: <link rel="preload" onload="this.rel='stylesheet'"> and LoadCSS fallback
        preload: 'js',
        // Inline critical font-face rules, and preload the font URLs
        inlineFonts: true,
        // preloadFonts: false
        // fonts: true
      })
    ),
    ifProduction(
      new WorkboxPlugin.InjectManifest({
        swSrc: './src/sw.js',
        importWorkboxFrom: 'local',
      })
    ),
    // Track bundle size
    ifProduction(new SizePlugin()),
  ]),
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: ifProduction(
          [{loader: 'elm-webpack-loader'}],
          [
            {loader: 'elm-hot-webpack-loader'},
            {
              loader: 'elm-webpack-loader',
              options: {
                // add Elm's debug overlay to output
                debug: true,
                forceWatch: true,
                cwd: __dirname,
              },
            },
          ]
        ),
      },
      {
        test: /\.css$/,
        use: [
          {
            loader: ifNotProduction(
              'style-loader',
              MiniCssExtractPlugin.loader
            ),
            options: {
              // you can specify a publicPath here
              // by default it use publicPath in webpackOptions.output
              // publicPath: "../"
            },
          },
          'css-loader',
        ],
      },
    ],
  },
  serve: {
    add: (app, _middleware, _options) => {
      // routes /xyz -> /index.html
      app.use(history());
      // e.g.
      // app.use(convert(proxy('/api', { target: 'http://localhost:5000' })));
    },
  },
};

function isUndefined(val) {
  return typeof val === 'undefined';
}
