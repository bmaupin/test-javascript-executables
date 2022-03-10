Testing various methods for packaging node apps as native binaries:

| Method                      | Node version | Linux binary size | Time to execute |
| --------------------------- | ------------ | ----------------- | --------------- |
| `npx pkg .`                 | 14           | 37M               | 0m0.042s        |
| `npx pkg --compress GZip .` | 14           | 37M               | 0m0.042s        |
| `npx nexe app.js --build`¹  | 14           | ⚠ 75M !!          | 0m0.054s        |

Note 1: `nexe` additionally took ~30 minutes for the first build because it had to compile Node.js, so it seems like a poor choice overall.

This is probably best for large applications/binaries. For smaller applications, we should probably use a JS builder to bundle/minimize the code into a single JS file, then add a shebang to the top, and require Node; see [app](app) as an example of doing this; it can be run as a normal shell executable:

```
$ ./app
Hello world
```
