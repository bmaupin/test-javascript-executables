Testing various methods for packaging node apps as native binaries:

| Method                                                              | Node version | Linux binary size | Time to execute |
| ------------------------------------------------------------------- | ------------ | ----------------- | --------------- |
| `npx pkg .`                                                         | 14           | 37 MB             | 0m0.042s        |
| `npx pkg --compress GZip .`                                         | 14           | 37 MB             | 0m0.042s        |
| `npx nexe app.js --build`¹                                          | 14           | 75 MB             | 0m0.054s        |
| `npx nexe app.js --build` (using `strip` and `upx` as below)        | 14           | 23 MB             | 0m0.250s        |
| 👉 `npx nexe app.js --build` (with `small-icu`, `strip`, and `upx`) | 14           | 14 MB             | 0m0.183s        |
| `deno compile app.js`²                                              | N/A          | 84 MB             | 0m0.026s        |

Notes:

1. `nexe` additionally took 30+ minutes for the first build because it had to compile Node.js
1. Using Deno 1.19.3; Deno used to have a `compile --lite` option, but unfortunately it was removed: [https://github.com/denoland/deno/issues/10507](https://github.com/denoland/deno/issues/10507)

#### Strip debugging symbols

Debugging symbols could be stripped from the Node/Deno binaries in the case where native modules aren't needed

- This helps `nexe` (see below) and Deno (see [here](https://github.com/denoland/deno/issues/9198#issuecomment-764007074)) somewhat, but doesn't seem to have any affect with `pkg`

#### `upx`

[`upx`](https://upx.github.io/) can be used to reduce the size of binaries at a small (~1 second) startup cost

- `nexe` works with `upx`; see below
- `pkg` does not work with `upx` ([https://github.com/vercel/pkg/issues/50](https://github.com/vercel/pkg/issues/50))

#### Node builds with smaller/no ICU support

[https://github.com/nodejs/node/blob/master/BUILDING.md#intl-ecma-402-support](https://github.com/nodejs/node/blob/master/BUILDING.md#intl-ecma-402-support)

Size comparisons for Node binary (using Node v14.18.2):

- Default build: 75 MB
- With small ICU (`--with-intl=small-icu`): 51 MB
- Without Intl support (`--without-intl`): TODO

#### Bundled JS instead of native binary

For large applications, a 20+ MB binary won't make much of a difference. Where size is an issue, we could just use a JS bundler to bundle/minimize the code into a single JS file, then add a shebang to the top, and require Node; see [app](app) as an example of doing this; it can be run as a normal shell executable:

```
$ ./app
Hello world
```

#### Getting the smallest binary size possible with `nexe`

1. Make sure `python` links to Python 3 (this is required to use a smaller ICU when compiling Node)

   ```
   sudo apt install python-is-python3
   ```

1. Run `npx nexe app.js --build --configure='--with-intl=small-icu' --verbose` to build Node with small ICU

   - Replace `--with-intl=small-icu` with `--without-intl` for an even smaller Node binary

     > The Intl object will not be available, nor some other APIs such as String.normalize.

     ([https://github.com/nodejs/node/blob/master/BUILDING.md#building-without-intl-support](https://github.com/nodejs/node/blob/master/BUILDING.md#building-without-intl-support))

1. Go to the Nexe node binary directory

   ```
   cd ~/.nexe/14.18.2/out/Release
   ```

1. Make a copy of the Node binary

   ```
   cp node node.bak
   ```

1. Strip debugging symbols

   ⚠ Only do this if you're not using any native modules, as the debugging symobols are required for native modules

   ```
   strip node
   ```

1. Run [`upx`](https://upx.github.io/) on the node binary

   ```
   upx node
   ```

After that, using `npx nexe --build` should use the stripped/compressed Node binary
