# Build Pipeline

:construction: This page is a Work In Progress :construction:

The entry point of the application in the browser is Javascript.
When developing, however, we use Elm and TypeScript.
Both Elm and TypeScript have a compiler that allows us to transform their code into Javascript that the browser understands.
Furthermore, in order to bring everything together under a single module system, we use _bundling_ with [webpack](https://webpack.js.org/);

All this allows us to import the `Main.elm` file at the entry point `index-dev.ts` or `index-prod.ts`, and also make use of Javascript modules and ecosystem.
Webpack also allows us to automatically inject the scripts into `index.html`, extract critical CSS via `Critters`, hash assets consistently, and finally use `Workbox` to create a manifest for our Service Worker.

I have done my best to leave [comments in webpack.config.js](/webpack.config.js), in order to guide you around. I realise that large webpack configs can be daunting, so please get in touch if there is anything unclear!

## Development

In development, we load Elm into webpack's representation of the world via `elm-webpack-loader`.
This allows us to import Elm directly in index:

```js
import {Elm} from './Main.elm';
```

We also use `elm-hot-webpack-loader` to allow hot-reloading of Elm code.
This allows us to see changes to the code faster, and without losing browser state.

## Production

In production, we do something different.
Instead of using `elm-webpack-loader`, we use `elm make` directly, minify the output ourselves, and then import the resulting `dist/js/elm.js` through webpack.
To do this, we split the entry points as `index-dev.js` and `index-prod.js`.

This is a bit strange, but it is for one specific reason:
The minimiser can do more compression on the output if it has some guarantees about the code being pure and other things. These guarantees hold for Elm, so it is desirable to use it.

We define the following command in `package.json`

```
"build:uglify": "uglifyjs dist/js/elm.js --compress 'pure_funcs=\"F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9\",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=dist/js/elm.js"
```

At the time of writing, this is the difference between `12.3kB` and `17kB`.
Perhaps this difference is a constant, or it grows at some rate.
It would be interesting to investigate this further, but for the purpose of getting this project out, I will defer that.
