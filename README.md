Testing various methods for packaging Node.js apps into self-contained executables

## TL;DR

#### (Recommended) For the smallest binary, use `nexe`

⚠ See below for more information on each of these steps, including cost vs. benefit

1. Build Node.js with small ICU

   ```
   npx nexe app.js --build --no-mangle --configure=--with-intl=small-icu --make=-j$(nproc) --python=$(which python3) --verbose
   ```

1. Make a copy of the Node binary, e.g.

   ```
   cp ~/.nexe/16.14.1/out/Release/node ~/.nexe/16.14.1/out/Release/node.bak
   ```

1. Strip debugging symbols

   ```
   strip ~/.nexe/16.14.1/out/Release/node
   ```

1. Run [`upx`](https://upx.github.io/) on the node binary, e.g.

   ```
   upx --lzma ~/.nexe/16.14.1/out/Release/node
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
-rwxr-xr-x 1 root root 9.8M Mar 16 13:25 app
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

#### Optimization 1: Use an older version of Node.js

- Cost
  - ⚠ Potential security issues
  - If you have to transpile your code to work with older versions of Node.js, you may break even or even end up with a larger binary in the end
- Benefit

  | Version | Size of Node binary |
  | ------- | ------------------- |
  | 16.14.0 | 79 MB               |
  | 14.18.2 | 75 MB               |
  | 12.22.0 | 47 MB               |
  | 10.24.1 | 40 MB               |
  | 8.17.0  | 34 MB               |

**Note:** For Node <= 10, you'll need to use Python 2 to do the build, e.g.

```
npx nexe app.js --target linux-x64-10.24.1 --build --no-mangle --make=-j$(nproc) --python=$(which python2) --verbose
```

For TypeScript, you can use this to target older versions of Node.js: [Node Target Mapping](https://github.com/microsoft/TypeScript/wiki/Node-Target-Mapping)

#### Optimization 2: Use a bundler

This allows you to take advantage of tree shaking, minification, etc.

Common bundlers include [Vite](https://vitejs.dev/), [Parcel](https://parceljs.org/), [Rollup](https://rollupjs.org/), [webpack](https://webpack.js.org/)

#### Optimization 3: Build Node.js with small or no `Intl` support

e.g. to build Node.js with small ICU

```
npx nexe app.js --build --no-mangle --configure=--with-intl=small-icu --make=-j$(nproc) --python=$(which python3) --verbose
```

- Cost
  - `--with-intl=small-icu` includes the full `Intl` APIs with only English data; seems like it would be safe in most cases
  - `--without-intl` removes some APIs altogether, including `Intl`; this would probably break libraries and applications that rely on those APIs
  - See here for more information: [https://github.com/nodejs/node/blob/master/BUILDING.md#intl-ecma-402-support](https://github.com/nodejs/node/blob/master/BUILDING.md#intl-ecma-402-support)
- Benefit

  | Version | Normal (full ICU) | `--with-intl=small-icu` | `--without-intl` |
  | ------- | ----------------- | ----------------------- | ---------------- |
  | 16.14.0 | 79 MB             | 54 MB                   | 45 MB            |
  | 14.18.2 | 75 MB             | 51 MB                   | 40 MB            |
  | 12.22.0 | 47 MB             | 47 MB¹                  | 38 MB            |

  Notes:

  1. [Node <= 12 builds with small ICU by default](https://nodejs.org/docs/latest-v12.x/api/intl.html#intl_options_for_building_node_js); [Node 13+ builds with full ICU by default](https://nodejs.org/docs/latest-v13.x/api/intl.html#intl_options_for_building_node_js)

#### Optimization 4: Strip debugging symbols

e.g.

```
strip ~/.nexe/16.14.1/out/Release/node
```

- Cost
  - Debugging symbols are required for native Node modules, so stripping the Node binary will break them
- Benefit

  | Version | Full Node binary | Stripped |
  | ------- | ---------------- | -------- |
  | 16.14.0 | 79 MB            | 68 MB    |
  | 14.18.2 | 75 MB            | 64 MB    |
  | 12.22.0 | 47 MB            | 38 MB    |

#### Optimization 5: [`upx`](https://upx.github.io/)

e.g.

```
upx --lzma ~/.nexe/16.14.1/out/Release/node
```

- Cost
  - Increased startup time
  - ⚠ There have been reports of antivirus software incorrectly flagging upx-compressed binaries ([https://github.com/upx/upx/issues?q=is%3Aissue+virus+](https://github.com/upx/upx/issues?q=is%3Aissue+virus+)) which might negate its benefits, particularly on Windows
- Benefit (tests done using Node 16.14.0)

  | Compression method | Size of Node binary | Time to run hello world |
  | ------------------ | ------------------- | ----------------------- |
  | Uncompressed       | 79 MB               | 0m0.044s                |
  | `upx`              | 29 MB               | 0m0.268s                |
  | `upx --lzma`       | 20 MB               | 0m1.155s                |

#### Putting it all together

| Version | Full size of Node | `--with-intl=small-icu`, `strip`, `upx --lzma` | `--without-intl`, `strip`, `upx --lzma` |
| ------- | ----------------- | ---------------------------------------------- | --------------------------------------- |
| 16.14.0 | 79 MB             | 13 MB                                          | 9.8 MB                                  |
| 14.18.2 | 75 MB             | 11 MB                                          | 8.6 MB                                  |
| 12.22.0 | 47 MB             | 11 MB                                          | 8.1 MB                                  |
| 10.24.1 | 40 MB             | 9.1 MB                                         | 7.0 MB                                  |
| 8.17.0  | 34 MB             | 7.7 MB                                         | 5.9 MB                                  |

#### Comparing different tools and methods

- `nexe` seems to be the most flexible and can result in the smallest binaries
- Deno also appears to [work with `strip`](https://github.com/denoland/deno/issues/9198#issuecomment-764007074) [and `upx`](https://github.com/denoland/deno/issues/986#issuecomment-742041812)
- `pkg` [does not work with `upx`](https://github.com/vercel/pkg/issues/50) and `strip` seems to have no effect

  - But it has more versions of Node precompiled (meaning you probably won't need to compile it yourself) and cross-compiles by default out-of-the-box, e.g.

    ```
    $ npx pkg app.js
    $ ls -1
    app.js
    app-linux
    app-macos
    app-win.exe
    ```

| Method                                                                   | Runtime version | Linux binary size | Time to execute hello world |
| ------------------------------------------------------------------------ | --------------- | ----------------- | --------------------------- |
| `npx pkg .`                                                              | Node 14.18.2    | 37 MB             | 0m0.042s                    |
| `npx pkg --compress GZip .`¹                                             | Node 14.18.2    | 37 MB             | 0m0.042s                    |
| `npx nexe app.js --build`                                                | Node 14.18.2    | 75 MB             | 0m0.054s                    |
| `npx nexe app.js --build` (with `strip` and `upx`)                       | Node 14.18.2    | 23 MB             | 0m0.250s                    |
| `npx nexe app.js --build` (with `small-icu`, `strip`, and `upx`)         | Node 14.18.2    | 14 MB             | 0m0.183s                    |
| `npx nexe app.js --build` (with `--without-intl`, `strip`, and `upx`)    | Node 14.18.2    | 11 MB             | 0m0.154s                    |
| `npx nexe app.js --build` (with `--without-intl`, `strip`, `upx --lzma`) | Node 14.18.2    | 8.6 MB            | 0m0.568s                    |
| `deno compile app.js`²                                                   | Deno 1.19.3     | 84 MB             | 0m0.026s                    |

Notes:

1. `pkg --compress` only compresses the JavaScript source, so it has little impact on our hello world test code
1. Deno used to have a `compile --lite` option, but unfortunately it was removed: [https://github.com/denoland/deno/issues/10507](https://github.com/denoland/deno/issues/10507)

## Other options

#### Bundled JS instead of self-contained executable

For large applications, adding 10+ MB to the binary size in order to bundle Node.js won't make much of a difference. If you want something smaller and don't mind requiring users to have Node.js installed in order to run your application, you can use a JS bundler to bundle the application with its dependencies into a single JS file, then add a shebang at the top, e.g.:

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
