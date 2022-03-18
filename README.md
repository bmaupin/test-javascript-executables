Testing various methods for packaging Node.js apps into self-contained executables

## Packaging your Node.js application into a self-contained executable

#### (Recommended) For the smallest binary, use `nexe`

Out of all the tools I tested, [`nexe`](https://github.com/nexe/nexe) has the most flexibility and can produce the smallest binaries. See below for more details.

ⓘ Most of the steps here are optional; adjust them to suit your needs

1. Figure out which version of Node.js to use

   ⚠ Using an older version of Node.js can be a security risk

   Older versions of Node.js are much smaller (see below). Depending how large your code is and what features you're using, you could try using an older version of Node and/or transpiling your code.

   For TypeScript, you can use this to target older versions of Node.js: [Node Target Mapping](https://github.com/microsoft/TypeScript/wiki/Node-Target-Mapping)

1. Bundle your code to take advantage of tree shaking, minification, etc.

   Common bundlers include [Vite](https://vitejs.dev/), [Parcel](https://parceljs.org/), [Rollup](https://rollupjs.org/), [webpack](https://webpack.js.org/)

1. Build Node.js

   For example, to build Node.js with small ICU (see below for more options):

   ```
   npx nexe app.js --build --no-mangle --configure=--with-intl=small-icu --make=-j$(nproc) --python=$(which python3) --verbose
   ```

   (`--python=$(which python3)` uses Python 3, which is required for newer versions of Node)

1. (Optional) Make a copy of the Node binary, e.g.

   ```
   cp ~/.nexe/16.14.1/out/Release/node ~/.nexe/16.14.1/out/Release/node.bak
   ```

1. Strip debugging symbols

   ⚠ Only do this if you're not using any native modules, as the debugging symobols are required for native modules

   ```
   strip ~/.nexe/16.14.1/out/Release/node
   ```

1. Run [`upx`](https://upx.github.io/) on the node binary, e.g.

   ```
   upx ~/.nexe/16.14.1/out/Release/node
   ```

1. Now run `npx nexe --build` one more time to package your application using the smaller Node binary, e.g.

   ```
   npx nexe app.js --build
   ```

#### Run `nexe` using Docker

This project has a sample [`Dockerfile`](Dockerfile) you can optionally use, e.g.

```
$ docker build . -t nexe

$ docker run --rm -v "$PWD:/build" nexe sh -c "cd /build; nexe app.js --build"

$ ls -lh app
-rwxr-xr-x 1 root root 14M Mar 16 13:25 app
```

#### For ease-of-use, use `pkg`

[`pkg`](https://github.com/vercel/pkg) doesn't work with `strip` or `upx`, so isn't able to produce the smallest binaries. But it has more versions of Node precompiled (meaning you probably won't need to compile it yourself) and cross-compiles by default out-of-the-box, e.g.

```
$ npx pkg app.js
$ ls -1
app.js
app-linux
app-macos
app-win.exe
```

## More details

#### Comparing different tools and methods

| Method                                                                | Runtime version | Linux binary size | Time to execute |
| --------------------------------------------------------------------- | --------------- | ----------------- | --------------- |
| `npx pkg .`                                                           | Node 14.18.2    | 37 MB             | 0m0.042s        |
| `npx pkg --compress GZip .`¹                                          | Node 14.18.2    | 37 MB             | 0m0.042s        |
| `npx nexe app.js --build`                                             | Node 14.18.2    | 75 MB             | 0m0.054s        |
| `npx nexe app.js --build` (with `strip` and `upx`)                    | Node 14.18.2    | 23 MB             | 0m0.250s        |
| `npx nexe app.js --build` (with `small-icu`, `strip`, and `upx`)      | Node 14.18.2    | 14 MB             | 0m0.183s        |
| `npx nexe app.js --build` (with `--without-intl`, `strip`, and `upx`) | Node 14.18.2    | 11 MB             | 0m0.154s        |
| `deno compile app.js`²                                                | Deno 1.19.3     | 84 MB             | 0m0.026s        |

Notes:

1. `pkg --compress` only compresses the JavaScript source, so it has little impact on our hello world test code
1. Deno used to have a `compile --lite` option, but unfortunately it was removed: [https://github.com/denoland/deno/issues/10507](https://github.com/denoland/deno/issues/10507)

#### Comparing different versions of Node.js

| Version | Full size of Node | `--without-intl`, `strip`, `upx` |
| ------- | ----------------- | -------------------------------- |
| 16.14.0 | 79 MB             | 14 MB                            |
| 14.18.2 | 75 MB             | 11 MB                            |
| 12.22.0 | 47 MB             | 11 MB                            |
| 10.24.1 | 40 MB             | 9.4 MB                           |
| 8.17.0  | 34 MB             | 7.9 MB                           |

**Note:** For Node <= 10, you'll need to use Python 2 to do the build, e.g.

```
npx nexe app.js --target linux-x64-10.24.1 --build --no-mangle --make=-j$(nproc) --python=$(which python2) --verbose
```

#### Strip debugging symbols

Debugging symbols could be stripped from the Node/Deno binaries in the case where native modules aren't needed

- This works with `nexe` and Deno (see [here](https://github.com/denoland/deno/issues/9198#issuecomment-764007074)), but doesn't seem to have any effect with `pkg`

#### `upx`

[`upx`](https://upx.github.io/) can be used to reduce the size of binaries at a small startup cost (depending on the size of your application)

- `nexe` works with `upx`
- `pkg` does not work with `upx` ([https://github.com/vercel/pkg/issues/50](https://github.com/vercel/pkg/issues/50))
- Deno may work with `upx`; see [https://github.com/denoland/deno/issues/986#issuecomment-742041812](https://github.com/denoland/deno/issues/986#issuecomment-742041812)

#### Node builds with smaller/no `Intl` support

See here for implications of the various options: [https://github.com/nodejs/node/blob/master/BUILDING.md#intl-ecma-402-support](https://github.com/nodejs/node/blob/master/BUILDING.md#intl-ecma-402-support)

Size comparisons for Node binary (using Node v14.18.2):

| Build type              | Normal size | Stripped | Stripped and `upx` |
| ----------------------- | ----------- | -------- | ------------------ |
| Normal (full ICU)       | 75 MB       | 65 MB    | 22 MB              |
| `--with-intl=small-icu` | 51 MB       | 41 MB    | 14 MB              |
| `--without-intl`        | 40 MB       | 32 MB    | 11 MB              |

## Other options

#### Bundled JS instead of self-contained executable

For large applications, a 10+ MB binary won't make much of a difference. If you want something smaller and don't mind requiring users to have Node.js installed in order to run your application, you can use a JS bundler to bundle the application with its dependencies into a single JS file, then add a shebang at the top, e.g.:

```javascript
#!/usr/bin/env node

console.log('Hello world');
```

Then users can just run the bundled JS directly:

```
$ chmod +x app.js
$ ./app.js
Hello world
```

#### QuickJS

If you want the smallest binary possible (e.g. for embedded systems), you probably want use something like [QuickJS](https://bellard.org/quickjs/) instead, but it's slower than Node.js and has its own API, making it incompatible with existing Node.js applications.
