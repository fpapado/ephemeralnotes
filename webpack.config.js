const HtmlWebpackPlugin = require('html-webpack-plugin');
const ScriptExtHtmlWebpackPlugin = require('script-ext-html-webpack-plugin');
const Critters = require('critters-webpack-plugin');
const SizePlugin = require('size-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const WorkboxPlugin = require('workbox-webpack-plugin');
const ForkTsCheckerNotifierWebpackPlugin = require('fork-ts-checker-notifier-webpack-plugin');
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');

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
  context: process.cwd(),
  mode: ifProduction('production', 'development'),
  entry: {
    main: ifProduction(['./src/index-prod.ts'], ['./src/index-dev.ts']),
  },
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
    // Adjust scripts in template
    new ScriptExtHtmlWebpackPlugin({
      preload: ['main'],
      chunks: 'initial',
    }),
    ifNotProduction(new ForkTsCheckerWebpackPlugin()),
    new ForkTsCheckerNotifierWebpackPlugin({
      title: 'Typescript',
      excludeWarnings: false,
    }),
    new OptimizeCssAssetsPlugin({
      cssProcessor: cssnano,
      cssProcessorPluginOptions: {
        // The mergeLonghand option is unsafe if we rely on the cascade for env() fallbacks,
        // such as safe area insets for iPhone X
        // @see https://github.com/cssnano/cssnano/issues/803
        preset: ['default', {mergeLonghand: false}],
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
        // Do not removed inlined selectors from source
        // This is done because the feature is buggy and removes media queries :/
        pruneSource: false,
        // Outputs: <link rel="preload" onload="this.rel='stylesheet'"> and LoadCSS fallback
        // NOTE: Actually, only does the latter, maybe a PR opportunity/
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
        test: /.tsx?$/,
        use: [
          {
            loader: 'ts-loader',
            options: {transpileOnly: ifProduction(false, true)},
          },
        ],
      },
      {
        test: /\.css$/,
        use: [
          ifNotProduction(
            {loader: 'style-loader'},
            {
              loader: MiniCssExtractPlugin.loader,
            }
          ),
          'css-loader',
        ],
        // Exclude leaflet.css; we include only a reference to it
        exclude: /leaflet\.css/,
      },
      {
        test: /.css$/,
        use: [
          // Use postcss to bundle leaflet css, while keeping it out of webpack
          // This is because we want to reference the leaflet css style inside of the web component
          // whereas webpack (css-loader + extractText) assumes top-level styles.
          // With top-level styles, we would need to use a <link>. We could do that with file-loader,
          // but it leads to a flash of unstyled text. So we must either inline the <style> or use the constructable stylesheets API
          {loader: 'postcss-loader'},
        ],
        // Include a reference to leaflet.css, hashed, but do not touch it otherwise
        include: /leaflet\.css/,
      },
      // Load references to file URLs after resolution
      // Used, for example, to link urls
      {
        test: /\.(png|jpg|gif)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: '[name]-[hash:20].[ext]',
              outputPath: 'assets/images',
              publicPath: 'assets/images',
            },
          },
        ],
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.elm', '.css'],
  },
  devServer: {
    compress: true,
    // E.g. /404 should serve index.html, and let Elm handle the route
    historyApiFallback: true,
    hot: true,
    stats: 'errors-only',
  },
};

function isUndefined(val) {
  return typeof val === 'undefined';
}
