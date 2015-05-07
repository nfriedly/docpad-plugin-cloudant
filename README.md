[MongoDB](https://www.mongodb.org/) Importer Plugin for [DocPad](http://docpad.org)

<!-- BADGES/ -->

[![Build Status](//travis-ci.org/nfriedly/docpad-plugin-mongodb.svg?branch=master)](https://travis-ci.org/nfriedly/docpad-plugin-mongodb)
[![NPM version](//badge.fury.io/js/docpad-plugin-mongodb.png)](https://npmjs.org/package/docpad-plugin-mongodb "View this project on NPM")
[![Dependency Status](//david-dm.org/nfriedly/docpad-plugin-mongodb.png?theme=shields.io)](https://david-dm.org/nfriedly/docpad-plugin-mongodb)
[![Development Dependency Status](//david-dm.org/nfriedly/docpad-plugin-mongodb/dev-status.png?theme=shields.io)](https://david-dm.org/nfriedly/docpad-plugin-mongodb#info=devDependencies)
[![Gittip donate button](//img.shields.io/gittip/nfriedly.png)](https://www.gittip.com/nfriedly/ "Donate weekly to this project using Gittip")

<!-- /BADGES -->

Import MongoDB collections into DocPad collections.

Inspired by https://github.com/simonh1000/docpad-plugin-mongo and based on https://github.com/docpad/docpad-plugin-tumblr/

## Install

```
docpad install mongodb
```


## Configuration

### Simple example

Add the following to your [docpad configuration file](http://docpad.org/docs/config):

``` coffee
plugins:
  mongodb:
    collections: [
      connectionString: "mongodb://localhost/blog" # format is "mongodb://username:password@hostname:port/dbname?options"
      collectionName: "posts"
      relativeDirPath: "blog"
      extension: ".html"
      sort: date: 1 # newest first
      meta:
        layout: "blogpost"
    ]
```

### Fancy example

``` coffee
plugins:
  mongodb:
    collectionDefaults:
      connectionString: "mongodb://localhost/blog" # format is "mongodb://username:password@hostname:port/dbname?options"

    collections: [
      {
        # connectionString is imported from the defaults
        collectionName: "posts"
        relativeDirPath: "blog"
        extension: '.html.eco'
        sort: date: 1 # newest first
        injectDocumentHelper: (document) ->
          document.setMeta(
            layout: 'default'
            tags: (document.get('tags') or []).concat(['post'])
            data: """
              <%- @partial('post/'+@document.tumblr.type, @extend({}, @document, @document.tumblr)) %>
              """
          )
      },

      {
        collectionName: "comments"
        extension: '.html.markup'
        sort: date: -1 #oldest first
        query: {isSpam: false}
        meta:
          write: false
      },

      {
        connectionString: "mongodb://localhost/stats"
        collectionName: "stats"
        docpadCollectionName: "websiteStats"
        extension: ".json"
      }
    ]
```

### Config details:

Each configuration object in `collections` inherits default values from `collectionDefaults` and then from the built-in defaults:

```coffee
    connectionString: process.env.MONGOLAB_URI || process.env.MONGOHQ_URL || "mongodb://localhost/localdev"
    relativeDirPath: null # defaults to collectionName
    extension: ".json"
    injectDocumentHelper: null # function to format documents
    collectionName: "mongodb" # name of the collection in mongodb
    docpadCollectionName: null # defaults to collectionName
    sort: null # http://documentcloud.github.io/backbone/#Collection-comparator
    meta: {} # automatically added to each document
    query: {} # optional MongoDB query to select a sub-set of the documents in the collection
```

The default directory for where the imported documents will go inside is the collectionName.
You can override this using the `relativeDirPath` plugin config option.

The default content for the imported documents is JSON data. You can can customise this with the `injectDocumentHelper`
plugin configuration option which is a function that takes in a single [Document Model](https://github.com/bevry/docpad/blob/master/src/lib/models/document.coffee).

If you would like to render a template, add a layout, and change the extension, you can do it via the `meta` configuration
option or you can get fancy and do this with (for example) the
[eco](https://github.com/docpad/docpad-plugin-eco) and [partials](https://github.com/docpad/docpad-plugin-partials)
plugins and following collection configuration:

``` coffee
extension: '.html.eco'
injectDocumentHelper: (document) ->
  document.setMeta(
    layout: 'default'
    tags: (document.get('tags') or []).concat(['post'])
    data: """
			<%- @partial('post/'+@document.tumblr.type, @extend({}, @document, @document.tumblr)) %>
			"""
  )
```

The `sort` field is [passed as the comparator to Query Engine](https://learn.bevry.me/queryengine/guide#querying) which tries it as a
[MongoDB-style sort](http://docs.mongodb.org/manual/reference/method/cursor.sort/) first and then a
[Backbone.js comparator](http://documentcloud.github.io/backbone/#Collection-comparator) second.

The `query` is a standard [MongoDB query](http://docs.mongodb.org/manual/tutorial/query-documents/) and can be used to filter the documents before importing them into your DocPad database.

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


