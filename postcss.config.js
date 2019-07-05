module.exports = {
  plugins: {
    'postcss-import': {},
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
