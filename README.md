# Taipei Metro in Git

It's just a random idea and it looks like it has been previously published by [gugod](https://gugod.org/2009/12/git-graphing/), [othree](https://blog.othree.net/log/2016/09/17/git-mrt/) before.

This version took ideas from both versions and is fully automated. Each station is a commit with a tag associated for name lookup. Each line (segment) has its own branch for lookup.

To make it compatible with more git/visualization tools, the master branch is a multi-way merge with all branches and a special code/document commit.

The techniques used in the script is somewhat useful if you're looking to create a monorepo. :p

See the graph with [Github](https://github.com/itszero/Taipei-Metro-In-Git/network) or [Sublime Merge](https://mobile.twitter.com/itszero/status/1260849067917144064).

# Update Data

This code reads from the metro route info from Taiwan's PTX transport open data platform. You can fetch a copy of data by going to the [PTX OpenAPI platform](https://ptx.transportdata.tw/MOTC?t=Rail&v=2#!/Metro/MetroApi_StationOfRoute).

Run the API (`/v2/Rail/Metro/StationOfRoute/TRTC`), grab the curl command and save the output to `data.json`.


# Run

Make sure you have `ruby`, `rsync` and `git` installed and run `ruby main.rb`

# Updates

2020/10/4: Updated data for Y line (環狀線, Circular Line)

# License

Copyright 2020 Zero Cho

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
