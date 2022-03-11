Testing various methods for packaging node apps as native binaries:

| Method                                                        | Node version | Linux binary size | Time to execute |
| ------------------------------------------------------------- | ------------ | ----------------- | --------------- |
| `npx pkg .`                                                   | 14           | 37M               | 0m0.042s        |
| `npx pkg --compress GZip .`                                   | 14           | 37M               | 0m0.042s        |
| `npx nexe app.js --build`¹                                    | 14           | ⚠ 75M !!          | 0m0.054s        |
| `npx nexe app.js --build`² (using `strip` and `upx` as below) | 14           | 23M               | 0m0.250s        |
| `deno compile app.js`³                                        | N/A          | ⚠ 84M !!          | 0m0.026s        |

Notes:

1. `nexe` additionally took 30+ minutes for the first build because it had to compile Node.js
1. Using Deno 1.19.3; Deno used to have a `compile --lite` option, but unfortunately it was removed: [https://github.com/denoland/deno/issues/10507](https://github.com/denoland/deno/issues/10507)

This is probably best for large applications/binaries. For smaller applications, we should probably use a JS bundler to bundle/minimize the code into a single JS file, then add a shebang to the top, and require Node; see [app](app) as an example of doing this; it can be run as a normal shell executable:

```
$ ./app
Hello world
```

#### Alternatives

- Debugging symbols could be stripped from the Node/Deno binaries in the case where native modules aren't needed, e.g. [https://github.com/denoland/deno/issues/9198#issuecomment-764007074](https://github.com/denoland/deno/issues/9198#issuecomment-764007074)
- [`upx`](https://upx.github.io/) can be used to reduce the size of binaries at a small (~1 second) startup cost
  - Apparently `nexe` works with `upx` ([https://github.com/nexe/nexe/issues/366#issuecomment-333534629](https://github.com/nexe/nexe/issues/366#issuecomment-333534629))
  - `pkg` does not work with `upx` ([https://github.com/vercel/pkg/issues/50](https://github.com/vercel/pkg/issues/50))

#### Using `strip` and `upx` with `nexe`

1. Run `npx nexe --build` to build Node
1. `cd ~/.nexe/14.18.2/out/Release`
1. `strip node`
1. `upx node`

After that, using `npx nexe --build` should use the stripped/compressed Node binary
