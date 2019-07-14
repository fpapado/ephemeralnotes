module.exports = {
  plugins: {
    'postcss-import': {},
    autoprefixer: {},
    cssnano: {
      preset: [
        'default',
        // Unsafe transform when considering cascade + fallbacks
        // @see wepback.config.js
        {
          mergeLonghand: false,
        },
      ],
    },
  },
};
