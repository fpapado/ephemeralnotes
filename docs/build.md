We use Elm, paired with webpack.
This allows us to import the `Main.elm` file at the entry point `index.js`, and also make use of Javascript modules and ecosystem.
Webpack also allows us to automatically inject the scripts into `index.html`, extract critical CSS via `Critters`, hash assets consistently, and finally use `Workbox` to create a manifest for our Service Worker.

# Dev

In development, we load Elm into webpack's representation of the world via `elm-webpack-loader`.
This allows us to import Elm directly in `index.js`:

```js
import {Elm} from './Main.elm';
```

We also use `elm-hot-webpack-loader` to allow [hot-reloading]() of Elm code.
In short, this allows us to see changes to the code faster, and without losing browser state.

# Production

In production, we do something different.
Instead of using `elm-webpack-loader`, we use `elm-make` directly, minify the output, and then import the resulting `dist/js/elm.js` through webpack.
To do this, we split the entry points as `index-dev.js` and `index-prod.js`.

This is a bit strange, but it is for one specific reason:
Uglify (the minimiser) can do more compression on the output if it has some guarantees about the code being pure and other things. This is true in the case of Elm, so it is desirable to use it.

```
"build:uglify": "uglifyjs dist/js/elm.js --compress 'pure_funcs=\"F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9\",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=dist/js/elm.js"
```

At the time of writing, this is the difference between `12.3kB` and `17kB`.
Perhaps this difference is a constant, or it grows at some rate.
It would be interesting to investigate this further, but for the purpose of getting this project out, I will defer that.

These would be unsafe with the general JS code that we might import in `index.js`, so they have to be separate.
I have not found a way to use a separate minimiser for one input type, in webpack.
The `minimizer` option seemed promising, but nothing that I could use.
If such a thing is possible, we should move everything inside of webpack.

Let me know if you are aware of any such option :)

[There was some discussion on the elm-webpack-loader PR tracker](https://github.com/elm-community/elm-webpack-loader/pull/142#issuecomment-416568288)
