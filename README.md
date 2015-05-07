[Cloudant](https://cloudant.com/) Importer Plugin for [DocPad](http://docpad.org)

<!-- BADGES/ -->

[![Build Status](//travis-ci.org/nfriedly/docpad-plugin-cloudant.svg?branch=master)](https://travis-ci.org/nfriedly/docpad-plugin-cloudant)
[![NPM version](//badge.fury.io/js/docpad-plugin-cloudant.png)](https://npmjs.org/package/docpad-plugin-cloudant "View this project on NPM")
[![Dependency Status](//david-dm.org/nfriedly/docpad-plugin-cloudant.png?theme=shields.io)](https://david-dm.org/nfriedly/docpad-plugin-cloudant)
[![Development Dependency Status](//david-dm.org/nfriedly/docpad-plugin-cloudant/dev-status.png?theme=shields.io)](https://david-dm.org/nfriedly/docpad-plugin-cloudant#info=devDependencies)
[![Gittip donate button](//img.shields.io/gittip/nfriedly.png)](https://www.gittip.com/nfriedly/ "Donate weekly to this project using Gittip")

<!-- /BADGES -->

Import Cloudant collections into DocPad collections.

(Cloudant is a hosted [CouchDB](https://couchdb.apache.org/)-compatible database from IBM with a fairly generous free tier.)

Based on https://github.com/nfriedly/docpad-plugin-mongodb

## Install

```
docpad install cloudant
```


## Configuration

Add the following to your [docpad configuration file](http://docpad.org/docs/config):

``` coffee
plugins:
  cloudant:
    collections: [
      cloudantConfig: {account: "foo", password: "bar"} // passed directly to the [node.js client](https://github.com/cloudant/nodejs-cloudant), so a `url` is also accepted
      dbName: "posts"
      collectionName: "blog_posts" # defaults to dbName
      relativeDirPath: "blog" # defaults to dbName
      extension: ".html" # defaults to .json
      meta:
        layout: "blogpost"
    ]
```

### Creating a File Listing

As imported documents are just like normal documents, you can also list them just as you would other documents. Here is an example of a `index.html.eco` file that would output the titles and links to all the blog posts from the simple example above:

``` erb
<h2>Blog:</h2>
<ul><% for post in @getCollection('posts').toJSON(): %>
	<li>
		<a href="<%= post.url %>"><%= post.title %></a>
	</li>
<% end %></ul>
```

## MIT License

Copyright (c) 20154 Nathan Friedly  - http://nfriedly.com/

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

