Various methods for packaging Node.js apps into self-contained executables

## General steps

Here are the high-level steps that will need to be done:

1. Choose a tool to use to create the exectuable (see below)
1. Apply conversions to the code as needed

   - If you're using Bun or Deno, you may be able to skip this step
   - Otherwise, a bundler such as [`esbuild`](https://esbuild.github.io/) can probably do everything for you in one step; here are some possible conversions you may need:
     - Convert from newer JavaScript to support an older version of Node (e.g. if you want a smaller binary)
     - Convert from TypeScript to JavaScript
     - Convert from ESM to CommonJS (some tools like `pkg` don't support ESM)
     - Bundle dependencies
     - Other transformations (minify, uglify, etc)

1. Package your code into an executable

   - This is where you package your source code into a self-contained executable. How this is done will depend on the tool used.

1. (Optional) Reduce the size of the executable
   - Tools such as `strip` and `upx` can reduce the size of the executable after it's built, but they don't work in all cases. See below for more information.
   - Instead of modifying the executable, a simpler option may be to compress it for distribution; 7zip is a common tool with cross-platform support and a great compression ratio.

## Choosing the right tool to use

There are many tools that can package Node.js apps into executables. Which one to choose depends on your needs.

### Official solutions

If your priority is an officially supported solution, many of the JavaScript runtimes now have support for creating executables.

#### Node

Starting with Node 19, support for packaging Node apps into executables has been integrated into Node: [Single executable applications](https://nodejs.org/api/single-executable-applications.html)

- Pros
  - Official support
- Cons
  - No official TypeScript support, but this can easily be handled by a bundler
  - No ESM support? But this can easily be handled by a bundler
  - No cross-compilation
  - Seems to require a lot of manual steps

#### Bun

Bun supports executables out of the box: [Single-file executable](https://bun.sh/docs/bundler/executables)

- Pros
  - Great solution if you're already using Bun
  - Supports TypeScript out of the box
- Cons
  - Bun doesn't fully support all Node.js APIs

#### Deno

Deno also supports standalone executables out of the box via [`deno compile`](https://docs.deno.com/runtime/manual/tools/compiler)

- Pros
  - Great solution if you're already using Deno
  - Seems to support `strip` and `upx` for smaller binaries
  - Supports TypeScript out of the box
- Cons
  - Deno doesn't fully support all Node.js APIs

### Ease of use

#### pkg

[`pkg`](https://github.com/vercel/pkg) is a tool from Vercel that works well out of the box.

- Pros
  - Easy to use
  - Supports cross-compilation out of the box (Linux, Mac, Windows)
  - Has many versions of Node precompiled, so no need to compile them
- Cons
  - `pkg` has been retired in favour of the official Node solution. It still works well but won't receive any more updates
  - Not compatible with `strip` or `upx` so not able to produce the smallest binaries
  - [Doesn't support ESM](https://github.com/vercel/pkg/issues/1291), but this is fairly easily worked around with a bundler (which you'll probably want to use anyway to bundle dependencies)
  - No official TypeScript support, but this can easily be handled by a bundler

#### js2bin

[`js2bin`](https://github.com/criblio/js2bin) looks promising although I haven't tested it myself

- Pros
  - Cross-compilation support
  - Seems very easy to use
- Cons
  - Only has a small number of binaries pre-compiled
  - No official TypeScript support, but this can easily be handled by a bundler

### Smallest binary

#### nexe

[`nexe`](https://github.com/nexe/nexe) seems to be the most flexible and can result in the smallest binaries

- Pros
  - Supports `strip` and `upx` to create the smallest possible binary
  - Now supports cross-compilation (see the nexe documentation)
- Cons
  - Fewer pre-compiled versions of Node.js compared to `pkg`
  - No official TypeScript support, but this can easily be handled by a bundler

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

## Quick start for building the smallest binary

#### Run `nexe` locally

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

## Detailed test results

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
