FROM node:16

RUN apt -y install upx-ucl && \
    npm install -g nexe && \
    # Create a dummy hello world file
    echo "console.log('Hello world!');" > hello.js && \
    # Python 3 is required for Node 16+ (https://nodejs.org/en/blog/release/v16.0.0/#toolchain-and-compiler-upgrades)
    # nexe hello.js --target linux-x64-8.17.0 --build --configure='--without-intl' --make=-j5 --python=$(which python3) --verbose
    # Remove `--without-intl` or replace with `--with-intl=small-icu` depending on the Intl support you need
    # (https://github.com/nodejs/node/blob/master/BUILDING.md#building-without-intl-support)
    nexe hello.js --build --configure='--without-intl' --make=-j5 --python=$(which python3) --verbose && \
    # Remove this if you use any native Node.js modules
    strip ~/.nexe/16.14.0/out/Release/node && \
    upx ~/.nexe/16.14.0/out/Release/node
