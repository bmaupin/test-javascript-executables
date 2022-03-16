FROM node:16

RUN apt update && \
    apt -y install upx-ucl && \
    npm install -g nexe && \
    # Create a dummy hello world file; nexe doesn't seem to be able build Node.js without a JS input file
    echo "console.log('Hello world!');" > hello.js && \
    # - Python 3 is required for Node 16+ (https://nodejs.org/en/blog/release/v16.0.0/#toolchain-and-compiler-upgrades)
    # - Remove `--without-intl` or replace with `--with-intl=small-icu` depending on the Intl support you need
    #   (https://github.com/nodejs/node/blob/master/BUILDING.md#building-without-intl-support)
    # - You can also specify an exact version of Node:
    #   nexe hello.js --target linux-x64-14.19.0 ...
    nexe hello.js --build --configure=--without-intl --make=-j4 --python=$(which python3) --verbose && \
    # Remove this if you use any native Node.js modules
    strip ~/.nexe/*/out/Release/node && \
    upx ~/.nexe/*/out/Release/node
